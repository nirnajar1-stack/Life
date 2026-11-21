
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

for (const item of $input.all()) {
    try {
        const rawText = item.json.content.parts[0].text;
        const parsedData = JSON.parse(rawText);
        const expensesArray = Array.isArray(parsedData) ? parsedData : [parsedData];
        const messageSource = "telegram"; 
        
        for (const expense of expensesArray) {
            const cls = normalizeClassification(expense);
            const amount = expense.amount ? Number(String(expense.amount).replace(/[^0-9.-]/g, "")) : 0;
            const created = expense.created_at || getIsraelTimeString();
            const purchaseDate = String(created).slice(0, 10);
            newItems.push({
                json: {
                    item_name: expense.item_name || "פריט ללא שם",
                    amount,
                    category: cls.category,
                    sub_category: cls.sub_category,
                    created_at: created,
                    purchase_date: purchaseDate,
                    date_source: "telegram",
                    is_fixed: cls.is_fixed,
                    source: expense.source || messageSource,
                    classification_confidence: cls.classification_confidence,
                    classification_reason: cls.classification_reason,
                    needs_review: cls.needs_review
                }
            });
        }
        
    } catch (error) {
        newItems.push({
            json: {
                item_name: "שגיאה בפענוח הודעה",
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
