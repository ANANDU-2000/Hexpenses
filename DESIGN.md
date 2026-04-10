# Design System Specification: The Architectural Ledger

## 1. Overview & Creative North Star
### Creative North Star: "The Intelligent Monolith"
In a landscape of cluttered fintech apps, this design system serves as a "Digital Private Office." It moves away from the chaotic "startup" aesthetic toward a feeling of institutional stability and quiet intelligence. 

The system rejects the "boxed-in" layout of traditional finance. Instead, it utilizes **Asymmetric Balance** and **Tonal Depth** to guide the eye. We prioritize editorial-grade white space and overlapping surface layers to create a sense of architectural structure that feels both secure and fluid.

## 2. Colors: Tonal Architecture
The palette is rooted in a deep, authoritative Indigo (`primary: #000b60`), supported by a sophisticated range of neutral surfaces that move beyond simple "white."

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined solely through:
1.  **Background Shifts:** Place a `surface-container-low` component on a `surface` background to define its edge.
2.  **Vertical Rhythm:** Use the spacing scale to create distinct "zones" of information.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Use the `surface-container` tiers to create "nested" depth:
*   **Base Layer:** `surface` (#f8f9fa) – The canvas.
*   **Section Layer:** `surface-container-low` (#f3f4f5) – To group related expense categories.
*   **Action Layer:** `surface-container-lowest` (#ffffff) – Used for primary cards or data entry modules to make them "pop" against the canvas.

### The "Glass & Gradient" Rule
To elevate the experience from "app" to "premium service," apply **Glassmorphism** for floating navigation bars or modals.
*   **Recipe:** Use `surface` at 80% opacity with a `24px` backdrop-blur.
*   **Signature Textures:** Apply a subtle linear gradient to main CTAs (transitioning from `primary` #000b60 to `primary_container` #142283) to provide a "sheen" that conveys quality.

## 3. Typography: Editorial Authority
The type system leverages a dual-font strategy: **Manrope** for high-impact data and headlines (conveying modern intelligence) and **Inter** for dense financial information (conveying utility and precision).

*   **Display & Headline (Manrope):** Use these for account balances and "Smart Insights." The generous x-height of Manrope makes large numbers feel approachable yet high-end.
*   **Body & Label (Inter):** Reserved for transaction lists and metadata. Inter’s neutral character ensures maximum legibility at small sizes (`body-sm: 0.75rem`).
*   **Contrast as Hierarchy:** Never use "Gray" for primary headings. Always use `on_surface` (#191c1d) to maintain a high-contrast, editorial feel.

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "heavy" for a smart fintech tool. We achieve hierarchy through **Ambient Light Physics.**

*   **The Layering Principle:** Place a `surface-container-lowest` card atop a `surface-container-high` background. The shift in hex code provides enough contrast to signify elevation without visual noise.
*   **Ambient Shadows:** For floating elements (like a "Add Expense" FAB), use a highly diffused shadow: `y: 8px, blur: 24px, color: rgba(25, 28, 29, 0.06)`. This mimics natural light.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility (e.g., in high-glare environments), use the `outline_variant` (#c6c5d4) at **15% opacity**. Never use 100% opaque lines.

## 5. Components: Precision Elements

### Buttons
*   **Primary:** Solid `primary` fill, white text, `md` (12px) rounded corners.
*   **Secondary:** `secondary_container` (#cfe6f2) fill with `on_secondary_container` text.
*   **State:** On hover, apply a `surface_tint` overlay at 8% opacity.

### Input Fields
*   **The "Quiet" Input:** No bottom line or full box. Use a `surface-container-highest` background with a `sm` (4px) corner radius.
*   **Focus State:** Transition the background to `surface_bright` and add a 2px `primary` ghost-border at 20% opacity.

### Lists & Expense Cards
*   **Anti-Divider Pattern:** Strictly forbid 1px dividers between transactions.
*   **The "Staggered" List:** Use a `12px` vertical gap between transaction items. Each item sits on its own `surface-container-low` background. This makes each expense feel like a distinct "event" rather than a line in a spreadsheet.

### Sleek Charts (Data Viz)
*   **Stroke:** Use `primary` for the main trend line. 
*   **Fill:** Use a gradient fade from `surface_tint` (20% opacity) to transparent to ground the data.
*   **Points:** Only show data points on interaction (hover/tap) to keep the "Clean" brand personality.

## 6. Do's and Don'ts

### Do:
*   **Do** use `headline-lg` (Manrope) for total balance amounts to establish "Big Number" authority.
*   **Do** use `md` (12px) rounding for primary containers, but `sm` (4px) for smaller elements like input fields to maintain a "structured" feel.
*   **Do** ensure Dark Mode uses `inverse_surface` (#2e3132) as the base to prevent pure-black eye strain.

### Don't:
*   **Don't** use "Alert Red" for everything negative. Use `error` (#ba1a1a) sparingly; for "money out," use `on_tertiary_container` (muted burnt orange) to keep the tone professional, not panicked.
*   **Don't** use standard icons. Use "Descriptive Icons" with a consistent 2px stroke weight to match the `outline` token.
*   **Don't** crowd the screen. If a view feels full, increase the `surface` spacing rather than adding borders.