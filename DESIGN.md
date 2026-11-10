# Design System Document: La Mohana

> **Source of truth:** `app/lib/config/design_tokens.dart` (colors, gradients, spacing, radii, shadows, decorations) and `app/lib/config/theme.dart` (`ThemeData`, typography, component themes). This document describes what those files implement. If a value here and a value there ever disagree, the code wins — update this file.
>
> `theme.dart` re-exports `design_tokens.dart`, so a single `import 'config/theme.dart';` gives access to both.

## 1. Overview & Creative North Star

**Creative North Star: "The Resonant Curator"**

An editorial experience rather than a broadcast grid: as authoritative as a magazine, as intimate as a local radio transmission. The system leans on a monochrome purple identity, generous white space, and tonal layering — depth comes from stacked surfaces and lilac-tinted shadows, not from heavy Material elevation.

Two visual registers coexist by design:

- **Light and airy** for browsing — feed, podcast library, live radio player. Tonal lilac backgrounds, white cards.
- **Deep and immersive** for the episode player — a dark purple gradient, so you can tell at a glance you are listening on demand and not to the live stream.

---

## 2. Colors

All values live in `MohanaColors`.

### Brand

| Token | Hex | Use |
| --- | --- | --- |
| `primary` (= `primary500`) | `#7B2E88` | CTAs, active states, links, accents, "EN VIVO" badge |
| `secondary` (= `secondary300`) | `#E18F53` | Warm accent — visualizer, avatar ring |
| `tertiary` (= `primary700`) | `#5C1F6A` | Emphasis, dark headers, tonal card shadow |
| `neutral` | `#F5F5F7` | Light background tint |

### Primary purple scale

`primary50 #F5EAF6` · `100 #E8D0EB` · `200 #D4A3D6` · `300 #C07DC0` · `400 #9D47A4` · `500 #7B2E88` · `600 #6A2575` · `700 #5C1F6A` · `800 #4A155C` · `900 #380B48`

### Secondary orange scale

`secondary50 #FDF3EB` · `100 #F8DCC7` · `200 #F2C5A3` · `300 #E18F53` · `400 #D47A3D` · `500 #C76828`

### Surfaces (light)

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F8F8FA` | Base canvas / scaffold |
| `surface`, `surfaceContainerLowest` | `#FFFFFF` | Cards, elevated / active zones |
| `surfaceContainerLow` | `#F3F3F7` | Section backgrounds, input fills |
| `surfaceContainer` | `#EDEDF2` | — |
| `surfaceContainerHigh` | `#E2E1E8` | Secondary buttons, shimmer |
| `surfaceDim` | `#D4D3DC` | Disabled fills |

### Tonal feed background

A monochrome wash from the primary scale that gives the home and library their identity. White cards sit on top for contrast.

`tonalTop #D4A3D6` → `tonalMid #E7D4EF` → `tonalBottom #F6EDF9` (see `MohanaGradients.homeTonal`; the `0.45` mid-stop concentrates saturation in the top third, and the pale foot sits under the player bar).

### On-colors

`onPrimary #FFFFFF` · `onSecondary #5C1F6A` · `onTertiary #FFFFFF` · `onSurface #1A1B21` · `onSurfaceVariant #49454F` · `onBackground #1A1B21`

Never use pure `#000000` for text — `onSurface` (`#1A1B21`) reads softer.

### Outline, semantic, status

`outline #79747E` · `outlineVariant #CDCDD5` · `inputBorder #E2E1E8`
`error #D32F2F` · `success #388E3C` · `warning #F57C00` · `info #1976D2`
`liveIndicator #E91E63` (pulsing dot — as a mark of color only) · `liveIndicatorStrong #C2185B` (the same pink one step darker, for when the live pill carries white text: `liveIndicator` under white is 3.97:1 and misses AA; this one is 5.4:1) · `enVivoBadge #7B2E88` (badge fill)
`shimmer #E2E1E8` · `divider #EDEDF2` · `scrim #521A1B21` (`onSurface` at 32%)

### Category tags

`MohanaCategoryColors.forCategory(name)` maps a category string to its chip fill, falling back to `primary` for anything unlisted. Matching is case- and accent-tolerant ("música"/"musica", "educación"/"educacion").

