
const ALLOWED = {
  "דיור": ["שכירות","ארנונה","חשמל","מים","ועד בית","ריהוט","תחזוקת בית","מוצרי ניקיון","ציוד לבית"],
  "מזון": ["סופר","מסעדות","משלוחים","בתי קפה","שתייה","חטיפים"],
  "תחבורה": ["הלוואת רכב","דלק","חניה","מוניות","תחבורה ציבורית","טיפולים","ביטוח רכב","אגרות רכב"],
  "בריאות": ["תרופות","רופא","טיפול רפואי","בריאות הנפש","כושר"],
  "טיפוח": ["קוסמטיקה","תספורת","מוצרי טיפוח","שירותי טיפוח"],
  "בילויים ופנאי": ["ברים","קולנוע","אטרקציות","אירועים","תחביבים","בילוי כללי"],
  "קניות": ["אלקטרוניקה","ציוד","ציוד משרדי","קניות כלליות"],
  "ביגוד והנעלה": ["ביגוד","נעליים","אביזרים"],
  "נסיעות ונופש": ["טיסות","מלונות","טיולים","תחבורה בחו\"ל","הוצאות חופשה"],
  "מתנות ותרומות": ["מתנות","תרומות"],
  "מנויים ושירותים": ["שירותים דיגיטליים","תקשורת","אפליקציות","מנויים","שירותים חוזרים"],
  "הוצאות אישיות": ["ספרים","צרכים אישיים","שירותים אישיים","הוצאה אישית כללית"],
  "עישון": ["סיגריות","טבק","נייר גלגול","פילטרים","מצתים"],
  "עמלות ופיננסים": ["עמלות","דמי תפעול","אגרות פיננסיות"],
  "שונות": ["שונות"]
};

function normalizeClassification(expense) {
  let category = String(expense.category || "").trim();
  let sub = String(expense.sub_category || "").trim();
  let confidence = Number(expense.classification_confidence);
  if (!Number.isFinite(confidence)) confidence = 0.5;
  confidence = Math.max(0, Math.min(1, confidence));

  let needsReview = Boolean(expense.needs_review);
  if (confidence < 0.70) {
    category = "שונות";
    sub = "שונות";
    needsReview = true;
  }

  if (!ALLOWED[category]) {
    category = "שונות";
    sub = "שונות";
    needsReview = true;
  } else if (!ALLOWED[category].includes(sub)) {
    // keep category; fall back sub to first allowed or שונות-equivalent
    sub = ALLOWED[category][0];
    if (confidence < 0.85) needsReview = true;
  }

  // Car loan always fixed
  if (category === "תחבורה" && sub === "הלוואת רכב") {
    expense.is_fixed = true;
  }

  let isFixed = expense.is_fixed === true || expense.is_fixed === 1 || expense.is_fixed === "1" || expense.is_fixed === "true";
  return {
    category,
    sub_category: sub || "שונות",
    is_fixed: isFixed ? 1 : 0,
    classification_confidence: confidence,
    classification_reason: String(expense.classification_reason || "").slice(0, 240),
    needs_review: needsReview
  };
}

const inputItem = $input.first();
let rawText = inputItem.json.content?.parts?.[0]?.text || inputItem.json.text || "";
let cleanText = rawText.replace(/```json|```/g, '').trim();

let expensesArray = [];
try {
    let jsonArray = JSON.parse(cleanText);
    expensesArray = Array.isArray(jsonArray) ? jsonArray : [jsonArray];
} catch (e) {
    expensesArray = [{ 
        item_name: "שגיאה בפענוח JSON", 
        error: "המודל החזיר פורמט לא תקין", 
        raw: cleanText 
    }];
}

const newItems = [];

const getIsraelTimeString = () => {
    const options = { 
        timeZone: 'Asia/Jerusalem', 
        year: 'numeric', 
        month: '2-digit', 
        day: '2-digit', 
        hour: '2-digit', 
        minute: '2-digit', 
        second: '2-digit', 
        hour12: false 
    };
    const formatter = new Intl.DateTimeFormat('en-US', options);
    const parts = formatter.formatToParts(new Date());
    const map = {};
    parts.forEach(p => map[p.type] = p.value);
    return `${map.year}-${map.month}-${map.day}T${map.hour}:${map.minute}:${map.second}.000Z`;
};

// Prefer receipt date from model; else Telegram message date.
let telegramTs = null;
try {
  const msg = $('Telegram Trigger').first().json.message || {};
  if (msg.date) telegramTs = new Date(msg.date * 1000);
} catch (e) {}

for (const expense of expensesArray) {
    try {
        const sanitizedAmount = String(expense.amount || "0").replace(',', '.').replace(/[^0-9.]/g, "");
        const cls = normalizeClassification(expense);
        let created = expense.created_at;
        let dateSource = "receipt";
        if (!created) {
          if (telegramTs) {
            created = telegramTs.toISOString();
            dateSource = "telegram";
          } else {
            created = getIsraelTimeString();
            dateSource = "telegram";
          }
        }
        // Normalize date-only to noon Israel-ish ISO date for purchase_date
        const purchaseDate = String(created).slice(0, 10);
        // If model gave YYYY-MM-DD only, expand to timestamptz noon
        let createdAt = created;
        if (/^\d{4}-\d{2}-\d{2}$/.test(String(created))) {
          createdAt = `${created}T12:00:00.000Z`;
        }

        newItems.push({
            json: {
                item_name: expense.item_name || "פריט ללא שם",
                amount: parseFloat(sanitizedAmount) || 0,
                category: cls.category,
                sub_category: cls.sub_category,
                created_at: createdAt,
                purchase_date: purchaseDate,
                date_source: dateSource,
                is_fixed: cls.is_fixed,
                source: "telegram_media",
                classification_confidence: cls.classification_confidence,
                classification_reason: cls.classification_reason,
                needs_review: cls.needs_review
            }
        });
    } catch (error) {
        newItems.push({
            json: {
                item_name: "שגיאה בעיבוד פריט",
                amount: 0,
                category: "שונות",
                sub_category: "שונות",
                created_at: getIsraelTimeString(),
                is_fixed: 0,
                source: "telegram_error",
                error_details: error.message,
                needs_review: true
            }
        });
    }
}

return newItems;
