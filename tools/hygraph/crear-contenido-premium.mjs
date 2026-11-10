#!/usr/bin/env node
// Crea el modelo `ContenidoPremium` en Hygraph y sus campos.
//
// Esto es una migración de esquema, no contenido: el endpoint que usa la app es
// de solo lectura y no puede crear modelos. Va por la API de gestión, que pide
// un token.
//
// Se guarda en el repo porque documenta la forma del CMS mejor que una captura
// del panel, y porque si algún día hay que recrear el proyecto (o montar un
// entorno de pruebas) esto lo deja igual en un comando.
//
// Uso:
//   export HYGRAPH_TOKEN='...'          # token con permisos de gestión
//   node tools/hygraph/crear-contenido-premium.mjs
//
// Es idempotente a medias: si el modelo ya existe, Hygraph rechaza la migración
// entera y no deja nada a medias. Para añadir un campo a un modelo que ya está,
// comenta las operaciones que ya se aplicaron.

import { Client, SimpleFieldType, RelationalFieldType } from '@hygraph/management-sdk';

const TOKEN = process.env.HYGRAPH_TOKEN;
// Ojo: NO es el endpoint que usa la app. Ese es el de la CDN de solo lectura
// (`us-west-2.cdn.hygraph.com/content/...`) y el SDK no puede derivar de él la
// dirección de gestión. Aquí va la API normal del proyecto, la que sale en
// Project settings -> API Access como "Content API".
const ENDPOINT =
  process.env.HYGRAPH_ENDPOINT ??
  'https://api-us-west-2.hygraph.com/v2/cmsxfdt9305as06w6zt9vjukk/master';

if (!TOKEN) {
  console.error('Falta HYGRAPH_TOKEN. Ver el comentario de cabecera.');
  process.exit(1);
}

const MODELO = 'ContenidoPremium';

const client = new Client({
  endpoint: ENDPOINT,
  authToken: TOKEN,
  // El de la region del proyecto, no el generico: `management.hygraph.com`
  // responde 401 "token verification failed" a este token. El `iss` del propio
  // token dice cual es (aqui, management-us-west-2).
  managementEndpoint:
    process.env.HYGRAPH_MANAGEMENT_ENDPOINT ??
    'https://management-us-west-2.hygraph.com/graphql',
  // Con marca de tiempo: Hygraph guarda el nombre de cada migración, también
  // de las que fallan, y rechaza repetirlo. Sin esto, un segundo intento tras
  // un error aborta antes de llegar al CMS.
  name: `contenido-premium-${Date.now()}`,
});

client.createModel({
  apiId: MODELO,
  // El plural se escribe a mano: Hygraph propondría "ContenidoPremiums" y la
  // app consulta exactamente `contenidosPremium`. Va en mayúscula inicial
  // porque la API de gestión lo exige así; el nombre de la consulta sale de
  // bajarle la primera letra, que es justo el que espera la app.
  apiIdPlural: 'ContenidosPremium',
  displayName: 'Contenido Premium',
  description:
    'Audios exclusivos de la emisora: lo que no se publica en iVoox. '
    + 'Se ve en la pestaña Exclusivo de la app.',
});

client.createSimpleField({
  modelApiId: MODELO,
  apiId: 'titulo',
  displayName: 'Título',
  type: SimpleFieldType.String,
  isRequired: true,
  // Es el campo por el que se reconoce la ficha en los listados del panel.
  isTitle: true,
});

client.createSimpleField({
  modelApiId: MODELO,
  apiId: 'descripcion',
  displayName: 'Descripción',
  type: SimpleFieldType.String,
  formRenderer: 'GCMS_MULTI_LINE',
  description: 'Dos o tres frases. Es lo que se lee debajo del título en la app.',
});

client.createSimpleField({
  modelApiId: MODELO,
  apiId: 'fecha',
  displayName: 'Fecha',
  type: SimpleFieldType.Date,
  isRequired: true,
  description: 'Ordena la lista en la app: lo más reciente primero.',
});

client.createSimpleField({
  modelApiId: MODELO,
  apiId: 'duracion',
  displayName: 'Duración',
  type: SimpleFieldType.String,
  description: 'Tal cual se quiera leer: "48 min", "1 h 10 min". Opcional.',
});

// La descripción de este campo se ve en el panel, debajo del selector de
// archivo. Es el único sitio donde la regla del mp3 no se puede ignorar: los
// episodios que la emisora exporta hoy pesan unos 48 MB y el tope son 50.
client.createRelationalField({
  modelApiId: MODELO,
  apiId: 'audio',
  displayName: 'Audio',
  type: RelationalFieldType.Asset,
  description:
    'El mp3. Expórtalo en MONO a 64 kbps: así una hora pesa unos 29 MB y '
    + 'cabe de sobra. Hygraph rechaza cualquier archivo de más de 50 MB. '
    + 'IMPORTANTE: al publicar la ficha, marca también la casilla del audio, '
    + 'o se queda en borrador y en la app saldrá "Audio no disponible".',
  reverseField: {
    modelApiId: 'Asset',
    apiId: 'audioDeContenidoPremium',
    displayName: 'Audio de contenido premium',
    isList: true,
  },
});

client.createRelationalField({
  modelApiId: MODELO,
  apiId: 'portada',
  displayName: 'Portada',
  type: RelationalFieldType.Asset,
  description:
    'Imagen cuadrada. Si se deja vacía, la app pone el logo de la emisora. '
    + 'Al publicar, marca también su casilla.',
  reverseField: {
    modelApiId: 'Asset',
    apiId: 'portadaDeContenidoPremium',
    displayName: 'Portada de contenido premium',
    isList: true,
  },
});

// La válvula de escape. Va al final porque casi nunca se usa.
client.createSimpleField({
  modelApiId: MODELO,
  apiId: 'audioUrl',
  displayName: 'URL del audio (avanzado)',
  type: SimpleFieldType.String,
  description:
    'Déjalo vacío. Solo se usa si el audio está alojado fuera de Hygraph: '
    + 'si lo llenas, la app usa esta dirección e ignora el archivo subido.',
});

const resultado = await client.run(true);

if (resultado.status === 'SUCCESS') {
  console.log(`✓ ${MODELO} creado. Migración ${resultado.id}`);
} else {
  console.error(`✗ La migración falló (${resultado.status}):`);
  console.error(resultado.errors);
  process.exit(1);
}
