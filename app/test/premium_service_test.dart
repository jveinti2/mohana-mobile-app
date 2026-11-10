import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/services/hygraph_service.dart';
import 'package:mohana/services/premium_service.dart';

/// Lo que se prueba aquí es el mapeo y la regla de dónde sale la dirección del
/// audio, que es el eje de todo el diseño de la sección exclusiva: es lo que
/// permitirá mover los archivos a otro almacenamiento sin tocar la app, y lo
/// que salva una ficha cuyo archivo se quedó en borrador en el panel.
void main() {
  Map<String, dynamic> ficha({
    String? id = 'ck1',
    String? titulo = 'Taller de memoria',
    String? descripcion = 'Grabado en el patio de la OFP.',
    String? fecha = '2026-03-14',
    String? duracion = '48 min',
    String? audioUrl,
    String? audioAsset = 'https://media.hygraph.com/audio.mp3',
    String? portada = 'https://media.hygraph.com/portada.jpg',
  }) => {
    'id': id,
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha': fecha,
    'duracion': duracion,
    'audioUrl': audioUrl,
    'audio': audioAsset == null ? null : {'url': audioAsset},
    'portada': portada == null ? null : {'url': portada},
  };

  group('parseo del contenido exclusivo', () {
    test('mapea título, descripción, duración, fecha y portada', () {
      final items = PremiumService.parse([ficha()]);

      expect(items, hasLength(1));
      final item = items.single;
      expect(item.id, 'ck1');
      expect(item.title, 'Taller de memoria');
      expect(item.description, 'Grabado en el patio de la OFP.');
      expect(item.duration, '48 min');
      expect(item.publishedAt, DateTime(2026, 3, 14));
      expect(item.imageUrl, 'https://media.hygraph.com/portada.jpg');
      expect(item.playable, isTrue);
    });

    test('usa el archivo subido cuando no hay URL escrita a mano', () {
      final items = PremiumService.parse([ficha(audioUrl: null)]);

      expect(items.single.audioUrl, 'https://media.hygraph.com/audio.mp3');
    });

    test('la URL escrita a mano gana sobre el archivo subido', () {
      // Es la válvula de escape: el día que los audios se muevan fuera de
      // Hygraph basta con pegar la dirección en el panel.
      final items = PremiumService.parse([
        ficha(audioUrl: 'https://otro-almacen.example/taller.mp3'),
      ]);

      expect(items.single.audioUrl, 'https://otro-almacen.example/taller.mp3');
    });

    test('una URL escrita en blanco no tapa al archivo subido', () {
      final items = PremiumService.parse([ficha(audioUrl: '   ')]);

      expect(items.single.audioUrl, 'https://media.hygraph.com/audio.mp3');
    });

    test('sin audio por ningún lado la ficha queda no reproducible', () {
      // El caso real: en Hygraph el archivo es una entrada aparte y publicar
      // la ficha no lo publica. La fila se pinta igual para que se vea que
      // falta algo, en vez de desaparecer sin explicación.
      final items = PremiumService.parse([
        ficha(audioUrl: null, audioAsset: null),
      ]);

      expect(items, hasLength(1));
      expect(items.single.playable, isFalse);
      expect(items.single.audioUrl, isEmpty);
    });

    test('sin portada queda vacía, para que la pinte MohanaCover', () {
      final items = PremiumService.parse([ficha(portada: null)]);

      expect(items.single.imageUrl, isEmpty);
    });

    test('tolera campos ausentes o nulos sin lanzar', () {
      final items = PremiumService.parse([
        {'id': 'ck2'},
        ficha(titulo: null, descripcion: null, duracion: null, fecha: null),
      ]);

      expect(items, hasLength(2));
      expect(items.first.title, 'Sin título');
      expect(items.first.description, isEmpty);
      expect(items.first.duration, isNull);
      expect(items.first.publishedAt, isNull);
      expect(items.last.title, 'Sin título');
    });

    test('descarta una ficha sin id y lo que no sea un mapa', () {
      final items = PremiumService.parse([
        ficha(id: null),
        'basura',
        42,
        ficha(id: 'ck3'),
      ]);

      expect(items.map((e) => e.id), ['ck3']);
    });

    test('una fecha ilegible no tumba la ficha', () {
      final items = PremiumService.parse([ficha(fecha: 'el martes')]);

      expect(items.single.publishedAt, isNull);
    });

    test('sin lista devuelve vacío', () {
      expect(PremiumService.parse(null), isEmpty);
      expect(PremiumService.parse(<Object?>[]), isEmpty);
      expect(PremiumService.parse({'no': 'una lista'}), isEmpty);
    });

    test('asEpisode lleva a la capa de audio lo que esta lee', () {
      // AudioService solo mira audioUrl, title e imageUrl de la cola.
      final episodio = PremiumService.parse([ficha()]).single.asEpisode;

      expect(episodio.audioUrl, 'https://media.hygraph.com/audio.mp3');
      expect(episodio.title, 'Taller de memoria');
      expect(episodio.imageUrl, 'https://media.hygraph.com/portada.jpg');
    });
  });

  group('distinguir un modelo que falta de una avería', () {
    test('un campo desconocido se reconoce como fallo de esquema', () {
      // Es lo que responde Hygraph mientras el modelo no exista en el panel:
      // la sección tira de los audios de muestra en vez de pintar un error
      // que nadie puede arreglar desde el teléfono.
      const e = HygraphException(
        'El CMS respondió 400',
        detail:
            'Cannot query field "contenidosPremium" on type "Query". '
            'Did you mean "podcastsDestacados"?',
      );

      expect(e.schemaError, isTrue);
    });

    test('un corte de red no se confunde con un modelo que falta', () {
      const e = HygraphException(
        'No se pudo conectar con el CMS',
        detail: 'SocketException: Failed host lookup',
      );

      expect(e.schemaError, isFalse);
    });
  });
}
