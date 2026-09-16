---
name: base-design-references
description: Curated design references and component ecosystems for high-end web applications. Includes direct guidance and verified links for ThreeUI, Spline 3D, React Bits components, shadcn/ui, and modern styling libraries.
license: MIT
---

# Design References & Component Ecosystems

Use this skill when designing landing pages, 3D interactive hero sections, dashboards, or animated UI workflows.

---

## 1. 3D & Interactive Experiences

### [ThreeUI](https://threeui.com/browse)
- **Primary Use**: 3D hero sections, interactive shaders, WebGL backgrounds, particle canvas components, and physics-based landing page visuals.
- **Implementation Rules**:
  - Browse [ThreeUI](https://threeui.com/browse) for verified Three.js / React Three Fiber (R3F) shader setups and canvas templates.
  - Always enforce a performance budget: limit draw calls, clamp pixel ratios on mobile (`Math.min(window.devicePixelRatio, 2)`), and dispose geometries/materials on unmount.
  - Provide a clean static fallback (e.g. SVG or CSS gradient image) while the 3D scene compiles or if WebGL is disabled/unsupported.
  - Automatically pause animation loops when off-screen using `IntersectionObserver`.

### [Spline](https://spline.design/)
- **Primary Use**: Collaborative 3D design, interactive 3D web scenes, real-time mouse tracking objects, character interactions, and interactive product showcases.
- **Implementation Rules**:
  - Use [`@splinetool/react-spline`](https://spline.design/) or `@splinetool/runtime` for lightweight embed.
  - Keep 3D assets optimized (compress meshes, export Draco-compressed glTF/Spline binaries).
  - Treat Spline scenes as progressive enhancement: essential navigation and calls to action must never depend on the 3D canvas loading.

---

## 2. Animated & Interactive React Components

### [React Bits](https://www.reactbits.dev/get-started/mcp)
- **Primary Use**: 135+ interactive, customizable, and animated React components built with Tailwind CSS and Framer Motion (text animations, interactive cards, cursor effects, background grids).
- **MCP Integration**:
  - Connect through the React Bits MCP server: see [`mcp/README.md#react-bits`](../../mcp/README.md).
  - Query components directly from your coding agent to inspect component source code and installation commands.
  - Seamlessly integrates into shadcn/ui-based React and Next.js repositories.

---

## 3. Production Design Systems & Base Components

### [shadcn/ui](https://ui.shadcn.com/)
- Accessible, unstyled Radix UI primitives styled with Tailwind CSS. The standard base for production SaaS dashboards, dialogs, forms, and navigation.

### [21st.dev](https://21st.dev/)
- The npm for design engineers. High-craft, community-crafted Tailwind + Framer Motion components with copy-paste integration.

### [Motion (Framer Motion)](https://motion.dev/)
- Production-ready declarative animations, gestures, layout transitions, and scroll animations for React and vanilla JS.

---

## Architecture Guidelines for the Frontend Designer

1. **Stack Detection**: Inspect `package.json` before proposing any library. If the project uses Tailwind, prefer React Bits and shadcn. If vanilla CSS, adapt the concepts rather than forcing extra runtime bloat.
2. **Reduced Motion**: Any animation from ThreeUI, Spline, or Framer Motion **must** respect:
   ```css
   @media (prefers-reduced-motion: reduce) {
     *, ::before, ::after {
       animation-duration: 0.01ms !important;
       animation-iteration-count: 1 !important;
       transition-duration: 0.01ms !important;
       scroll-behavior: auto !important;
     }
   }
   ```
3. **Taste Dials**: Cross-reference [`design-taste-frontend`](../design-taste-frontend/SKILL.md) and [`ui-ux-pro-max`](../ui-ux-pro-max/SKILL.md) to set intentional `DESIGN_VARIANCE`, `MOTION_INTENSITY`, and `VISUAL_DENSITY` values.
