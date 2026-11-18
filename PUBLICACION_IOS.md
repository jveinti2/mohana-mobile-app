# Publicación en App Store

Plan para llevar la app de la emisora a la App Store. Documento vivo: marca las
casillas según avances y anota aquí las decisiones que se tomen.

**Contexto de partida:** se desarrolla en Linux, sin Mac. No hace falta: se compila
y se firma en la nube. Hay un iPhone disponible para probar y tomar capturas.

---

## 1. Cuenta de Apple Developer — HECHO (18/11/2026)

**Se compra la cuenta individual ahora y se migra a la OFP después.** Decisión del
cliente: salir cuanto antes pesa más que ahorrarse la cuota.

- [x] Inscripción pagada el 17/11/2026 (459.900 COP, renovación anual el
      17/11/2027) y **aprobada el 18/11/2026**, como *Individual / Sole Proprietor*.

### El pago falló dos veces: qué pasaba

Ni la tarjeta virtual de DolarApp ni la física de Nu pasaban, las dos salían en
`(Error)` en Ajustes → Pago y envío. La causa no era ninguna de las dos: había un
**saldo pendiente en la cuenta de Apple** de una suscripción que no se pudo cobrar.
Con un saldo pendiente, Apple rechaza cualquier método de pago nuevo que añadas, y
el mensaje que muestra habla del método de pago, no de la deuda.

Se resuelve en Ajustes → tu nombre → Contenido y compras → Ver cuenta → Historial
de compras, pagando el pedido que aparece en rojo. Dicho sea de paso: Apple no
acepta tarjetas prepago ni virtuales para esta inscripción, así que la de DolarApp
no habría servido igualmente.

### Lo que esto implica

La ficha saldrá a nombre de **Jhonatan Becerra Pedrozo**, no de la Organización
Femenina Popular, y la cuenta queda atada a una persona. Son 459.900 COP al año
hasta que se complete la migración.

Sobre el precio: Apple cobra 459.900 COP y no los ~320.000 que darían 99 USD a la
TRM. La diferencia es el IVA del 19 % más una tasa de cambio fija propia de Apple
(~3.900 COP/USD) que no sigue al mercado. No depende de ninguna configuración del
teléfono: lo determina el país del Apple ID.

### La migración posterior

Se hace con un **App Transfer**, y los usuarios no notan nada. Verificado contra la
documentación de Apple y contra las dependencias de esta app, que no usa iCloud,
Apple Pay, Sign in with Apple, Game Center, Wallet, keychain compartido ni push —
que es justo lo que complica una transferencia. Se conservan el bundle ID, la URL
de App Store, reseñas, valoraciones y las actualizaciones para quien ya la tenga
instalada. Lo único que cambia a la vista es el nombre del desarrollador.

Para que la cuenta de la OFP salga gratis, al inscribirla hay que pedir la
**exención de cuota** para organizaciones sin ánimo de lucro, y pedirla *durante*
su inscripción: no se puede añadir después. La OFP califica (entidad legal con NIT,
app gratuita que no vende nada), pero exige el trámite del D-U-N-S, de 1 a 2
semanas.

Condiciones de la transferencia, para cuando toque:

- La app debe estar ya publicada en App Store.
- Antes de iniciarla hay que borrar todos los builds y testers de TestFlight y
  vaciar los campos de Test Information.
- La cuenta de la OFP debe estar inscrita y aprobada **antes** de iniciarla.
- El historial de analítica se queda en la cuenta de origen. Para una app gratuita
  es irrelevante.

Conviene no dejarlo pasar de un año, o se pagará una segunda anualidad.

## 2. Cambios de código iOS — HECHO (05/11/2026)

- [x] `PRODUCT_BUNDLE_IDENTIFIER` → `com.ofp.lamohanaradio`, igual que Android.
      Antes era `com.mohana.mohana`. También el del target de tests.
      **Crítico:** una vez subido un build a App Store Connect ya no se puede cambiar.
- [x] `ITSAppUsesNonExemptEncryption = false` en `Info.plist`. La app no usa cifrado
      propio, solo HTTPS del sistema; evita el cuestionario de exportación en cada subida.
- [x] `ios/Runner/PrivacyInfo.xcprivacy` creado y registrado en el proyecto de Xcode
      (referencia, grupo y fase de Resources). Declara: sin seguimiento, sin recogida
      de datos, y dos APIs de motivo requerido — `UserDefaults` (CA92.1) por
      `shared_preferences`, y marcas de tiempo de archivo (C617.1) por la caché en
      disco. Sin este archivo, App Store Connect rechaza automáticamente.
