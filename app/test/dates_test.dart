import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mohana/utils/dates.dart';

/// El feed ordena por fecha desde siempre, pero hasta ahora no la enseñaba: lo
/// de ayer y lo del año pasado se leían igual. Lo que se prueba aquí es que la
/// frontera entre "hace unos días" y una fecha con su día y su mes caiga donde
/// toca.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final ahora = DateTime(2026, 5, 20, 15, 0);

  test('lo de hoy es "hoy", aunque sea de esta mañana', () {
    expect(fechaRelativa(DateTime(2026, 5, 20, 7, 0), now: ahora), 'hoy');
  });

  test('lo de anoche es "ayer", no "hace 0 días"', () {
    // Menos de 24 horas, pero otro día natural.
    expect(fechaRelativa(DateTime(2026, 5, 19, 23, 30), now: ahora), 'ayer');
  });

  test('dentro de la semana se cuenta en días', () {
    expect(fechaRelativa(DateTime(2026, 5, 18), now: ahora), 'hace 2 días');
    expect(fechaRelativa(DateTime(2026, 5, 15), now: ahora), 'hace 5 días');
  });

  test('a partir de una semana se da la fecha', () {
    final texto = fechaRelativa(DateTime(2026, 5, 13), now: ahora);
    expect(texto, contains('13'));
    expect(texto, isNot(contains('hace')));
  });

  test('la fecha del año en curso no lleva año', () {
    expect(fechaRelativa(DateTime(2026, 1, 8), now: ahora), isNot(contains('2026')));
  });

  test('la de otro año sí lo lleva, para no confundir mayos', () {
    expect(fechaRelativa(DateTime(2025, 5, 20), now: ahora), contains('2025'));
  });

  test('una fecha por delante del reloj no dice disparates', () {
    expect(fechaRelativa(DateTime(2026, 5, 25), now: ahora), 'hoy');
  });
}
