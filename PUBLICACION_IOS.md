# Publicación en App Store

Plan para llevar la app de la emisora a la App Store. Documento vivo: marca las
casillas según avances y anota aquí las decisiones que se tomen.

**Contexto de partida:** se desarrolla en Linux, sin Mac. No hace falta: se compila
y se firma en la nube. Hay un iPhone disponible para probar y tomar capturas.

---

## 1. Cuenta de Apple Developer — DECIDIDO (09/11/2026)

**Se compra la cuenta individual ahora y se migra a la OFP después.** Decisión del
cliente: salir cuanto antes pesa más que ahorrarse la cuota.

- [x] Inscripción enviada y **pagada** el 17/11/2026 desde la app Apple Developer
      (*Individual / Sole Proprietor*). Estado: **Enrollment Pending**, a la espera
      de que Apple la apruebe (24-48 h habitualmente).

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

## 3. Política de privacidad y soporte — LISTO, falta activar Pages

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

- [ ] **Activar GitHub Pages**: Settings → Pages → *Deploy from a branch* → rama
      `main`, carpeta `/docs` → Save.
- [ ] Comprobar que las dos URLs responden antes de enviar a revisión. Apple las
      revisa en cada actualización y, si dejan de responder, puede retirar la app.

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
- [ ] Generar la **API key** en Users and Access → Integrations → Team Keys, rol
      App Manager. Es la pieza que permite firmar y publicar sin Mac. El archivo
      `.p8` **solo se descarga una vez**; hay que guardarlo junto al Key ID y al
      Issuer ID.

---

## 6. Codemagic — `codemagic.yaml` escrito, falta la API key

El workflow está en `codemagic.yaml`, en la raíz del repositorio: instala
dependencias, corre `flutter analyze` y los tests (si fallan, no se gastan minutos
de macOS compilando), saca el número de build de lo que ya hay en TestFlight para
que nunca se repita, resuelve los pods, compila el IPA firmado y lo sube a
TestFlight.

Plan gratuito: ~500 minutos de macOS al mes y un build en paralelo. Un build de
esta app ronda 10-15 min. Descartado Xcode Cloud: se configura desde Xcode, o sea
desde un Mac.

Falta hacer en la interfaz de Codemagic, que no se puede dejar escrito en el YAML:

- [x] API key cargada en Codemagic como `mohana-app-store-connect`.
- [ ] **Regenerarla con rol Admin.** La primera se creó con App Manager y el build
      falló con «No matching profiles found for bundle identifier». Apple no da
      acceso a Certificates, Identifiers & Profiles por la API salvo con Admin, así
      que la firma no puede crear el certificado ni el perfil.
- [x] `APP_STORE_APPLE_ID` ya puesto: 6836393064.
- [ ] Conectar el repositorio y lanzar el primer build.

### Por qué falló el primer build

`No matching profiles found for bundle identifier "com.ofp.lamohanaradio" and
distribution type "app_store"`. El bloque `ios_signing` de Codemagic solo **busca**
certificados y perfiles ya subidos; no los crea. En una cuenta recién hecha no hay
ninguno, así que no encontraba nada que usar.

La solución son dos pasos explícitos en el workflow: `app-store-connect
fetch-signing-files --create`, que genera el certificado de distribución y el perfil
de App Store si faltan, y `xcode-project use-profiles`, que los aplica al proyecto.
Este último va **después** de `pod install`, porque CocoaPods regenera
`Pods.xcodeproj` y borraría los ajustes de firma si se hiciera antes.

### Los demás fallos del estreno, por orden

1. **«Cannot save Signing Certificates without certificate private key».**
   `fetch-signing-files --create` daba de alta el certificado en Apple pero no
   podía guardarlo sin una clave privada. Se generó una clave RSA y se guardó como
   variable protegida `CERTIFICATE_PRIVATE_KEY` en el grupo `firma_ios` de
   Codemagic. Tiene que ser siempre la misma: una nueva en cada build iría
   acumulando certificados y Apple solo permite tres.
2. **«FLUTTER_BUILD_NUMBER is used by the framework and cannot be set».** Ese
   nombre lo reserva Flutter y `flutter build` aborta si lo encuentra en el
   entorno. La variable pasó a llamarse `NUMERO_BUILD` y se entrega por
   `--build-number`.
3. **ITMS-90683, build 1 rechazado al procesarse.** La app compiló y subió bien,
   pero Apple la rechazó por falta de `NSMicrophoneUsageDescription` en el
   `Info.plist`. La app no graba nada; la cadena se exige igualmente porque
   `just_audio` y `audio_session` referencian APIs de `AVAudioSession` que pueden
   acceder a la entrada de audio. Aviso importante: este rechazo **no aparece en
   el log de Codemagic**, llega por correo a la cuenta del desarrollador.

CocoaPods, que era lo que más preocupaba, pasó sin problemas a la primera.

### Aviso sin urgencia

**ITMS-90725:** el build se hizo con el SDK de iOS 26.5. Desde abril de 2027, App
Store Connect exigirá el SDK de iOS 27 o posterior. No bloquea nada hoy.

## 7. Pruebas en iPhone por TestFlight — el paso que más importa

iOS se comporta distinto a Android en audio, y es justo el corazón de esta app.

- [ ] Directo: que suene, y que **siga sonando con la app cerrada y la pantalla
      bloqueada**.
- [ ] Controles en la notificación y en la pantalla de bloqueo: título, carátula,
      play/pausa.
- [ ] Reconexión al cortar y restablecer la red.
- [ ] Episodios: cola, velocidad, ±10/30 s y reanudación donde se quedaron.
- [ ] Que no se desborde nada con la letra del sistema ampliada.

Un simulador no sirve para esto: no reproduce el comportamiento de audio en segundo
plano.

---

## 8. Capturas y envío a revisión

- [ ] Capturas desde el iPhone: 6.9" (1320×2868) y 6.5". Si se deja iPad, también 13".
- [ ] Completar el cuestionario de privacidad en App Store Connect.
- [ ] Enviar a revisión. Normalmente 1–3 días.

---

## Estado

Hecho: pasos 2, 3 (falta un clic en GitHub), 4 y 4 bis.
Pendiente: comprar la cuenta (paso 1) — desbloquea los pasos 5 a 8, que van en
orden y no se pueden adelantar.

```
1 (cuenta) ──► 5 (App Store Connect) ──► 6 (Codemagic) ──► 7 (TestFlight) ──► 8 (envío)
```

Plazo estimado desde que exista la cuenta: **1 a 2 semanas**. Cinco días si todo
sale limpio; dos semanas si Apple rechaza la primera entrega, que es frecuente en
la primera app de una cuenta.
