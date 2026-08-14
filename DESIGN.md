# Design System Document: La Mohana

## 1. Overview & Creative North Star
**Creative North Star: "The Resonant Curator"**

This design system moves away from the rigid, clinical grids of traditional broadcasting and toward a sophisticated, editorial experience. It celebrates the "Premium Community Voice"—a space that feels as authoritative as a high-end magazine yet as intimate as a local radio transmission. 

To achieve this, the system breaks the "template" look through **intentional asymmetry**. We utilize large, high-contrast typography scales and overlapping elements to create a sense of motion and rhythm. The interface should feel like it is "breathing," using expansive white space and tonal layering to guide the user’s eye without the need for restrictive structural lines.

---

## 2. Colors
Our palette is rooted in deep, cultural purples and soft, ethereal lilacs. It is designed to feel immersive and "vocal."

*   **Primary (#6100A4 / #7B2CBF):** The heartbeat of the system. Use these for high-action areas and key brand moments.
*   **Neutral Surfaces:** A sophisticated range from `surface-container-lowest` (#FFFFFF) to `surface-dim` (#DAD9E1), providing a canvas that feels like premium matte paper.

### The "No-Line" Rule
**Explicit Instruction:** Prohibit the use of 1px solid borders for sectioning. Structural boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` section sitting on a `background` (#FAF8FF) provides enough contrast to signify a new content block without the visual clutter of a line.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine paper. 
*   **Background (#FAF8FF):** The base foundation.
*   **Surface-Container-Low (#F4F3FB):** Large content areas or section backgrounds.
*   **Surface-Container-Lowest (#FFFFFF):** Elevated cards or "active" interactive zones.
By nesting these tiers, you create depth that feels organic rather than artificial.

### The "Glass & Gradient" Rule
To move beyond a standard flat look, use **Glassmorphism** for floating elements (e.g., Audio Players or Navigation Bars). Apply a semi-transparent surface color with a `backdrop-blur` of 16px-24px. 

### Signature Textures
Use subtle linear gradients—transitioning from `primary` (#6100A4) to `primary-container` (#7B2CBF)—for Hero backgrounds and main CTAs. This provides a "soul" and visual depth that flat color cannot replicate.

---

## 3. Typography
The typography is a dialogue between the bold, editorial strength of **Epilogue** and the clean, modern functionalism of **Manrope**.

*   **Display & Headlines (Epilogue):** Modern, bold, and unapologetic. The large scale (`display-lg` at 3.5rem) is used to create focal points that feel like magazine spreads. Use `headline-md` (1.75rem) for community stories to give them weight and importance.
*   **Body & Titles (Manrope):** Chosen for its high legibility and friendly, open terminals. `body-lg` (1rem) is the workhorse for storytelling, while `label-md` (0.75rem) handles the technical metadata of radio broadcasting (frequencies, timestamps).

**Hierarchy Identity:** By pairing a massive Epilogue headline with a generous 1.6 line-height Manrope body, the interface strikes a balance between professional journalism and community warmth.

---

## 4. Elevation & Depth
We eschew traditional shadows in favor of **Tonal Layering**.

*   **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift. This "paper-on-paper" effect is the hallmark of premium digital design.
*   **Ambient Shadows:** When a float is required (e.g., a "Live Now" FAB), use extra-diffused shadows. 
    *   *Spec:* `Y: 8px, Blur: 24px, Spread: -4px`. 
    *   *Color:* Use a 6% opacity version of `on-surface` (#1A1B21). Never use pure black or dark grey.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke, use `outline-variant` (#CFC2D5) at **20% opacity**. It should be felt, not seen.
*   **Glassmorphism:** Use semi-transparent lilac tints for cards containing imagery to allow colors to bleed through, integrating the content into the environment.

---

## 5. Components

### Buttons
*   **Primary:** High-gloss. Use the signature gradient (Primary to Primary-Container). `ROUND_EIGHT` (0.5rem) corners.
*   **Secondary:** `surface-container-high` background with `on-surface` text. No border.
*   **Tertiary:** Ghost style. `primary` text, no background, 0.5rem padding for a large hit state.

### Cards & Lists
*   **Rule:** Forbid divider lines. Separate list items using 12px-16px of vertical white space or a subtle shift to `surface-container-low` on hover.
*   **Editorial Cards:** Feature images should use the `lg` (1rem) corner radius, while the container uses the `DEFAULT` (0.5rem) to create a "contained-fluidity" look.

### Input Fields
*   **Style:** Minimalist. Use a `surface-container-highest` fill. The active state should not use a border, but a 2px `primary` bottom-bar or a subtle glow effect.

### Audio Player (Specialized Component)
*   **Visuals:** A "frosted glass" bar anchored to the bottom. Use `Manrope Bold` for the track title and `Epilogue` for the frequency (e.g., 91.2 FM).
*   **Interaction:** Play/Pause buttons use the `primary` container with a soft ambient shadow.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use asymmetrical margins. For example, a headline may be indented 10% more than the body text to create an editorial "rag."
*   **Do** prioritize high-quality photography of the community. Use the lilac surface tints as overlays on images to maintain brand harmony.
*   **Do** allow elements to overlap. A title card can "float" 20px over a header image to create depth.

### Don't:
*   **Don't** use 1px solid black or grey borders. They break the "Resonant" flow.
*   **Don't** use standard Material Design drop shadows. They feel "default" and "cheap."
*   **Don't** cram the screen. If a section feels busy, double the padding. This is a premium experience; let the content breathe.
*   **Don't** use pure #000000 for text. Use `on-surface` (#1A1B21) for a softer, more natural reading experience.