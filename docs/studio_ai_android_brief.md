# Life App — Brief לבניית אפליקציית Android (Studio AI)

העתק את כל המסמך הזה והדבק ב־Studio AI.

---

## 1) מטרת האפליקציה

אפליקציה אישית לניהול חיי היומיום במקום אחד — בעיקר **משימות** ו**הוצאות/תקציב**.
המטרה: לראות במהירות מה צריך לעשות, כמה הוצאתי, לאן הכסף הולך, ולהזין נתונים בקלות מהטלפון.

- קהל יעד: משתמש יחיד (שימוש אישי)
- שפה: עברית, ממשק RTL
- פלטפורמה: אפליקציית Android נייטיבית
- Backend קיים: Supabase (Postgres) — לא לבנות DB מאפס, רק להתחבר לטבלאות הקיימות
- Auth: לא בשלב זה

---

## 2) מסכים ופונקציונליות

### מסך בית
דשבורד עם 2 מודולים:
1. משימות — ניהול המשימות שלי
2. הוצאות — מעקב תקציב וקניות

### מודול משימות
מה לבנות:
- רשימת משימות פעילות (`is_completed = false`)
- סינון קטגוריה: הכל / כללי / פיננסי / בריאותי / אישי
- יצירת משימה
- עריכת משימה
- סימון כהושלמה
- מחיקה עם אישור
- Pull to refresh
- הצגת עדיפות ותאריך יעד

שדות משימה:
- title (חובה)
- description (אופציונלי)
- category: כללי / פיננסי / בריאותי / אישי
- priority: 1=גבוהה, 2=בינונית, 3=נמוכה
- due_date (אופציונלי)
- is_completed
- created_at (אוטומטי)

### מודול הוצאות
שני טאבים:

#### א) יומן הוצאות
- רשימה מקובצת לפי חודש (החדש למעלה)
- קיבוץ לפי `message_id` (קבלה)
- הוספה / עריכה / מחיקה
- סימון הוצאה משותפת ברמת קבלה (`Shared_exp`)
- תווית תשלומים: "תשלום X/Y"

#### ב) דשבורד תובנות
סינון תקופה:
- החודש
- 3 חודשים
- מתחילת השנה
- הכל

תובנות:
- KPIs
- השוואה לחודש קודם (MoM)
- גרף חודשי
- פירוק לפי קטגוריות־אב
- פירוק לפי מקורות
- פיצול: משתנה / קבועה / תשלומים
- טרנזקציות ופריטים מובילים

קטגוריות־אב:
דיור, מזון, תחבורה, בריאות, פנאי, טכנולוגיה וציוד, מתנות ותרומות, אישי ואחר

סוגי הוצאה:
- משתנה: `is_fixed = 0`
- קבועה: `is_fixed = 1`
- תשלומים: לפי `installment_group_id` (ו־`is_fixed` תמיד 0)

---

## 3) UX ל־Android

- עברית RTL
- עיצוב נקי, מודרני, ניגודיות גבוהה
- מצבי טעינה ושגיאה
- ניווט: בית → מודול → רשימה/דשבורד/טופס
- כפתורים ברורים: הוספה, עריכה, מחיקה, סימון הושלמה
- מותאם למסכי טלפון

ארכיטקטורה:
- Feature-first: tasks, expenses
- UI → Domain/ViewModel → Repository → Supabase
- UI לא מדבר ישירות עם DB

---

## 4) חיבור Supabase

- Project: Nir_DB
- URL: `https://grxumlgwgzmnnpxlgzah.supabase.co`
- Anon key:
`eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyeHVtbGd3Z3ptbm5weGxnemFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MzA0MDYsImV4cCI6MjA5NDAwNjQwNn0.NQDZSO176anvgI6eyQZe0udmzpR_g7qtHwsdCWAuy5M`

חשוב:
- להשתמש רק ב־anon key באפליקציה
- לא להשתמש ב־service_role
- לא לבנות Auth בשלב זה

