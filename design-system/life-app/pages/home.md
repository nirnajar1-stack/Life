# Page Override: Home

Overrides `MASTER.md` for the Home dashboard only.

## Structure
1. Greeting + avatar circle
2. Navy `HeroPanel` — today’s focus + micro stats
3. Soft card with 4 circular quick actions (task / event / habit / expense)
4. Notifications card
5. Upcoming calendar panel
6. Two-column (desktop) / stacked (mobile): focus tasks + money snapshot; habits below tasks

## Rules
- Hero title is short urgency copy; full digest stays in subtitle
- Task rows use trailing `StatusPill` (overdue / today / date) — never color alone
- Quick actions stay icon circles with 12px labels; equal spacing
- Prefer SoftCard / HeroPanel primitives from `app_theme.dart`
