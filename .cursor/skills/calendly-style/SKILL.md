---
name: calendly-style
description: "Calendly.com style reference — navy ink on cool marble. Light SaaS UI with Ink Navy (#0b3558) text, Signal Blue (#006bff) primary CTAs, cool Cloud (#f8f9fb) canvas, white elevated cards, blue-tinted shadows, Gilroy typography, and magenta/cyan decorative blobs. Activate when designing UI, pages, landing screens, components, or Flutter/web layouts in the Calendly visual language or navy-ink-on-marble aesthetic."
argument-hint: "[page|component|tokens|layout]"
license: MIT
metadata:
  author: claudekit
  version: "1.0.0"
---

# Calendly Style — Navy Ink on Cool Marble

Quiet, confident scheduling-workspace aesthetic: near-white canvas, crisp white product cards on cool stone-gray, and all typography in deep navy ink (never pure black). One vivid Signal Blue carries every primary action; decorative pink/cyan blobs warm product mockups without cluttering the UI.

**Theme:** light

## When to Activate

- Designing or restyling UI/pages in the Calendly visual language
- Building landing heroes, booking widgets, feature sections, footers
- Applying navy-ink-on-marble tokens (colors, type, radii, shadows)
- Flutter or web layouts that should match this Life app style reference
- Component specs that need Signal Blue CTAs + Ink Navy text + Cloud canvas

## Prerequisites

Load the full reference before implementing pixels:

`references/style-reference.md`

## Core Rules (Always)

1. **Ink Navy `#0b3558` for all text** — never `#000000`
2. **Signal Blue `#006bff` only for filled primary CTAs** — Ink Navy for secondary dark buttons
3. **Flat surfaces + blue-tinted shadows** — no background gradients; no `rgba(0,0,0,…)` shadows
4. **Radii:** buttons/inputs `8px`, product cards `16px`, feature panels `24px` — not pills for CTAs
5. **Display type:** Gilroy 700 at 50–80px for heroes/section H2s (substitute Manrope or Inter)
6. **Decorative blobs** (`#e55cff` / `#0099ff`) behind product visuals only — never as UI fills
7. **Canvas `#f8f9fb`**, cards `#ffffff`, hairline borders `#d4e0ed`

## Quick Color Reference

| Role | Value |
|------|-------|
| Text (primary) | `#0b3558` |
| Text (secondary) | `#476788` |
| Background (canvas) | `#f8f9fb` |
| Surface (card) | `#ffffff` |
| Border (hairline) | `#d4e0ed` |
| Primary action | `#006bff` |
| Accent (decorative) | `#e55cff` / `#0099ff` |

## Workflow

### Step 1: Confirm style intent

If the user asks for Calendly-like, navy-on-marble, scheduling SaaS, or this Life style reference — use this skill exclusively for visual decisions.

### Step 2: Load tokens & components

1. Read `references/style-reference.md` (colors, type scale, spacing, components, do/don't)
2. Prefer CSS custom properties / named tokens from the Quick Start section
3. Map tokens into Flutter `ThemeData` / web CSS as needed — keep snake→camel mapping out of the skill; keep visual values exact

### Step 3: Compose layout

- Max-width **1200px**, section gaps **48–64px**, base unit **8px**
- Hero: two-column (headline + CTAs | booking/product card + blob)
- Prefer paired text/product sections over card grids
- Sticky 64px nav: logo left, menu center, CTA cluster right

### Step 4: Verify against Do's and Don'ts

Check the Do / Don't lists in `references/style-reference.md` before shipping UI.

## References

| Topic | File |
|-------|------|
| Full style reference (tokens, components, elevation, prompts, CSS) | `references/style-reference.md` |

## Routing

1. Parse intent from `$ARGUMENTS` (`page`, `component`, `tokens`, `layout`)
2. Always load `references/style-reference.md`
3. Apply Core Rules above; expand with the matching section (Components, Layout, Quick Start, Agent Prompt Guide)