כללי שמות:
- עמודות DB ב־snake_case
- חריג קריטי: העמודה `Shared_exp` חייבת להיכתב בדיוק כך (S גדולה)
- `amount` עלול להגיע כ־string → לפרסר ל־Double בבטחה
- `purchase_date` לשלוח כ־`YYYY-MM-DD`

---

## 5) טבלה: `tasks`

עמודות:
- id uuid PK (default gen_random_uuid) — לא לשלוח ב־insert
- title text NOT NULL
- description text NULL
- is_completed boolean NOT NULL default false
- priority int NOT NULL default 2
- due_date timestamptz NULL
- created_at timestamptz NOT NULL default now — לא לשלוח ב־insert
- category text NOT NULL default 'כללי'
- status text NULL (לא בשימוש ב־UI)
- urgency_level text NULL (לא בשימוש ב־UI)
- is_time_sensitive boolean NULL (לא בשימוש ב־UI)

### פעולות Tasks

Fetch active:
```
GET /rest/v1/tasks?is_completed=eq.false&order=priority.asc,due_date.asc.nullslast
```
אופציונלי: `&category=eq.פיננסי`

Create body:
```json
{
  "title": "string",
  "description": "string|null",
  "is_completed": false,
  "priority": 2,
  "category": "כללי",
  "due_date": "2026-08-10T00:00:00.000Z"
}
```

Update:
```
PATCH /rest/v1/tasks?id=eq.{uuid}
```

Toggle complete:
```json
{"is_completed": true}
```

Delete:
```
DELETE /rest/v1/tasks?id=eq.{uuid}
```

---

## 6) טבלה: `expenses_new`

חשוב: להשתמש ב־`expenses_new` בלבד. לא ב־`expenses`.

עמודות:
- id bigint PK — לא לשלוח ב־insert
- created_at timestamptz NOT NULL — תאריך ההוצאה/חיוב
- item_name text NOT NULL
- amount numeric NOT NULL
- category text NOT NULL
- sub_category text NOT NULL
- is_fixed smallint NULL default 0 — רק 0 או 1
- source text NULL — באפליקציה לשים "life_app"
- uuid uuid NOT NULL default gen_random_uuid — לא לשלוח ב־insert
- message_id text NULL — קיבוץ קבלה
- inserted_at timestamptz NOT NULL default now — לא לשלוח ב־insert
- Shared_exp smallint NULL — >0 משותף, אחרת אישי
- installment_group_id uuid NULL
- installment_number int NULL
- installments_total int NULL
- purchase_date date NULL

Business rules:
1. אם installment_group_id לא ריק → תשלומים
2. else אם is_fixed == 1 → קבועה
3. else → משתנה
4. בתשלומים is_fixed תמיד 0
5. הוצאה משותפת ברמת message_id
6. יומן: קיבוץ לפי חודש של created_at, ואז לפי message_id
7. סדר: created_at DESC
8. שליפת ledger עם limit גבוה (למשל 3000)

### פעולות Expenses

Fetch ledger:
```
GET /rest/v1/expenses_new?select=*&order=created_at.desc&limit=3000
```

Create single expense:
```json
{
  "created_at": "2026-08-01T00:00:00.000Z",
  "item_name": "חלב",
  "amount": 12.9,
  "category": "מזון",
  "sub_category": "סופר",
  "is_fixed": 0,
  "source": "life_app",
  "message_id": null,
  "Shared_exp": 0,
  "installment_group_id": null,
  "installment_number": null,
  "installments_total": null,
  "purchase_date": null
}
```

Update:
```
PATCH /rest/v1/expenses_new?id=eq.{id}
```

Delete:
```
DELETE /rest/v1/expenses_new?id=eq.{id}
```

Toggle shared for whole receipt:
```
PATCH /rest/v1/expenses_new?message_id=eq.{messageId}
{"Shared_exp": 1}
```

