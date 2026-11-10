import 'package:flutter/foundation.dart';

import '../config/hygraph_config.dart';
import 'hygraph_service.dart';

/// Una franja de la parrilla: un programa a una hora, unos días.
class ScheduleSlot {
  final String title;

  /// Días en los que va, como números de [DateTime.monday]..[DateTime.sunday].
  final Set<int> weekdays;

  /// Minutos desde medianoche, en hora de la emisora.
  final int startMinute;
  final int endMinute;

  const ScheduleSlot({
    required this.title,
    required this.weekdays,
    required this.startMinute,
    required this.endMinute,
  });

  bool coversMinute(int weekday, int minute) =>
      weekdays.contains(weekday) && minute >= startMinute && minute < endMinute;

  /// "7:00 – 8:00 a. m."
  String get label => '${_hhmm(startMinute)} – ${_hhmm(endMinute)}';

  static String _hhmm(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    final sufijo = h < 12 ? 'a. m.' : 'p. m.';
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return m == 0
        ? '$h12:00 $sufijo'
        : '$h12:${m.toString().padLeft(2, '0')} $sufijo';
  }
}

/// Parrilla de la emisora.
///
/// Responde qué programa está al aire, que es lo que el directo no sabía
/// decir: el stream no trae metadatos, así que sin parrilla [RadioScreen] solo
/// puede enseñar la marca.
///
/// La fuente es el modelo `Franja` de Hygraph. Cada entrada es un programa con
/// sus días y sus horas, elegidos en el panel — antes esto era un archivo de
/// texto en Drive que había que escribir con una sintaxis exacta y que fallaba
/// en silencio ante un `7:00` en vez de `07:00`. Ahora el panel no deja
/// guardarlo mal.
///
/// Las horas se interpretan **en hora de Colombia**, no en la del teléfono:
/// quien escuche desde España tiene que ver el programa que suena de verdad.
///
/// Mientras no haya franjas, [current] devuelve null y la app enseña la
/// identidad de la emisora, exactamente como antes.
class ScheduleService {
  ScheduleService._();

  /// Colombia no cambia de hora, así que basta un desfase fijo respecto a UTC.
  static const _stationOffset = Duration(hours: -5);

  /// La parrilla cambia como mucho por temporadas; media jornada de caché
  /// sobra y evita una petición en cada arranque.
  static const _ttl = Duration(hours: 12);

  static const _query = r'''
query Parrilla {
  franjas(first: 200) {
    programa
    dias
    horaInicio
    horaFin
  }
}
''';

  static List<ScheduleSlot> _slots = const [];
  static DateTime? _loadedAt;

  static bool get isEmpty => _slots.isEmpty;

  /// Franjas cargadas. El `setter` existe solo para las pruebas: en la app la
  /// parrilla entra por [load].
  static List<ScheduleSlot> get slots => _slots;

  @visibleForTesting
  static set slots(List<ScheduleSlot> value) => _slots = value;

  /// Descarga la parrilla si hace falta. Nunca lanza: sin parrilla la app
  /// funciona igual.
  static Future<void> load({bool forceRefresh = false}) async {
    if (!HygraphConfig.isConfigured) return;

    final at = _loadedAt;
    if (!forceRefresh &&
        at != null &&
        DateTime.now().difference(at) < _ttl &&
        _slots.isNotEmpty) {
      return;
    }

    try {
      final data = await HygraphService.query(_query);
      final slots = parse(data['franjas']);
      if (slots.isEmpty) return;
      _slots = slots;
      _loadedAt = DateTime.now();
    } catch (e) {
      debugPrint('Parrilla: no disponible: $e');
    }
  }

  /// Programa al aire ahora mismo, o null si no hay parrilla o si a esta hora
  /// no hay nada programado (música, repeticiones).
  static ScheduleSlot? current({DateTime? now}) {
    if (_slots.isEmpty) return null;
    final t = _stationTime(now);
    final minute = t.hour * 60 + t.minute;
    for (final slot in _slots) {
      if (slot.coversMinute(t.weekday, minute)) return slot;
    }
    return null;
  }

  /// Siguiente franja del día, para el "a continuación".
  static ScheduleSlot? next({DateTime? now}) {
    if (_slots.isEmpty) return null;
    final t = _stationTime(now);
    final minute = t.hour * 60 + t.minute;

    ScheduleSlot? best;
    for (final slot in _slots) {
      if (!slot.weekdays.contains(t.weekday)) continue;
      if (slot.startMinute <= minute) continue;
      if (best == null || slot.startMinute < best.startMinute) best = slot;
    }
    return best;
  }

  /// Hora de la emisora, independiente de la zona del teléfono.
  static DateTime _stationTime(DateTime? now) =>
      (now ?? DateTime.now()).toUtc().add(_stationOffset);

  // ─── Mapeo ─────────────────────────────────────────────────────

  /// Convierte las franjas que devuelve Hygraph en [ScheduleSlot]. Público
  /// para poder probarlo sin salir a la red.
  static List<ScheduleSlot> parse(Object? franjas) {
    final slots = <ScheduleSlot>[];

    for (final json in (franjas as List?) ?? const []) {
      if (json is! Map) continue;

      final programa = (json['programa'] as String?)?.trim();
      if (programa == null || programa.isEmpty) continue;

      // `dias` no se pudo marcar como obligatorio en Hygraph (no admite
      // listas requeridas), así que una franja sin días es posible: se ignora
      // en vez de sonar todos los días.
      final weekdays = <int>{};
      for (final dia in (json['dias'] as List?) ?? const []) {
        final n = _dias[dia.toString().toLowerCase()];
        if (n != null) weekdays.add(n);
      }
      if (weekdays.isEmpty) continue;

      final start = _minutos(json['horaInicio'] as String?);
      var end = _minutos(json['horaFin'] as String?);
      if (start == null || end == null) continue;
      // Una franja que termina a medianoche se escribe 00:00; se estira hasta
      // el final del día en vez de quedar vacía.
      if (end <= start) end = 24 * 60;

      slots.add(
        ScheduleSlot(
          title: programa,
          weekdays: weekdays,
          startMinute: start,
          endMinute: end,
        ),
      );
    }

    return slots;
  }

  /// "07:30" → 450. El panel valida el formato, pero un dato viejo o editado
  /// por la API podría no cumplirlo.
  static int? _minutos(String? hhmm) {
    if (hhmm == null) return null;
    final partes = hhmm.trim().split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Identificadores de la enumeración `Dia` de Hygraph. Se aceptan también
  /// con tilde por si alguien reescribe la enumeración en el panel.
  static const _dias = <String, int>{
    'lunes': DateTime.monday,
    'martes': DateTime.tuesday,
    'miercoles': DateTime.wednesday,
    'miércoles': DateTime.wednesday,
    'jueves': DateTime.thursday,
    'viernes': DateTime.friday,
    'sabado': DateTime.saturday,
    'sábado': DateTime.saturday,
    'domingo': DateTime.sunday,
  };
}
