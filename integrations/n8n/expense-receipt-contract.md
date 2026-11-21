# n8n / Telegram — חוזה קליטת הוצאות (Receipt)

מסמך זה מגדיר איך workflow חיצוני (Telegram / WhatsApp / OCR) צריך לכתוב ל־`expenses_new`
ולאשר למשתמש. הקליטה עצמה אינה בריפו Life; האפליקציה צורכת את השדות האלה.

## Priority לתאריך (`transaction_date` = `purchase_date`)

1. תאריך אמין מהחשבונית / OCR → `date_source = receipt`
2. אחרת — תאריך+שעה של הודעת Telegram → `date_source = telegram`
3. **אסור** תאריך גנרי / hardcoded

שדות לשמור:

| Field | Meaning |
|-------|---------|
| `purchase_date` | תאריך העסקה (YYYY-MM-DD) |
| `created_at` | רצוי אותו יום ב־noon UTC (או timestamp ההודעה) |
| `date_source` | `receipt` \| `telegram` \| `manual` \| `import` |
| `source_message_timestamp` | `message.date` מטלגרם (timestamptz) |

## Priority לסכום ששולם

1. Amount Paid  
2. Total Paid  
3. Grand Total  
4. סה״כ לתשלום  
5. סה״כ לאחר הנחות  
6. סכום עסקה  
7. Net Total  
8. רק אם אין Total — סכום Line Items (אחרי הנחות שורה)

שדות:

| Field | Example |
|-------|---------|
| `gross_amount` | 100 |
| `discount_amount` | 20 |
| `paid_amount` | 80 |
| `amount` | 80 (אותו ערך כמו paid — תאימות לאחור) |
| `extracted_total_label` | `"סה״כ לתשלום"` |
| `extraction_confidence` | `0.94` |

Line items: העדף `final_line_total` על פני `qty * unit_price`.

## Confirmation לטלגרם (חובה אחרי Insert)

```
נקלטה הוצאה

סכום:
124.90 ₪

קטגוריה:
מזון

תאריך שנרשם:
21/11/2026

מקור התאריך:
תאריך ההודעה
```

אם התאריך מהחשבונית: `מקור התאריך: חשבונית`  
אם יש שם עסק: הוסף שורת `עסק: …`

## Shared

ברירת מחדל למשק בית משותף: `Shared_exp = 2` אלא אם המשתמש סימן אחרת.

## Behavior (`expense_behavior_type`)

ערכים מותרים:

| Value | Daily Pace | Monthly Cashflow |
|-------|------------|------------------|
| `fixed_commitment` | ❌ | ✅ |
| `recurring_variable` | ❌ | ✅ |
| `variable_discretionary` | ✅ | ✅ |
| `one_time` | ❌ | ✅ |

`one_time` רק להוצאה חריגה משמעותית (טיסה / מלון / חופשה / ריהוט גדול / מחשב משמעותי) — לא לקניות שוטפות.

Installments: לא נכנסים ל־Daily Pace, כן נכנסים ל־Monthly Expected Outflow / Balance / Future Commitments.

Legacy rows ללא ערך בעמודה מסווגים בזמן קריאה ע״י `deriveExpenseBehaviorType` (בלי backfill).