### יצירת תוכנית תשלומים
ליצור N שורות ב־insert אחד:
- אותו installment_group_id לכולן
- installment_number = i
- installments_total = N
- created_at = firstChargeDate + (i-1) months
- purchase_date = תאריך רכישה מקורי בפורמט YYYY-MM-DD
- amount מחולק שווה; שארית אגורות לתשלום האחרון
- is_fixed = 0
- source = "life_app"

דוגמה ל־3 תשלומים על 100:
```json
[
  {
    "created_at": "2026-08-01T00:00:00.000Z",
    "item_name": "טלוויזיה",
    "amount": 33.33,
    "category": "טכנולוגיה וציוד",
    "sub_category": "אלקטרוניקה",
    "is_fixed": 0,
    "source": "life_app",
    "Shared_exp": 0,
    "installment_group_id": "11111111-1111-4111-8111-111111111111",
    "installment_number": 1,
    "installments_total": 3,
    "purchase_date": "2026-08-01"
  },
  {
    "created_at": "2026-09-01T00:00:00.000Z",
    "item_name": "טלוויזיה",
    "amount": 33.33,
    "category": "טכנולוגיה וציוד",
    "sub_category": "אלקטרוניקה",
    "is_fixed": 0,
    "source": "life_app",
    "Shared_exp": 0,
    "installment_group_id": "11111111-1111-4111-8111-111111111111",
    "installment_number": 2,
    "installments_total": 3,
    "purchase_date": "2026-08-01"
  },
  {
    "created_at": "2026-10-01T00:00:00.000Z",
    "item_name": "טלוויזיה",
    "amount": 33.34,
    "category": "טכנולוגיה וציוד",
    "sub_category": "אלקטרוניקה",
    "is_fixed": 0,
    "source": "life_app",
    "Shared_exp": 0,
    "installment_group_id": "11111111-1111-4111-8111-111111111111",
    "installment_number": 3,
    "installments_total": 3,
    "purchase_date": "2026-08-01"
  }
]
```

---

## 7) RPC: `life_app_get_expenses_summary`

```
POST /rest/v1/rpc/life_app_get_expenses_summary
{}
```

Response צפוי:
```json
{
  "grand_total": 12345.67,
  "total_count": 1300,
  "first_date": "2024-01-01T00:00:00+00:00",
  "last_date": "2026-08-01T00:00:00+00:00",
  "categories": [
    { "category": "מזון", "total": 4000.0, "count": 200 },
    { "category": "דיור", "total": 3000.0, "count": 12 }
  ]
}
```

---

## 8) Repository methods למימוש

TasksRepository:
- fetchActiveTasks(category: String?)
- createTask(task)
- updateTask(task)
- toggleTaskStatus(id, isCompleted)
- deleteTask(id)

ExpensesRepository:
- getExpensesForLedger(limit = 3000)
- createExpense(expense)
- updateExpense(expense)
- deleteExpense(id)
- updateSharedFlagForMessage(messageId, sharedExp)
- createInstallmentPlan(...)
- getSummary()

---

## 9) Do / Don't

Do:
- השתמש ב־expenses_new
- כתוב בדיוק Shared_exp
- פרסר amount כ־number או string
- לתשלומים צור N שורות עם אותו installment_group_id

Don't:
- אל תכתוב לטבלה expenses
- אל תשים is_fixed = 3 (מותר רק 0/1)
- אל תשלח service_role באפליקציה
- אל תבנה Auth בשלב זה

---

## 10) מה לבנות עכשיו

בנה אפליקציית Android עם:
1. מסך בית עם 2 מודולים
2. מודול משימות מלא (CRUD + סינון + עדיפות + תאריך יעד)
3. מודול הוצאות עם טאב יומן + טאב דשבורד
4. טפסי הוספה/עריכה להוצאות כולל תשלומים והוצאה משותפת
5. חיבור ל־Supabase לפי החוזה למעלה
