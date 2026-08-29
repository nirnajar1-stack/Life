/**
 * Shared natural-language calendar parser for the n8n Code node.
 * Timezone assumption: Asia/Jerusalem (wall-clock local).
 *
 * Input:  { text, nowIso? }
 * Output: { ok, title, startsAt, endsAt, durationMinutes, timeInferred, durationInferred, error? }
 */

const WEEKDAYS_HE = {
  ראשון: 0,
  שני: 1,
  שלישי: 2,
  רביעי: 3,
  חמישי: 4,
  שישי: 5,
  שבת: 6,
};

const WEEKDAYS_EN = {
  sunday: 0,
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
};

const MONTHS_HE = {
  ינואר: 0,
  פברואר: 1,
  מרץ: 2,
  אפריל: 3,
  מאי: 4,
  יוני: 5,
  יולי: 6,
  אוגוסט: 7,
  ספטמבר: 8,
  אוקטובר: 9,
  נובמבר: 10,
  דצמבר: 11,
};

function startOfDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function nextWeekday(today, weekdayJs, now) {
  let delta = (weekdayJs - today.getDay() + 7) % 7;
  if (delta === 0 && now.getHours() >= 21) delta = 7;
  const out = new Date(today);
  out.setDate(out.getDate() + delta);
  return out;
}

