# n8n: טלגרם → Google Calendar → Life App (Hybrid AI)

זרימה שמקבלת הודעת טקסט בבוט טלגרם, מנתחת עם **Gemini**, ואז עוברת **ולידציה + ברירות מחדל** בקוד — יוצרת אירוע ב־Google Calendar ושומרת ב־Supabase (`calendar_events`).

## קבצים

| קובץ | תפקיד |
|------|--------|
| `telegram-google-calendar.json` | Workflow לייבוא / mirror של מה שב־n8n Cloud |
| `parse-event.js` | פרסר כללים (גיבוי / שימוש באפליקציה) |

## זרימה (Hybrid)

```
Telegram Trigger
  → Has Text?
  → AI Extract Event (Gemini 2.5 Flash)  ← מבין ניסוח חופשי
  → Validate & Defaults (Code)           ← אוכף כללים
  → Parse OK?
      ├─ Create Google Event
      │    → Save to Life App (calendar_events)
      │    → Reply Success
      └─ Reply Error
```

## מה ה־AI עושה
מחלץ JSON: `title`, `startsAt`, `durationMinutes`, `hourMentioned`, `rawHour`, `timeOfDayHint`…

## מה הוולידציה אוכפת
- משך ברירת מחדל: **60 דקות** אם לא צוין
- שעה ברירת מחדל: **09:00** אם לא צוינה
- שעות **1–7** בלי רמז לבוקר → ערב (+12), למשל 6 → 18:00
- אם אין תאריך בכלל → שגיאה לטלגרם (בלי ליצור אירוע)

## Instance נוכחי
- Workflow: `Telegram → Google Calendar + Life App`
- URL: https://nir0544.app.n8n.cloud/workflow/54GpwjjBXsvlMQ61
- Telegram: account 2 (לא בוט המשימות — כדי לא לשבור webhook)
- Gemini / Google Calendar / Supabase: credentials קיימים ב־n8n

## דוגמאות

```
יום שלישי הקרוב בשעה 6 תור לרופא
מחר אחרי הצהריים פגישה עם רואה חשבון שעתיים
15/9 בשעה 10:30 בדיקה
```