Impacto social `#00897B` · Cultura `#2E7D32` · Salud `#00838F` · Medio ambiente `#558B2F` · Música `#7B2E88` · Comunidad `#AD1457` · Educación `#1565C0` · Infraestructura `#6D4C41` · Podcast nuevo `#E91E63`

### Dark mode

`MohanaTheme.dark` swaps only the neutrals — the brand purple stays `#7B2E88`.

| Role | Light | Dark |
| --- | --- | --- |
| Background | `#F8F8FA` | `#121215` |
| Surface | `#FFFFFF` | `#1E1D22` |
| Surface container low | `#F3F3F7` | `#2A292F` |
| On-surface | `#1A1B21` | `#E8E7EC` |
| On-surface variant | `#49454F` | `#B0AFB8` |
| Divider / outline variant | `#EDEDF2` / `#CDCDD5` | `#3A393F` |

`ThemeController.mode` (a `ValueNotifier<ThemeMode>`) drives the switch; `ThemeController.toggle()` flips it. Default is light.

**Caveat:** most tokens outside the `ColorScheme` are light-mode constants, and many widgets reference `MohanaColors.*` directly. New surfaces should read theme-derived colors (`Theme.of(context).colorScheme`) rather than hardcoding light tokens, or they will not follow the dark theme.

---

## 3. Gradients

All in `MohanaGradients`.

| Token | Stops | Where |
| --- | --- | --- |
| `primaryButton` | `#A855B8` → `#7B2E88`, left → right | Gradient CTAs |
| `brand` | `primary` → `tertiary`, top-left → bottom-right | Headers, hero areas |
| `homeTonal` | `tonalTop` → `tonalMid` (0.45) → `tonalBottom`, top → bottom | Home and library backgrounds |
| `player` | `#6A2575` → `#4A155C` (0.55) → `#2E0B3A`, top → bottom | Episode player — deliberately dark |
| `radioPlayer` | `#F8F8FA` → `#F0E6F2` → `#F5EAF6`, top → bottom | Live radio screen — deliberately light |
| `miniPlayer` | `#F5EAF6` → `#EDEDF2`, left → right | Mini player bar |
| `visualizer` | `#7B2E88` → `#E18F53` → `#D47A3D`, bottom → top | Audio visualizer bars |
| `avatarRing` | Sweep: purple → orange → deep purple → orange → purple | Profile avatar ring |
| `backgroundSubtle` | `#F8F8FA` → `#F0E6F2` → `#F8F8FA`, top → bottom | Login / onboarding wash |

Use gradients for hero areas and primary CTAs; flat `primary` is correct everywhere else.

---

## 4. Typography

Three families, loaded through `google_fonts` (no bundled font files):

- **Bree Serif** — display and headline. A slab serif carries the editorial voice, plus the AppBar title (20 / w700 / `primary`).
- **Montserrat** — titles. Semibold, structural.
- **Poppins** — body, labels, and every button and chip.

| Style | Family | Size | Weight | Line height |
| --- | --- | --- | --- | --- |
| `displayLarge` | Bree Serif | 56 | 400 | 1.1 |
| `displayMedium` | Bree Serif | 45 | 400 | 1.15 |
| `displaySmall` | Bree Serif | 36 | 400 | 1.2 |
| `headlineLarge` | Bree Serif | 32 | 400 | 1.2 |
| `headlineMedium` | Bree Serif | 28 | 400 | 1.25 |
| `headlineSmall` | Bree Serif | 24 | 400 | 1.3 |
| `titleLarge` | Montserrat | 22 | 600 | — |
| `titleMedium` | Montserrat | 16 | 600 | — |
| `titleSmall` | Montserrat | 14 | 600 | — |
| `bodyLarge` | Poppins | 16 | 400 | 1.6 |
| `bodyMedium` | Poppins | 14 | 400 | 1.6 |
| `bodySmall` | Poppins | 12 | 400 | 1.5 (`onSurfaceVariant`) |
| `labelLarge` | Poppins | 14 | 600 | — |
| `labelMedium` | Poppins | 12 | 500 | — (`onSurfaceVariant`) |
| `labelSmall` | Poppins | 11 | 500 | — (`onSurfaceVariant`, +0.5 tracking) |

