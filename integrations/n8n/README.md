# n8n: טלגרם → Google Calendar → Life App

זרימה שמקבלת הודעת טקסט בבוט טלגרם, מפרסרת עברית/אנגלית לאירוע יומן, יוצרת אותו ב־Google Calendar, ושומרת עותק ב־Supabase (`calendar_events`) כדי שיופיע באפליקציה.

## קבצים

| קובץ | תפקיד |
|------|--------|
| `telegram-google-calendar.json` | Workflow לייבוא ל־n8n |
| `parse-event.js` | אותו פרסר (לבדיקות / העתקה ל־Code node) |

## התקנה ב־n8n

1. **Credentials**
   - Telegram Bot API (טוקן מ־BotFather)
   - Google Calendar OAuth2 (חשבון עם גישה ליומן)
2. **Environment variables** ב־n8n:
   - `SUPABASE_ANON_KEY` או `SUPABASE_SERVICE_ROLE_KEY` (מפתח ל־Nir_DB)
3. **Import**: Workflows → Import from File → בחרו את `telegram-google-calendar.json`
4. בכל צומת Telegram / Google — בחרו את ה־credential האמיתי שלכם (ה־ID בקובץ הוא placeholder)
5. **Activate** את ה־workflow וודאו שה־Telegram Trigger נרשם (webhook / polling לפי סוג ה־n8n)

## דוגמאות הודעה

```
יום שלישי הקרוב בשעה 6 תור לרופא
15/9 בשעה 10:30 פגישה
מחר ב־18 ישיבת צוות שעתיים
20 בספטמבר בשעה 9 בבוקר בדיקה
```

## כללי פרסור

- **משך ברירת מחדל:** שעה אחת
- **שעה ברירת מחדל** (אם לא צוינה): 09:00
- שעות **1–7** בלי «בבוקר» נחשבות לערב (למשל 6 → 18:00)
- תאריך מדויק: `15/9`, `15.9.2026`, `20 בספטמבר`
- יום בשבוע: `יום שלישי` / `שלישי הקרוב`

## זרימה

```
Telegram Trigger
  → Has Text?
  → Parse Event (Code)
  → Parse OK?
      ├─ Create Google Event
      │    → Save to Life App (POST calendar_events)
      │    → Reply Success
      └─ Reply Error
```

## טבלת Supabase

`public.calendar_events` — נוצרה במיגרציה `20260829120000_calendar_events`.

האפליקציה קוראת ממנה במסך **יומן** ובפאנל האירועים במסך הבית.
