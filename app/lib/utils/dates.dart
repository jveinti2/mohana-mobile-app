import 'package:intl/intl.dart';

/// Fecha de publicación en la forma en que la diría alguien: lo de esta semana
/// en días, lo demás con su fecha.
///
/// El feed ordena por fecha pero hasta ahora no la mostraba, así que una
/// noticia de hace ocho meses y la de ayer se leían igual.
///
/// [now] existe para poder fijar el presente en los tests.
String fechaRelativa(DateTime date, {DateTime? now}) {
  final ahora = now ?? DateTime.now();
  // Se compara por día natural, no por horas: algo publicado anoche es "ayer"
  // aunque no hayan pasado 24 horas.
  final dias = DateTime(ahora.year, ahora.month, ahora.day)
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;

  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  if (dias < 7) return 'hace $dias días';
  if (date.year == ahora.year) return DateFormat('d MMM', 'es').format(date);
  return DateFormat('d MMM y', 'es').format(date);
}
