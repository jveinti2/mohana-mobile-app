# Publicación en App Store

Plan para llevar la app de la emisora a la App Store. Documento vivo: marca las
casillas según avances y anota aquí las decisiones que se tomen.

**Contexto de partida:** se desarrolla en Linux, sin Mac. No hace falta: se compila
y se firma en la nube. Hay un iPhone disponible para probar y tomar capturas.

---

## 1. Cuenta de Apple Developer — BLOQUEADO, a definir con el cliente

Hay que elegir entre dos vías antes de tocar nada de Apple.

| | Individual | Organización (OFP) |
|---|---|---|
| Coste | **459.900 COP/año** | **0** (exención para ONG) |
| Trámite previo | ninguno | D-U-N-S, 1–2 semanas |
| Nombre en la ficha | Jhonatan Becerra Pedrozo | Organización Femenina Popular |
| Titularidad | personal | de la OFP |

### Sobre el precio en pesos

Apple cobra 459.900 COP, no los ~320.000 que darían 99 USD a la TRM. La diferencia
es IVA del 19 % más una tasa de cambio fija propia de Apple (~3.900 COP/USD) que no
se actualiza con el mercado. No depende de ninguna configuración del teléfono: lo
determina el país del Apple ID y la dirección de facturación.

### Sobre la exención de cuota

Apple exime la cuota anual completa a organizaciones sin ánimo de lucro reconocidas
oficialmente. La OFP califica: es entidad legal con NIT, la app es gratuita y no
vende bienes ni servicios digitales. Dos condiciones que hay que respetar:

- Una persona natural **no** puede pedirla. Exige inscribirse como organización.
- Se solicita **durante** la inscripción. No se puede añadir después.

### Si se paga ahora como individuo, ¿se puede pasar luego a la OFP?

Sí, con un **App Transfer**, y los usuarios no notan nada. Verificado contra la
documentación de Apple y contra las dependencias de esta app, que no usa iCloud,
Apple Pay, Sign in with Apple, Game Center, Wallet, keychain compartido ni push —
que son justo lo que complica una transferencia. La de esta app sale limpia.

Se conservan el bundle ID, la URL de App Store, reseñas, valoraciones y los usuarios
existentes, que siguen recibiendo actualizaciones. Lo único que cambia a la vista es
el nombre del desarrollador.

Condiciones de la transferencia:

- La app debe estar ya publicada (al menos una versión en App Store).
- Antes de iniciarla hay que borrar todos los builds y testers de TestFlight y
  vaciar los campos de Test Information.
- La cuenta de la OFP debe estar inscrita y aprobada **antes**, con su exención
  pedida en su propia inscripción.
- El historial de analítica se queda en la cuenta de origen; la OFP arranca el suyo
  desde la transferencia. Para una app gratuita es irrelevante.

Conclusión: pagar ahora no encierra en nada. Los 459.900 compran tiempo, nada más.
Si el trámite del D-U-N-S se alarga más de un año, se pagaría una segunda anualidad.

### Acciones según la vía

- [ ] **Vía organización:** pedir D-U-N-S con RUT y certificado de existencia →
      inscribirse como organización → marcar la exención durante la inscripción.
- [ ] **Vía individual:** inscribirse desde la app Apple Developer en el iPhone →
      elegir *Individual / Sole Proprietor* → verificar identidad con cédula (el
      nombre debe coincidir **exacto**, es el fallo más común) → pagar.

---

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

## 3. Política de privacidad — página lista, falta activarla

Dos versiones del mismo texto: `documentos/politica-privacidad.md` (para que la OFP
lo revise y edite) y `docs/index.html` (la página que se publica, ya con la identidad
visual de la emisora).

Refleja la realidad de la app: no recoge ningún dato, solo guarda caché local, y lista
los terceros a los que se conecta (Zeno.fm, iVoox, Hygraph, Google Fonts).

- [ ] Que la OFP complete el correo de contacto y la fecha, y revise el texto.
- [ ] **Activar GitHub Pages** en este mismo repositorio, que es público:
      Settings → Pages → Source: *Deploy from a branch* → rama `main`, carpeta
      `/docs` → Save. En un par de minutos queda en
      `https://jveinti2.github.io/mohana-mobile-app/`.
- [ ] Esa URL va en App Store Connect y no puede caerse: Apple la revisa en cada
      actualización, y si deja de responder puede retirar la app.

Si la OFP tiene dominio propio, es mejor alojarla ahí: una URL institucional da más
confianza que una de GitHub, y no queda atada a una cuenta personal. GitHub Pages
sirve perfectamente mientras tanto.

Sin esta URL **no se puede enviar a revisión**.

## 4. Textos de la ficha — borrador listo

Borrador en `documentos/ficha-app-store.md`: nombre, subtítulo, descripción,
palabras clave, categoría, clasificación por edad, texto para el revisor y notas
de versión.

- [ ] Que la OFP complete el párrafo sobre quiénes son y las redes sociales.
- [ ] Definir URL de soporte.
- [ ] Confirmar la clasificación por edad según el contenido real de los programas.

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
- [ ] **Que la OFP confirme las cifras** (1972, +10 municipios, 2.700 mujeres).
      Salen de prensa y de fuentes académicas, no de la propia organización.
- [ ] Decidir si se añaden enlaces a su web y redes. Se dejaron fuera porque
      `ofp.org.co` no respondía al comprobarlo.

## 5. App Store Connect — requiere la cuenta activa

- [ ] Crear la app con el bundle id `com.ofp.lamohanaradio`.
- [ ] Generar una **API key** en Users and Access → Integrations, rol App Manager.
      Es la pieza que permite firmar y publicar sin Mac.

---

## 6. Codemagic — requiere la API key

Plan gratuito: ~500 minutos de macOS al mes, 1 build en paralelo. Un build de esta
app ronda 10–15 min, así que sobra. Descartado Xcode Cloud: se configura desde
Xcode, o sea desde un Mac.

- [ ] Conectar el repositorio y cargar la API key.
- [ ] Activar firma automática de iOS: Codemagic genera certificado y perfil por
      API, sin que intervenga ningún Mac.
- [ ] Configurar el workflow: `flutter build ipa --release` y publicación a TestFlight.
- [ ] Primer build. Aquí salen los errores de compilación iOS que no se ven desde Linux.

---

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

## Orden de dependencias

```
1 (cuenta) ──────────────► 5 ──► 6 ──► 7 ──► 8
2, 3, 4 (en paralelo) ─────────────────────┘
```

Los pasos 2, 3 y 4 no dependen de Apple y pueden avanzar mientras se decide el 1.
