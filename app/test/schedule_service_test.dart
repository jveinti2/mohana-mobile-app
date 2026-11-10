import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/services/schedule_service.dart';

/// La parrilla es lo que permite al directo decir qué suena. Antes venía de un
/// archivo de texto y lo frágil era el parseo; ahora la escribe el panel de
/// Hygraph con validación, así que lo que se prueba aquí es el mapeo de lo que
/// devuelve la API y que las horas se resuelvan en hora de Colombia, no en la
/// del teléfono.

/// Franja tal como llega de Hygraph.
Map<String, dynamic> franja(
  String programa,
  List<String> dias,
  String inicio,
  String fin,
) => {
  'programa': programa,
  'dias': dias,
  'horaInicio': inicio,
  'horaFin': fin,
};

const _semana = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes'];

final parrilla = <Map<String, dynamic>>[
  franja('Revista Informativa', _semana, '07:00', '08:00'),
  franja('Comuna Popular', _semana, '08:00', '09:00'),
  franja('Zona Púrpura', ['sabado'], '09:00', '11:00'),
  franja('La Hora del Cuento Radial', [
    'viernes',
    'sabado',
    'domingo',
  ], '22:00', '00:00'),
];

void main() {
  group('parse', () {
    test('mapea programa, días y horas', () {
      final slot = ScheduleService.parse(parrilla).first;
      expect(slot.title, 'Revista Informativa');
      expect(slot.weekdays, {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      });
      expect(slot.startMinute, 7 * 60);
      expect(slot.endMinute, 8 * 60);
    });

    test('terminar a las 00:00 estira la franja hasta el final del día', () {
      final slot = ScheduleService.parse(
        parrilla,
      ).firstWhere((s) => s.title == 'La Hora del Cuento Radial');
      expect(slot.endMinute, 24 * 60);
    });

    test('los días con tilde también valen', () {
      final slots = ScheduleService.parse([
        franja('Prueba', ['miércoles', 'sábado'], '10:00', '11:00'),
      ]);
      expect(slots.single.weekdays, {DateTime.wednesday, DateTime.saturday});
    });

    // Hygraph no permite marcar como obligatorio un campo de lista, así que
    // una franja sin días es algo que de verdad puede llegar.
    test('una franja sin días se descarta, no suena todos los días', () {
      expect(
        ScheduleService.parse([franja('Huérfana', [], '10:00', '11:00')]),
        isEmpty,
      );
    });

    test('se ignora lo que no se puede interpretar', () {
      expect(
        ScheduleService.parse([
          franja('Sin hora', ['lunes'], 'a las diez', '11:00'),
          franja('', ['lunes'], '10:00', '11:00'),
          {'programa': 'Incompleta'},
          'esto no es una franja',
        ]),
        isEmpty,
      );
    });

    test('sin franjas no se inventa nada', () {
      expect(ScheduleService.parse(null), isEmpty);
      expect(ScheduleService.parse(const []), isEmpty);
    });
  });

  group('qué suena', () {
    setUp(() => ScheduleService.slots = ScheduleService.parse(parrilla));
    tearDown(() => ScheduleService.slots = const []);

    // 2026-05-18 es lunes. Las horas se dan en UTC: Colombia va cinco por
    // detrás, así que 12:30 UTC son las 7:30 de la mañana allí.
    test('devuelve el programa de la franja, en hora de la emisora', () {
      final slot = ScheduleService.current(
        now: DateTime.utc(2026, 5, 18, 12, 30),
      );
      expect(slot?.title, 'Revista Informativa');
    });

    test('la zona del teléfono no cambia el resultado', () {
      // El mismo instante, expresado con el desfase de España (+02:00).
      final desdeEspana = DateTime.parse('2026-05-18T14:30:00+02:00');
      expect(
        ScheduleService.current(now: desdeEspana)?.title,
        'Revista Informativa',
      );
    });

    test('fuera de toda franja no hay programa', () {
      // Lunes a las 15:00 en Colombia: solo hay parrilla de mañana.
      expect(
        ScheduleService.current(now: DateTime.utc(2026, 5, 18, 20, 0)),
        isNull,
      );
    });

    test('una franja de otro día no cuenta', () {
      // Sábado 2026-05-23 a las 7:30: «Revista Informativa» es de lunes a
      // viernes, así que a esa hora el sábado no suena.
      expect(
        ScheduleService.current(now: DateTime.utc(2026, 5, 23, 12, 30)),
        isNull,
      );
    });

    test('el siguiente es el que empieza antes, no el primero de la lista', () {
      final slot = ScheduleService.next(now: DateTime.utc(2026, 5, 18, 12, 30));
      expect(slot?.title, 'Comuna Popular');
    });

    test('sin parrilla no se inventa nada', () {
      ScheduleService.slots = const [];
      expect(
        ScheduleService.current(now: DateTime.utc(2026, 5, 18, 12, 30)),
        isNull,
      );
      expect(
        ScheduleService.next(now: DateTime.utc(2026, 5, 18, 12, 30)),
        isNull,
      );
    });
  });
}
