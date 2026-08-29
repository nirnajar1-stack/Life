# n8n: טלגרם → Google Calendar → Life App (Hybrid + Voice)

זרימה שמקבלת **טקסט או הודעה קולית** בטלגרם, מתמללת (OpenAI), מנתחת עם **Gemini**, אוכפת ברירות מחדל, יוצרת אירוע ב־Google Calendar ושומרת ב־Supabase.

## זרימה

```
Telegram Trigger
  → Input Type (Switch)
      ├─ voice  → Get Voice File → Transcribe (OpenAI) → Wrap
      ├─ audio  → Get Audio File → Transcribe (OpenAI) → Wrap
      ├─ text   → Normalize Text
      └─ other  → Reply Need Input
  → Normalize Input → Has Content?
  → AI Extract Event (Gemini)
  → Validate & Defaults
  → Create Google Event → Save to Life App → Reply Success
```

## Instance
https://nir0544.app.n8n.cloud/workflow/54GpwjjBXsvlMQ61

## מה לשלוח לבוט
- טקסט: `יום שלישי בשעה 6 תור לרופא`
- **הקלטה קולית** עם אותו תוכן

## ברירות מחדל (אחרי AI)
- משך: שעה
- בלי שעה: 09:00
- שעות 1–7 בלי רמז לבוקר → ערב (6→18:00)
