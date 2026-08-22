/// Ejecuta [task] sobre [items] con como mucho [limit] tareas simultáneas,
/// devolviendo los resultados en el orden de entrada.
///
/// Alternativa a `Future.wait` cuando la lista puede ser larga: lanzar 27
/// descargas a la vez en una red móvil es la receta del timeout, y hacerlas
/// una a una multiplica la espera.
Future<List<R>> pooled<T, R>(
  List<T> items,
  int limit,
  Future<R> Function(T item) task,
) async {
  if (items.isEmpty) return <R>[];

  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final i = next++;
      if (i >= items.length) return;
      results[i] = await task(items[i]);
    }
  }

  await Future.wait([
    for (var i = 0; i < limit && i < items.length; i++) worker(),
  ]);
  return results.cast<R>();
}
