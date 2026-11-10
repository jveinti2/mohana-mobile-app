# Despliegue en App Store — Emisora La Mohana 91.2 FM

Plan de salida a producción en iOS. Estado del proyecto a 27/10/2026: nunca se
ha compilado para iOS, no hay cuenta de Apple y no hay Mac. El entorno de
desarrollo es Linux, así que la compilación va por integración continua.

Hermano de este documento: la app ya está en producción en Google Play con la
versión 10 (1.2.1) y 34 instalaciones.

---

## Decisiones tomadas

| Asunto | Decisión | Por qué |
|---|---|---|
| Tipo de cuenta | **Individual**, a nombre de Jorge Becerra | No se paga inscripción de empresa. La de organización exige D-U-N-S, correo en dominio propio y web institucional funcional |
| Nombre de vendedor | El nombre legal del titular | Apple no admite nombres comerciales en cuentas individuales. No es configurable |
| Nombre en la tienda | `Emisora La Mohana 91.2 FM` | Es lo que la gente ve, busca y recuerda. El nombre legal solo sale en la línea pequeña de desarrollador |
| Dispositivos | **Solo iPhone** en la primera versión | Declarar iPad obliga a que Apple revise en iPad y exige capturas de 13". Se añade después si hace falta |
| Compilación | **Codemagic** (cuenta personal) | 500 minutos gratis de macOS M2 al mes. Compila, firma y sube a TestFlight sin Mac |
| Pruebas | iPhone del titular vía TestFlight | Imprescindible: el audio en segundo plano no se puede validar de otra forma |
| Bundle ID | `com.ofp.lamohanaradio` | Igual que Android. **Inmutable una vez publicada** |

### Sobre usar la cuenta de otra persona de la emisora

Técnicamente da igual: seguiría saliendo el nombre legal de esa persona, no el
de la emisora. Y añade un riesgo que no compensa — la cuenta, los certificados
y la renovación anual quedarían atados a alguien que puede dejar la
organización. Si algún día la app debe figurar a nombre de la OFP, el camino es
la **transferencia de app**, no cambiar de titular ahora.

### La puerta que queda abierta

Apple permite transferir una app publicada a otra cuenta conservando
**valoraciones, reseñas, bundle ID y los usuarios ya instalados**, que siguen
recibiendo actualizaciones. Requisitos: que la app tenga al menos una versión
publicada y que la cuenta de destino sea una organización verificada. Nada de
lo que esta app usa impide la transferencia (no hay compras integradas, Game
Center, Apple Pay, Wallet ni Sign in with Apple).

Conclusión práctica: publicar ahora como individual **no cierra** la opción de
que mañana figure la OFP. Pedir el D-U-N-S sigue siendo útil y es gratis
(`https://developer.apple.com/enroll/duns-lookup/`), y además resuelve la
conversión pendiente de la cuenta de Google Play.

---

## Fase 0 — Cuenta de Apple (bloquea todo lo demás)

Sin cuenta pagada no se puede firmar ni instalar nada en el iPhone: la firma con
Apple ID gratuito requiere Xcode, es decir macOS.

1. Activar la verificación en dos pasos en el Apple ID que vaya a ser el titular.
2. Inscribirse en <https://developer.apple.com/programs/enroll/> como **Individual**.
   - Nombre y apellidos **legales**, tal como aparecen en el documento de identidad.
     Un alias o un nombre de marca retrasa la aprobación.
   - Dirección verificable (no apartados de correos), teléfono y correo.
3. Pagar **99 USD/año**.
4. Esperar la activación: normalmente horas, a veces 48 h.
5. Aceptar los acuerdos en App Store Connect → *Business* (sin esto no se puede
   subir nada).

---

## Fase 1 — Preparar el proyecto (sin dependencias; se puede hacer ya)

Todo esto son cambios de repositorio, no requieren cuenta ni Mac.

1. **Bundle ID**: `com.mohana.mohana` → `com.ofp.lamohanaradio` en
   `ios/Runner.xcodeproj/project.pbxproj` (3 apariciones del target Runner).
2. **Nombre visible**: `CFBundleDisplayName` de `Mohana` a `La Mohana`
   (bajo el icono caben ~12 caracteres).