Uppercase micro-labels (category tags, "EN VIVO", eyebrows) run Poppins 10–11 / w700 with 0.5–0.8 tracking.

A Bree Serif headline over 1.6 line-height Poppins body is the hierarchy signature: journalism above, community warmth below.

---

## 5. Spacing & Radius

**`MohanaSpacing`** — 4px base unit:

`xxs 2` · `xs 4` · `sm 8` · `md 12` · `base 16` · `lg 20` · `xl 24` · `xxl 32` · `xxxl 40` · `huge 48` · `massive 64`

Semantic aliases: `screenH 20` (horizontal screen padding), `cardPadding 16`, `sectionGap 32`.

**`MohanaRadius`** — `xs 4` · `sm 8` · `md 12` · `lg 16` · `xl 20` · `xxl 24` · `pill 100`, each with a ready-made `BorderRadius` (`smAll`, `mdAll`, `lgAll`, `xlAll`, `xxlAll`, `pillAll`).

Conventions in use: `sm` for tags and badges, `md` for inputs, `lg` for cards and cover images, `xl` for dialogs and glass panels, `xxl` for bottom sheets, `pill` for every button.

---

## 6. Elevation & Depth

Depth comes from **tonal layering** and diffuse tinted shadows, never from stock Material elevation — every component theme sets `elevation: 0`.

`MohanaShadows`:

| Token | Color | Offset | Blur | Spread |
| --- | --- | --- | --- | --- |
| `ambient` | `onSurface` 6% | 0, 8 | 24 | −4 |
| `card` | `onSurface` 4% | 0, 2 | 12 | 0 |
| `tonalCard` | `tertiary` 16% | 0, 6 | 18 | 0 |
| `elevated` | `onSurface` 10% | 0, 4 | 16 | −2 |
| `bottomNav` | `onSurface` 4% | 0, −4 | 16 | 0 |
| `miniPlayer` | `primary` 15% | 0, 4 | 20 | −2 |

Two rules that matter:

- **Tinted, never grey.** Shadows are tinted with `onSurface`, `tertiary`, or `primary` at low alpha. Pure black is never used.
- **Match the shadow to the ground.** A white card on the plain `background` uses `card`; the same card on the lilac `homeTonal` wash uses `tonalCard`, whose purple tint keeps it from looking dirty.

**Glassmorphism** is real, not decorative: the mini player wraps a `BackdropFilter` (`sigma 20`) around a `surfaceContainerLowest` fill at 92% opacity, clipped to a 16px top radius. `MohanaDecorations.glass` is the static approximation (`surfaceContainerLowest` at 85% + `ambient`, `xl` radius) for panels that do not warrant a blur pass — blurring is expensive, so reserve `BackdropFilter` for floating chrome.

---

## 7. Components

Ready-made `BoxDecoration`s live in `MohanaDecorations`; component defaults live in `MohanaTheme`. Prefer both over ad-hoc styling.

### Buttons

| Kind | Implementation | Spec |
| --- | --- | --- |
| Gradient CTA | `MohanaTheme.gradientButton(...)` / `MohanaDecorations.primaryButton` | `primaryButton` gradient, pill, `primary` @30% shadow (0,4 / 12). Poppins 16 w700. Disabled → flat `surfaceDim` |
| Solid primary | `ElevatedButton` (themed) | `primary` fill, `onPrimary` text, elevation 0, pill, padding 32×16, Poppins 16 w700 |
| Outlined | `OutlinedButton` (themed) | Transparent, 1.5px `primary` border, pill, padding 24×12, Poppins 14 w600 |
| Text / link | `TextButton` (themed) | `primary`, zero padding, Poppins 14 w700 — for "LEER MÁS →" style links |
| Social | `MohanaDecorations.socialButton` | White fill, 1px `outlineVariant`, `md` radius |

### Cards & lists

`MohanaDecorations.card` (white, `lg` radius, `card` shadow) and `tonalCard` (same, lilac shadow, for the tinted feed). `CardTheme` is elevation 0, `lg` radius, zero margin.

