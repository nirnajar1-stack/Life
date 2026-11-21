# Expense Classification Taxonomy (n8n Agent)

Applies to **new** expenses only via workflow  
`Get_Data_EXP_from_WhatsUp_Mes` (`CHOEpdOYHdJvy54D`).

No historical reclassification / backfill. Legacy rows are classified at read
time by `deriveExpenseBehaviorType` in the Flutter app.

## Canonical categories

1. דיור  
2. מזון  
3. תחבורה  
4. בריאות  
5. טיפוח  
6. בילויים ופנאי  
7. קניות  
8. ביגוד והנעלה  
9. נסיעות ונופש  
10. מתנות ותרומות  
11. מנויים ושירותים  
12. הוצאות אישיות  
13. עישון  
14. עמלות ופיננסים  
15. שונות  

## Subcategories

| Category | Subcategories |
|----------|---------------|
| דיור | שכירות, ארנונה, חשמל, מים, ועד בית, ריהוט, תחזוקת בית, מוצרי ניקיון, ציוד לבית |
| מזון | סופר, מסעדות, משלוחים, בתי קפה, שתייה, חטיפים |
| תחבורה | הלוואת רכב, דלק, חניה, מוניות, תחבורה ציבורית, טיפולים, ביטוח רכב, אגרות רכב |
| בריאות | תרופות, רופא, טיפול רפואי, בריאות הנפש, כושר |
| טיפוח | קוסמטיקה, תספורת, מוצרי טיפוח, שירותי טיפוח |
| בילויים ופנאי | ברים, קולנוע, אטרקציות, אירועים, תחביבים, בילוי כללי |
| קניות | אלקטרוניקה, ציוד, ציוד משרדי, קניות כלליות |
| ביגוד והנעלה | ביגוד, נעליים, אביזרים |
| נסיעות ונופש | טיסות, מלונות, טיולים, תחבורה בחו"ל, הוצאות חופשה |
| מתנות ותרומות | מתנות, תרומות |
| מנויים ושירותים | שירותים דיגיטליים, תקשורת, אפליקציות, מנויים, שירותים חוזרים |
| הוצאות אישיות | ספרים, צרכים אישיים, שירותים אישיים, הוצאה אישית כללית |
| עישון | סיגריות, טבק, נייר גלגול, פילטרים, מצתים |
| עמלות ופיננסים | עמלות, דמי תפעול, אגרות פיננסיות |
| שונות | שונות |

## Behavior type (`expense_behavior_type`)

| Value | Meaning | Daily Pace | Monthly Cashflow |
|-------|---------|------------|------------------|
| `fixed_commitment` | שכירות / הלוואה / ביטוח / מנוי / תשלומים | ❌ | ✅ |
| `recurring_variable` | חשמל / מים / ארנונה | ❌ | ✅ |
| `variable_discretionary` | קניות שוטפות (ביגוד, מסעדה, סופר…) | ✅ | ✅ |
| `one_time` | חריגה משמעותית (טיסה, מלון, ריהוט גדול…) | ❌ | ✅ |

`one_time` is **not** every one-off purchase — only exceptional / significant spends.

## Structured output (per line item)

```json
{
  "item_name": "...",
  "amount": 0.0,
  "category": "...",
  "sub_category": "...",
  "is_fixed": false,
  "expense_behavior_type": "variable_discretionary",
  "classification_confidence": 0.0,
  "classification_reason": "...",
  "needs_review": false,
  "created_at": "YYYY-MM-DDTHH:mm:ss+03:00"
}
```

## Confidence gate (Code nodes)

- `confidence >= 0.70` → keep model category/sub  
- `confidence < 0.70` → force `שונות` / `שונות`, `needs_review=true`  
- Invalid category → `שונות`  
- Derive / validate `expense_behavior_type`; map `is_fixed` 0/1 from it  
- `needs_review` / confidence stay in flow JSON for confirmations; **not** persisted

## Nodes updated (live n8n)

| Node | Change |
|------|--------|
| Message a model | Taxonomy + behavior type |
| Message a model2 | Same for voice |
| Analyze an image | Same for OCR |
| Code in JavaScript | Normalize + behavior + `is_fixed` |
| Code in JavaScript1 | Same for media |
| Create a row1 | Writes `expense_behavior_type` |
| Send a text message1 | Confirmation shows behavior |

Workflow URL: https://nir0544.app.n8n.cloud/workflow/CHOEpdOYHdJvy54D
