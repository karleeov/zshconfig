# Design workflow

## Establish the visual contract

Identify the audience, task, brand constraints, target devices, accessibility requirements, and existing design system. For UI work, capture `PRODUCT.md` and `DESIGN.md` when the project uses Impeccable. Reuse existing tokens and components before inventing a new visual language.

## Execute

1. Map the user journey and content hierarchy before styling.
2. Build the smallest representative surface: one flow, component, page, or diagram.
3. Define typography, spacing, color, states, and motion as reusable decisions.
4. Include loading, empty, error, focus, disabled, long-content, and reduced-motion states.
5. Verify keyboard operation, contrast, semantics, responsive behavior, and actual runtime output.
6. Inspect screenshots at representative mobile, tablet, and desktop sizes. Fix overflow and interaction defects before polish.
7. Run Impeccable `critique`, `audit`, or `detect` when installed; review findings rather than applying every suggestion blindly.

## Knife selection

| Need | Default |
|---|---|
| Product/UI iteration | Impeccable; keep Taste Skill and Hallmark as alternatives, not defaults |
| Design handoff | The team's existing Figma/Penpot flow and design tokens |
| Whiteboarding | tldraw or Drawnix |
| Architecture diagrams | `archify`, `diagram-design`, or `anatomy`; validate against source |
| Icons | Lucide with consistent size and stroke |
| React UI | Existing project system; HeroUI only when it fits the project |
| Motion/3D | Anime.js, Three.js, or shaders only when they serve the content |
| Image/vector/media | ImageMagick, rsvg-convert, FFmpeg; OpenCut/video-use for larger projects |

Do not enable design hooks, live browser agents, or external catalog requests without reviewing their behavior. Keep generated visual artifacts editable when the user needs continued design work.

## Definition of done

The result works at real breakpoints, has no dead controls, preserves accessibility, matches the agreed visual direction, and includes rendered evidence—not only source code or a textual claim.
