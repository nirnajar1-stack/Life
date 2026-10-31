# Page Override: Money

Overrides `MASTER.md` for the Money hub (expenses + income + vouchers).

## Structure
1. Navy cashflow `HeroPanel` (net + income/expense chips)
2. Tabs: הוצאות | הכנסות
3. Within expenses: פנקס | קבועות | תשלומים | ניתוח
4. Within income: פנקס | קבועות | שוברים

## Rules
- Future ledger months collapse behind expand control
- Period filter chips must wrap; selected chip uses navy fill
- Analytics MoM/trend always use calendar (non-future) data
- Recurring salary: manual amount + date entry (no auto-run)
- Soft search field with no hard outline border
