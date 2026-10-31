---
description: Use UI UX Pro Max + Life App design system for all UI work
globs:
  - lib/**/*.dart
  - design-system/**/*
alwaysApply: false
---

# UI / UX guidance for Life App

When designing, restyling, or reviewing UI:

1. Read `design-system/life-app/MASTER.md` first.
2. If a page override exists under `design-system/life-app/pages/`, it wins.
3. For new recommendations, run:
   `python3 .cursor/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system -p "Life App"`
   or domain/stack searches from `.cursor/skills/ui-ux-pro-max/SKILL.md`.
4. Prefer Soft UI Evolution × LawPro (cream surface, navy hero). Do not switch to dark glass dashboards unless the user asks.
5. Flutter: map colors through `AppColors` / `ThemeData` in `lib/core/theme/app_theme.dart`. Keep Heebo for Hebrew.
6. User explicit visual direction always overrides skill defaults.