3. **Limitar a iPhone**: `TARGETED_DEVICE_FAMILY = 1` en las tres
   configuraciones, y quitar las orientaciones de iPad del `Info.plist`.
4. **Iconos**: añadir a git los 6 ficheros de `AppIcon.appiconset` sin versionar
   (50×50, 57×57, 72×72), que el `Contents.json` sí referencia.
5. **Crear `codemagic.yaml`** en la raíz del repositorio (ver Fase 3).
6. Verificar con `flutter analyze` y `flutter test`.

### Lo que ya está correcto y no hay que tocar

- `UIBackgroundModes: audio` en el `Info.plist` — es el equivalente iOS del
  servicio en primer plano de Android. Ya estaba.
- `AppDelegate.swift` no necesita nada: a diferencia de Android, iOS no requiere
  el equivalente de `AudioServiceActivity` ni declarar servicios.
  `audio_service` configura la `AVAudioSession` en categoría *playback* por su
  cuenta, y la pantalla de bloqueo la pinta el sistema desde el `MediaItem` que
  ya lleva cada fuente de audio.
- Todas las URLs son `https` (Zeno.fm, iVoox, Hygraph): no hace falta excepción
  de App Transport Security, que es causa habitual de rechazo.
- El icono de 1024×1024 es RGB sin canal alfa. App Store Connect rechaza los que
  tienen transparencia.
- `IPHONEOS_DEPLOYMENT_TARGET = 13.0` sirve para los plugins actuales.
- El icono monocromo de notificación y `res/raw/keep.xml` son solo de Android.
  No aplican aquí.

---

## Fase 2 — App Store Connect

1. **Identificadores** → <https://developer.apple.com/account/resources/identifiers>
   → nuevo **App ID** con el bundle ID `com.ofp.lamohanaradio`, capability
   **Background Modes** activada.
2. **Nueva app** en <https://appstoreconnect.apple.com> → *Apps* → `+`:
   - Plataforma: iOS
   - Nombre: `Emisora La Mohana 91.2 FM`
   - Idioma principal: **Español (México)** — App Store Connect no tiene `es-419`
   - Bundle ID: el del paso anterior
   - SKU: `lamohana-ios-001` (interno, no se publica)
3. **Clave de API** → *Users and Access* → *Integrations* → `+`, rol **App Manager**.
   Descargar el `.p8` (solo se puede una vez) y anotar el **Issuer ID** y el **Key ID**.
   Esas tres cosas son lo que necesita Codemagic.

---

## Fase 3 — Codemagic

1. Crear cuenta **personal** en <https://codemagic.io> con el usuario de GitHub.
   No crear un "Team": los equipos no tienen minutos gratis.
2. Conectar el repositorio `jveinti2/mohana-mobile-app`.
3. *Teams/Integrations* → **App Store Connect**: subir el `.p8`, el Issuer ID y
   el Key ID. Codemagic genera y gestiona los certificados y perfiles solo.
4. Añadir el `codemagic.yaml` siguiente a la raíz del repositorio:

```yaml
workflows:
  ios-testflight:
    name: iOS → TestFlight
    instance_type: mac_mini_m2
    max_build_duration: 60
    working_directory: app
    integrations:
      app_store_connect: lamohana-asc   # nombre dado a la integración en el paso 3
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.ofp.lamohanaradio
      vars:
        APP_STORE_APPLE_ID: 0000000000  # el "Apple ID" numérico de la app
    scripts:
      - name: Dependencias
        script: flutter pub get
      - name: Pods
        script: find . -name "Podfile" -execdir pod install \;
      - name: Lints y pruebas
        script: |
          flutter analyze
          flutter test
      - name: Número de build
        script: |
          BUILD=$(($(app-store-connect get-latest-testflight-build-number \
            "$APP_STORE_APPLE_ID") + 1))
          echo "BUILD_NUMBER=$BUILD" >> $CM_ENV
      - name: Compilar IPA
        script: |
          flutter build ipa --release \
            --build-number=$BUILD_NUMBER \
            --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
      - flutter_drive.log
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
```

5. Lanzar el primer build. **Contar con que falle**: nadie ha ejecutado
   `pod install` en este proyecto nunca, y `just_audio_background` y
   `audio_service` traen código nativo iOS. Los fallos típicos son versión
   mínima de pods por debajo de lo que pide un plugin y el `Podfile` que se
   genera por primera vez.