function parseCalendarEvent(raw, now = new Date()) {
  let text = String(raw || '').trim();
  if (!text) {
    return { ok: false, error: 'הודעה ריקה' };
  }

  const today = startOfDay(now);
  let day = null;
  let hour = null;
  let minute = 0;
  let durationMinutes = 60;
  let timeInferred = true;
  let durationInferred = true;
  let forceEvening = /בערב|בלילה|אחה["״]?צ|אחר\s*הצהריים/.test(text);
  let forceMorning = /בבוקר/.test(text);

  text = text.replace(/(?:^|\s)(?:למשך\s+)?(\d+)\s*(שעות|שעה|דקות|דק|ד)(?=\s|$)/g, (_, n, unit) => {
    durationInferred = false;
    durationMinutes = String(unit).startsWith('שע') ? Number(n) * 60 : Number(n);
    return ' ';
  });
  text = text.replace(/(?:^|\s)(שעתיים)(?=\s|$)/g, () => {
    durationInferred = false;
    durationMinutes = 120;
    return ' ';
  });
  text = text.replace(/(?:^|\s)(שעה\s+אחת|שעה)(?=\s|$)/g, () => {
    durationInferred = false;
    durationMinutes = 60;
    return ' ';
  });
  text = text.replace(
    /(?:^|\s)(?:for\s+)?(\d+)\s*(h|hr|hrs|hours?|m|min|mins|minutes?)(?=\s|$)/gi,
    (_, n, unit) => {
      durationInferred = false;
      durationMinutes = String(unit).toLowerCase().startsWith('h')
        ? Number(n) * 60
        : Number(n);
      return ' ';
    },
  );

  text = text.replace(/(?:^|\s)(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?(?=\s|$)/g, (_, d, mo, yRaw) => {
    let y = yRaw == null ? now.getFullYear() : Number(yRaw);
    if (y < 100) y += 2000;
    let candidate = new Date(y, Number(mo) - 1, Number(d));
    if (yRaw == null && candidate < today) {
      candidate = new Date(y + 1, Number(mo) - 1, Number(d));
    }
    day = candidate;
    return ' ';
  });

  for (const [name, monthIndex] of Object.entries(MONTHS_HE)) {
    // 20 בספטמבר | ב־20 לספטמבר | 20 לאוקטובר 2026
    const re = new RegExp(
      `(?:^|\\s)(?:ב[־\\-]?\\s*)?(\\d{1,2})\\s*(?:ב|ל)?\\s*${name}(?:\\s+(\\d{4}))?(?=\\s|$)`,
      'g',
    );
    text = text.replace(re, (_, d, yRaw) => {
      const y = yRaw == null ? now.getFullYear() : Number(yRaw);
      let candidate = new Date(y, monthIndex, Number(d));
      if (yRaw == null && candidate < today) {
        candidate = new Date(y + 1, monthIndex, Number(d));
      }
      day = candidate;
      return ' ';
    });
  }

  text = text.replace(/(?:^|\s)(מחר|tomorrow)(?=\s|$)/gi, () => {
    day = new Date(today);
    day.setDate(day.getDate() + 1);
    return ' ';
  });
  text = text.replace(/(?:^|\s)(היום|today)(?=\s|$)/gi, () => {
    day = new Date(today);
    return ' ';
  });
  text = text.replace(/(?:^|\s)(?:עוד|בעוד)\s+(\d+)\s*ימים?(?=\s|$)/g, (_, n) => {
    day = new Date(today);
    day.setDate(day.getDate() + Number(n));
    return ' ';
  });

  for (const [name, wd] of Object.entries(WEEKDAYS_HE)) {
    const re = new RegExp(`(?:^|\\s)(?:ביום|יום)?\\s*${name}(?:\\s+הקרוב)?(?=\\s|$)`, 'g');
    text = text.replace(re, () => {
      day = nextWeekday(today, wd, now);
      return ' ';
    });
  }
  for (const [name, wd] of Object.entries(WEEKDAYS_EN)) {
    const re = new RegExp(`(?:^|\\s)(?:next\\s+)?${name}(?=\\s|$)`, 'gi');
    text = text.replace(re, () => {
      day = nextWeekday(today, wd, now);
      return ' ';
    });
  }

  text = text.replace(
    /(?:^|\s)(?:בשעה|ב[־\-]?|at)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm|בערב|בבוקר)?(?=\s|$)/gi,
    (_, h, m, suffix) => {
      timeInferred = false;
      hour = Number(h);
      minute = m == null ? 0 : Number(m);
      const s = String(suffix || '').toLowerCase();
      if (s === 'pm' || s === 'בערב') {
        if (hour < 12) hour += 12;
      } else if (s === 'am' || s === 'בבוקר') {
        if (hour === 12) hour = 0;
      }
      return ' ';
    },
  );

  text = text.replace(
    /(?:^|\s)(בערב|בבוקר|בלילה|אחה["״]?צ|אחר\s*הצהריים)(?=\s|$)/g,
    ' ',
  );

  if (!day) {
    return {
      ok: false,
      error:
        'לא מצאתי תאריך. שלחו למשל: יום שלישי בשעה 6 תור לרופא או 15/9 בשעה 10 פגישה',
    };
  }

  if (hour == null) {
    hour = 9;
    minute = 0;
    timeInferred = true;
  } else if (!forceMorning && (forceEvening || hour <= 7) && hour < 12 && hour > 0) {
    hour += 12;
  }

  if (hour > 23 || minute > 59 || durationMinutes <= 0) {
    return { ok: false, error: 'שעה או משך לא תקינים' };
  }

  const startsAt = new Date(
    day.getFullYear(),
    day.getMonth(),
    day.getDate(),
    hour,
    minute,
    0,
    0,
  );
  const endsAt = new Date(startsAt.getTime() + durationMinutes * 60_000);

  let title = text.replace(/[־\-–]+/g, ' ').replace(/\s+/g, ' ').trim();
  if (!title) title = 'אירוע';
  if (title.length > 120) title = title.slice(0, 120);

  return {
    ok: true,
    title,
    startsAt: startsAt.toISOString(),
    endsAt: endsAt.toISOString(),
    durationMinutes,
    timeInferred,
    durationInferred,
  };
}

module.exports = { parseCalendarEvent };

// Direct n8n Code-node entry when this file is pasted inline:
if (typeof $input !== 'undefined') {
  const item = $input.first().json;
  const text = item.text ?? item.message?.text ?? item.body?.text ?? '';
  const now = item.nowIso ? new Date(item.nowIso) : new Date();
  return [{ json: { ...item, ...parseCalendarEvent(text, now), rawText: text } }];
}