- [x] **Solo iPhone**: `TARGETED_DEVICE_FAMILY` pasa de `"1,2"` a `"1"` y se quitan
      las orientaciones `~ipad` del `Info.plist`. La app se sigue instalando en iPad,
      pero en modo de compatibilidad iPhone. Evita tener que entregar capturas de 13"
      y hacer QA en tableta.
- [x] Corregido de paso: `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
      valía `AppIcon` en dos configuraciones del proyecto, cuando es un ajuste booleano.
      Lo dejó así `flutter_launcher_icons` al generar los iconos. Restaurado a `YES`.
      El icono en sí estaba bien: `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` sigue
      presente en las tres configuraciones del target.
- [ ] `flutter analyze` y `flutter test`: **no ejecutados**, Flutter no está instalado
      en esta máquina. No cambió ni una línea de Dart, así que no hay riesgo, pero
      conviene pasarlos antes de la primera subida.

Ya estaba correcto y no se tocó: `UIBackgroundModes: audio`, el stream en HTTPS (no
hace falta excepción ATS), el icono de 1024 sin canal alfa y el target iOS 13.

Nota sobre Android: nada de esto le afecta. El `applicationId` de Android ya era
`com.ofp.lamohanaradio` — el cambio fue para que iOS se igualara. Lo único compartido
es la versión de `pubspec.yaml`: los builds que se gasten en TestFlight consumen
números de build, así que el `versionCode` de la próxima versión de Android arrancará
más alto. Play Store solo exige que sea mayor que el último publicado, no consecutivo.

## 3. Política de privacidad y soporte — PUBLICADO

Dos páginas en `docs/`, ya con el correo de la OFP (Comunicaciones.ofp@gmail.com)
y fecha del 9 de noviembre de 2026:

- `docs/index.html` — política de privacidad. Refleja la realidad de la app: no
  recoge ningún dato, solo guarda caché local, y lista los terceros a los que se
  conecta (Zeno.fm, iVoox, Hygraph, Google Fonts).
- `docs/soporte.html` — página de soporte con contacto y preguntas frecuentes.
  Apple exige una **URL** de soporte y no admite un correo; como la OFP no tiene
  web, se resuelve aquí.

El mismo texto de la política queda en `documentos/politica-privacidad.md` para
que la OFP lo edite sin tocar HTML.

- [x] GitHub Pages activo desde este mismo repositorio, que es público:
      - Privacidad: <https://jveinti2.github.io/mohana-mobile-app/>
      - Soporte: <https://jveinti2.github.io/mohana-mobile-app/soporte.html>
- [ ] Volver a comprobar que ambas responden justo antes de enviar a revisión.
      Apple las revisa en cada actualización y, si dejan de responder, puede
      retirar la app.

Si algún día la OFP tiene dominio propio, conviene mudarlas allí: una URL
institucional no queda atada a una cuenta personal de GitHub.

## 4. Textos de la ficha — LISTO

Todo en `documentos/ficha-app-store.md`, listo para copiar en App Store Connect:
nombre, subtítulo, descripción (con el párrafo sobre la OFP ya redactado),
palabras clave, categoría, clasificación por edad, URLs, texto para el revisor y
notas de versión.

Clasificación por edad: Apple ya no deja elegirla, la calcula desde un
cuestionario cuyos tramos son 4+, 9+, 13+, 16+ y 18+. Las respuestas recomendadas
están en el documento y dan **13+**. La emisora trata sociedad, política y opinión
pública, y el directo va sin guion: declarar 4+ es lo que expone a un rechazo por
haber declarado de menos.

## 4 bis. Pantalla «Nosotras» — HECHO (09/11/2026)

Antes mostraba el logo de la OFP y la palabra «Próximamente». Apple rechaza por
contenido de marcador de posición (directriz 2.1, *App Completeness*), así que era
un rechazo casi seguro.

- [x] Redactada con contenido real: origen en 1972 en el nororiente de
      Barrancabermeja, autonomía desde 1988, el Movimiento Social de Mujeres contra
      la Guerra y por la Paz de 1996, las Casas de la Mujer, y qué es la emisora
      dentro de la organización. Texto corto a propósito.
- [x] `flutter analyze` limpio y los 307 tests pasan, incluidos los de desbordes en
      cinco tamaños de pantalla por tres escalas de letra.
- [x] Cifras confirmadas por el cliente (1972, +10 municipios, 2.700 mujeres).
- [x] Sin enlaces a web ni redes: la OFP no considera necesario comunicarlas aquí,
      y `ofp.org.co` no respondía al comprobarlo.

## 5. App Store Connect — HECHO (18/11/2026)

Cuenta de desarrollador aprobada el 18/11/2026. **Team ID: 5WGZBLZBDM.**

- [x] App ID registrado en el portal con bundle id explícito `com.ofp.lamohanaradio`,
      sin capacidades: la app no usa push ni iCloud, y el audio en segundo plano se
      declara en el `Info.plist`, no en el App ID. El campo *Description* del App ID
      no admite caracteres especiales, así que el punto de «91.2» hay que quitarlo.
- [x] App creada en App Store Connect. **Apple ID: 6836393064.**
- [x] **API key** generada en Users and Access → Integrations → Team Keys, con rol
      **Admin**. Es la pieza que permite firmar y publicar sin Mac. El `.p8` solo
      se descarga una vez; está guardado en `~/.secretos/apple/` junto a un
      `LEEME.txt` con los cuatro identificadores (Key ID `36GU4TGF2G`, Issuer ID,
      Team ID y Apple ID de la app). Fuera del repositorio, y `*.p8` está en
      `.gitignore`.

El rol tiene que ser **Admin**, no App Manager: Apple no da acceso a
*Certificates, Identifiers & Profiles* por la API con App Manager, y la firma no
podría crear el certificado ni el perfil.

---

## 6. Codemagic — FUNCIONANDO (18/11/2026)

El workflow está en `codemagic.yaml`, en la raíz del repositorio: instala
dependencias, corre `flutter analyze` y los tests (si fallan, no se gastan minutos
de macOS compilando), saca el número de build de lo que ya hay en TestFlight para
que nunca se repita, crea el certificado y el perfil de firma, resuelve los pods,
compila el IPA firmado y lo sube a App Store Connect.

Plan gratuito: ~500 minutos de macOS al mes y un build en paralelo. Un build
completo de esta app tarda unos 20 minutos. Descartado Xcode Cloud: se configura
desde Xcode, o sea desde un Mac.

- [x] API key cargada en Codemagic como `mohana-app-store-connect`.
- [x] Grupo de variables `firma_ios` con `CERTIFICATE_PRIVATE_KEY` (clave RSA,
      marcada como *Secure*). El original está en
      `~/.secretos/apple/certificado_privado.pem`.
- [x] `APP_STORE_APPLE_ID`: 6836393064.
- [x] Repositorio conectado y pipeline verde de punta a punta.

### Los cinco fallos del estreno, por orden

Esta app nunca se había compilado para iOS. Queda escrito porque ninguno era
evidente desde el log y varios volverían a aparecer si se monta el proyecto de
cero.

1. **`No matching profiles found for bundle identifier`.** El bloque `ios_signing`
   de Codemagic solo **busca** certificados y perfiles ya subidos; no los crea, y
   en una cuenta recién hecha no hay ninguno. Se sustituyó por dos pasos
   explícitos: `app-store-connect fetch-signing-files --create`, que los genera, y
   `xcode-project use-profiles`, que los aplica al proyecto. Este último va
   **después** de `pod install`, porque CocoaPods regenera `Pods.xcodeproj` y
   borraría los ajustes de firma si se hiciera antes.
2. **`Cannot save Signing Certificates without certificate private key`.**
   `--create` daba de alta el certificado en Apple pero no podía guardarlo sin una
   clave privada local. Se generó una RSA y se guardó como variable protegida en
   Codemagic. Tiene que ser siempre la misma: una nueva en cada build iría
   acumulando certificados y Apple solo permite tres.
3. **`FLUTTER_BUILD_NUMBER is used by the framework and cannot be set`.** Ese
   nombre lo reserva Flutter y `flutter build` aborta si lo encuentra en el
   entorno. La variable pasó a llamarse `NUMERO_BUILD` y se entrega por
   `--build-number`.
4. **ITMS-90683, binario rechazado al procesarse.** La app compiló y subió bien,
   pero Apple la rechazó por falta de `NSMicrophoneUsageDescription` en el
   `Info.plist`. La app no graba nada; la cadena se exige igualmente porque
   `just_audio` y `audio_session` referencian APIs de `AVAudioSession` que pueden
   acceder a la entrada de audio. **Este rechazo no aparece en el log de
   Codemagic**: el build sale como fallido por no encontrar nunca la compilación en
   TestFlight, y el motivo real llega por correo al titular de la cuenta.
5. **`Complete test information is required... for external testing`.** El binario
   se procesó bien, pero el último paso lo enviaba a la revisión de TestFlight
   *externa*, que pide correo de contacto y datos del responsable y añade un día de
   espera a cada entrega. Para probar en el iPhone propio bastan las pruebas
   **internas**, que no pasan por revisión. El workflow quedó en
   `submit_to_testflight: false`.

CocoaPods, que era lo que más preocupaba, pasó a la primera.

### Aviso sin urgencia

**ITMS-90725:** el build se hizo con el SDK de iOS 26.5. Desde abril de 2027, App
Store Connect exigirá el SDK de iOS 27 o posterior. No bloquea nada hoy.

---

## 7. Pruebas en iPhone por TestFlight — EN CURSO

**La compilación 1.3.0 (1) está instalada en el iPhone** desde el 18/11/2026, por
el grupo interno `equipo`. Las pruebas internas no pasan por revisión: el build
queda disponible en cuanto Apple termina de procesarlo.

Un apunte por si vuelve a pasar: TestFlight pide un «código de canje» cuando no
hay ninguna app disponible para la cuenta con la que se entró. No es que falte un
código — es que la invitación no se ha aceptado todavía o la sesión es de otro
Apple ID. Se resuelve abriendo desde el iPhone el correo de invitación y pulsando
*View in TestFlight*.

Es el paso que más importa: iOS se comporta distinto a Android justo en lo que es
el corazón de esta app.

- [ ] Directo sonando **con la app cerrada** (cerrada del todo, no minimizada) y la
      pantalla bloqueada.
- [ ] Controles en la notificación y en la pantalla de bloqueo: título, carátula,
      play/pausa.
- [ ] Modo avión unos segundos y de vuelta: el directo debe reconectarse solo.
- [ ] Episodios: cola, velocidad, ±10/30 s y reanudación donde se quedaron.
- [ ] Tamaño del texto del sistema al máximo, recorriendo las pantallas en busca de
      textos cortados.

Un simulador no sirve para esto: no reproduce el comportamiento de audio en
segundo plano.

---

## 8. Ficha, capturas y envío a revisión — PENDIENTE

**Bloqueador conocido:** la versión en App Store Connect se creó como **1.0** y el
build es **1.3.0**. Tienen que coincidir para poder enviar a revisión, así que hay
que cambiar la versión a `1.3.0` en App Store Connect.

Todos los textos están redactados en `documentos/ficha-app-store.md`; esto es
copiar y pegar.

- [ ] **Información de la app:** subtítulo (`La radio de las mujeres`) y categoría
      (Principal: Música, Secundaria: Noticias).
- [ ] **Clasificación por edades:** responder el cuestionario. Las respuestas
      recomendadas están en el documento y dan **13+**.
- [ ] **Privacidad de la app:** cuestionario declarando que no se recoge ningún
      dato, y la URL `https://jveinti2.github.io/mohana-mobile-app/`.