Separate list items with 12–16px of vertical space, not divider lines. `MohanaDecorations.dividerLine` and the 1px `DividerTheme` exist for the few places a real rule is needed — section ends, the bottom-nav top edge — but they are the exception, not the sectioning tool.

Cover images use `lg` radius. `MohanaCover` (`lib/widgets/mohana_cover.dart`) is the only place that decides what shows when an image is missing: the station logo over brand lilac, never an empty box. Route every new cover through it.

### Category tags & live badge

`MohanaTheme.categoryTag(name)` — uppercase Poppins 10 / w700 / 0.8 tracking on the category fill, `sm` radius, padding 8×4.
`MohanaTheme.liveBadge()` — a 6px white dot plus "EN VIVO" in Poppins w700 on `enVivoBadge`, `sm` radius.

`ChipTheme` mirrors this: `primary` fill, Poppins 11 / w700 / 0.5 tracking, `sm` radius, no border.

### Input fields

Filled `surfaceContainerLow` (`#2A292F` in dark), `md` radius, 1px `inputBorder`; focus swaps to a 1.5px `primary` border, error to `error`. Padding 16×12. Label Poppins 12 / w600 / 1.2 tracking, hint Poppins 14 / w400, both `onSurfaceVariant`.

`MohanaDecorations.inputField` is the equivalent for hand-built containers; `uploadArea` is the image-picker variant (`surfaceContainerLow`, `lg` radius, 1.5px `outlineVariant`).

### On air

`OnAirCard` opens the home feed: the brand gradient on `lg` radius with the `liveIndicatorStrong` pill, a 4-bar `AudioVisualizer` that only moves while the stream actually plays, and an inverted 52px play button (white fill, `primary` glyph) — the highest contrast available on that surface, because it is the screen's primary action. It reads as the station, not as another content card. When `ScheduleService` has a schedule it names the current program; otherwise it falls back to station identity.

### Chrome

- **AppBar** — `background` fill, transparent surface tint, elevation 0, left-aligned, Bree Serif 20 / w700 / `primary`.
- **Bottom nav** — `surfaceContainerLowest` with a hairline `outlineVariant` @40% top border; `MohanaDecorations.bottomNav` offers a shadow variant. Icons only, no labels: the active tab is marked by a `primary100` pill behind the icon (a surface shift, not a rule) and the label survives as the semantics and long-press tooltip text. A brand-gradient circle sits at the centre — it is not a tab, it switches what is playing and opens the live player, and it carries a `liveIndicator` dot while the stream is on air.
- **Mini player** — sits above the bottom nav, glass-blurred (see §6); `MohanaDecorations.miniPlayer` is the flat gradient variant with the purple glow.
- **Bottom sheets** — `xxl` top radius. **Dialogs** — `xl` radius.
- **Avatar ring** — `MohanaDecorations.avatarRing`, the sweep gradient as a circular border.

---

## 8. Do's and Don'ts

### Do

- Reach for a token. `MohanaSpacing`, `MohanaRadius`, `MohanaColors`, `MohanaShadows` — a literal `16` or `Color(0xFF7B2E88)` in a widget is a bug waiting to drift.
- Prefer a `MohanaDecorations` entry over a hand-rolled `BoxDecoration`.
- Let content breathe. If a section feels busy, double the padding before adding structure.
- Use high-quality community photography, with lilac surface tints as overlays to keep brand harmony.
- Allow overlap — a title card floating over a header image reads as depth.
- Keep the two player registers distinct: light for live, dark for on-demand.

### Don't

- Don't use 1px grey rules to section content — shift the background instead. Hairlines are reserved for chrome edges.
- Don't use stock Material drop shadows or `elevation > 0`. Use `MohanaShadows`.
- Don't use pure `#000000` for text — use `onSurface` (`#1A1B21`).
- Don't hardcode light-mode colors in new widgets if the surface should follow the theme.
- Don't apply `BackdropFilter` broadly; it is per-frame expensive. Floating chrome only.
- Don't follow the vendored `frontend-design` skill's brand constants (Inter, `#2563eb`, `docs/design.md`). It is a third-party template and does not apply to this project.