---

## Fase 4 — Probar en el iPhone (no es opcional)

Instalar TestFlight en el iPhone y aceptar la invitación. El audio en segundo
plano es exactamente lo que se acaba de arreglar en Android y lo que iOS gestiona
de otra forma, así que hay que recorrerlo entero:

- [ ] El directo suena al dar play
- [ ] Sale del app y sigue sonando
- [ ] Pantalla bloqueada: aparece el control con carátula, título y emisora
- [ ] Play/pausa desde la pantalla de bloqueo responden
- [ ] **Diez minutos en segundo plano con la pantalla bloqueada sin que se corte**
- [ ] Llamada entrante: el audio se pausa y se reanuda al colgar
  *(caso que Android no tiene; si falla, es configuración de `AVAudioSession`)*
- [ ] Con el móvil en silencio sigue sonando (categoría *playback*)
- [ ] Un episodio de podcast: velocidad, ±30 s y que reanude donde se dejó
- [ ] Cortar el wifi 30 s y recuperarlo: el directo se reconecta solo
- [ ] Letra grande del sistema (Ajustes → Pantalla → Tamaño del texto al máximo):
      nada se desborda

---

## Fase 5 — Ficha y envío

1. **Capturas** (sin canal alfa, PNG o JPEG). Obligatorias dos tamaños de iPhone:
   - 6.1" Dynamic Island: 1179×2556 o 1206×2622
   - Pantalla grande: 1290×2796 (6.9") o 1284×2778 (6.5")

   Se toman en el iPhone y se ajustan al tamaño exacto desde Linux con
   ImageMagick. Las que hay en `docs/` son de Android y no sirven tal cual.
2. **Textos**: descripción, subtítulo, palabras clave, novedades.
3. **Categoría**: Música (principal), Noticias (secundaria).
4. **Política de privacidad**: URL pública obligatoria. Usar la misma de Play
   (el documento está en `docs/privacy_policy.html`; hace falta su URL publicada).
5. **Privacidad de la app**: sin login, sin analítica, sin publicidad →
   **"No se recopilan datos"**. Es declarable y defendible.
6. **Notas para el revisor**: que no hay cuenta de usuario, y que la emisora
   pertenece a la Organización Femenina Popular, que autoriza la emisión del
   directo y de los podcasts. Apple suele pedir prueba de derechos de contenido
   en apps de radio.
7. **Enviar a revisión.** 24–72 h habitualmente; la primera de una cuenta nueva
   puede tardar más.

---

## Riesgos de rechazo, por probabilidad

1. **Derechos de contenido** (lo más probable). Apple pide acreditar que se
   puede emitir la emisora y los podcasts. Tener lista una carta de la OFP.
2. **Guideline 4.2, funcionalidad mínima.** Una app que "solo pone una radio"
   se rechaza a veces por delgada. Ésta tiene podcasts con velocidad y
   reanudación, artículos y parrilla: que las capturas enseñen eso y no solo el
   reproductor del directo.
3. **Privacidad mal declarada.** Declarar "no se recopilan datos" y que luego
   se detecte lo contrario es rechazo seguro. En esta app es cierto.
4. **Capturas con transparencia o del tamaño equivocado.** Rechazo automático,
   trivial de evitar.

---

## Costes

| Concepto | Coste |
|---|---|
| Apple Developer Program | 99 USD/año (recurrente) |
| Codemagic | 0 — 500 min/mes de macOS gratis en cuenta personal |
| iPhone de pruebas | ya se tiene |
| **Total de arranque** | **99 USD** |

Un build de esta app ronda los 10–15 minutos, así que 500 minutos dan para unos
35 builds mensuales. De sobra.

---

## Camino crítico

```
Fase 0 (cuenta, horas-48h)  ─┐
                             ├─→ Fase 2 → Fase 3 → Fase 4 → Fase 5 → publicada
Fase 1 (código, ya)         ─┘
```

La Fase 1 no depende de nada y se puede cerrar hoy. Lo único que de verdad
bloquea es la inscripción, y después de ella todo lo demás son horas de trabajo
más el tiempo de revisión de Apple.