- [ ] **Versión 1.3.0:** descripción, palabras clave, URL de soporte
      (`.../soporte.html`), notas de versión.
- [ ] **Capturas** desde el iPhone: inicio, directo sonando, lista de podcasts, un
      episodio reproduciéndose y las publicaciones. Apple exige medidas exactas
      (1320×2868 para 6.9"); si el iPhone es más pequeño hay que ajustarlas antes
      de subirlas.
- [ ] **Revisión de apps:** datos de contacto y el texto para el revisor.
- [ ] Enviar. Normalmente 1-3 días.

---

## Estado a 18/11/2026

Hecho: pasos 1 a 6. La cuenta está pagada y aprobada, la app creada, y **el
pipeline completo funciona**: un push a `main` compila, firma y sube a TestFlight
sin tocar un Mac. La compilación 1.3.0 (1) está instalada en el iPhone.

En curso: paso 7, probar el audio en el dispositivo.
Pendiente: paso 8, rellenar la ficha, hacer las capturas y enviar a revisión.

```
7 (pruebas en iPhone) ──► 8 (ficha + capturas + envío) ──► revisión de Apple
```

Lo que queda es trabajo de ficha y de pruebas, no de infraestructura. Si las
pruebas no destapan nada, se puede enviar a revisión en un par de días.

### Datos de la cuenta

| | |
|---|---|
| Team ID | `5WGZBLZBDM` |
| Bundle ID | `com.ofp.lamohanaradio` |
| Apple ID de la app | `6836393064` |
| Key ID de la API | `36GU4TGF2G` |
| Secretos | `~/.secretos/apple/` (fuera del repositorio) |
