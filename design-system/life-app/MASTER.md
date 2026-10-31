# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Life App  
**Stack:** Flutter (Material 3) + Riverpod + Supabase  
**Platforms:** Android + Web (RTL Hebrew)  
**Style:** Soft UI Evolution × LawPro (cream surface, navy hero)  
**Generated with:** ui-ux-pro-max-skill  
**Updated:** 2026-10-31

---

## Global Rules

### Product intent
Personal life OS: tasks, habits, calendar, money (expenses / income / vouchers).  
One calm, high-contrast light UI. Primary action is always clear. Prefer soft depth over glass/dark dashboards.

### Color Palette

| Role | Hex | Flutter token |
|------|-----|---------------|
| Primary (navy) | `#1B2A4A` | `AppColors.primary` |
| On Primary | `#FFFFFF` | white |
| Secondary / Teal | `#0F766E` | `AppColors.expenses` / calendar |
| Accent / Income | `#2563EB` | `AppColors.income` |
| Background (cream) | `#F6F3EE` | `AppColors.surface` |
| Surface alt | `#EEE9E1` | `AppColors.surfaceAlt` |
| Card | `#FFFFFF` | `AppColors.card` |
| Foreground / Ink | `#152033` | `AppColors.ink` |
| Muted | `#6B7280` | `AppColors.muted` |
| Border / Line | `#E8E2D8` | `AppColors.line` |
| Success | `#159947` | `AppColors.success` |
| Warning | `#D97706` | `AppColors.warning` |
| Destructive | `#DC2626` | `AppColors.danger` |
| Badge success bg | `#E7F6EC` | `AppColors.badgeSuccessBg` |
| Badge warning bg | `#FFF1DF` | `AppColors.badgeWarningBg` |
| Badge danger bg | `#FDE8E8` | `AppColors.badgeDangerBg` |
| Badge info bg | `#E8EEF8` | `AppColors.badgeInfoBg` |

**Notes:** Cream canvas + navy hero panels (LawPro). Trust teal for spend, blue for income. Never pure white page background; cards stay white for contrast.

### Typography
- **Font:** Heebo (Hebrew-capable Soft UI substitute for Varela/Nunito)
- **Weights:** Regular 400 · Medium 500 · SemiBold 600 · Bold 700 (cap; no 900)
- **Scale:** Title large for hero, title medium for section headers, body 14–16, captions 11–12

### Spacing
Density ~7/10 (dashboard-friendly):

| Token | Value |
|-------|-------|
| xs | 4 |
| sm | 8 |
| md | 16 |
| lg | 24 |
| xl | 32 |

### Radii
| Token | Value | Use |
|-------|-------|-----|
| sm | 12 | buttons |
| md | 16 | inputs |
| lg | 20 | cards |
| xl | 24 | dialogs |
| pill | 999 | chips / status |

### Shadows
Soft UI Evolution — clearer than neumorphism, softer than flat:
`0 6px 18px rgba(21,32,51,0.06)` on cards. No hard borders on elevated cards.

### Motion
Subtle only (dial 3/10): 150–250ms fades / short slides. Honor `prefers-reduced-motion`.

---

## Layout patterns (from LawPro + Soft UI)

1. **Home:** Greeting row → navy `HeroPanel` digest → circular quick actions → soft list cards with `StatusPill`
2. **Lists (expenses/tasks):** Soft search field → wrap filter chips → elevated cards with icon + status badge
3. **Money hub:** Navy cashflow hero → tab bar → ledger / income / vouchers
4. **Future months:** Collapsed behind expand control (never dominate the top of the ledger)

---

## Flutter rules (ui-ux-pro-max stack)

- Prefer `ColorScheme` / `AppColors` semantic tokens — no one-off hex in widgets
- Use Material 3 `ThemeData` for Card / Chip / FAB / NavigationBar
- Touch targets ≥ 44px; chips wrap (never clip overflow)
- Status = badge (non-interactive). Filters = chips (interactive)
- Icons: Material outlined set (no emoji icons)
- RTL: always wrap money/Hebrew screens in `Directionality.rtl` where needed

---

## Anti-patterns
- Glassmorphism / dark-only dashboards for this product
- Pure white scaffold background
- Purple AI gradients / neon accents
- Auto-playing motion
- Clipped single-row chip strips
- Encoding status with color alone (always add label text)

---

## Pre-delivery checklist
- [ ] Contrast ≥ 4.5:1 for body text on cream/navy
- [ ] Focus / hover states visible on web
- [ ] Chips wrap on narrow widths
- [ ] Status pills have text labels
- [ ] Soft shadows present; no harsh borders on cards
- [ ] Hebrew Heebo rendering OK on Android + Web
