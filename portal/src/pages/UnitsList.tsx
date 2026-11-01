import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Panel } from '@/components/ui/card'
import { units } from '@/data/mock'
import { formatRelativeHe } from '@/lib/utils'
import { useApp } from '@/state/AppContext'

export function UnitsList() {
  const { searchQuery, setSearchQuery, currentUser } = useApp()
  const [region, setRegion] = useState('all')
  const [attentionOnly, setAttentionOnly] = useState(false)

  const regions = useMemo(
    () => Array.from(new Set(units.map((u) => u.region))),
    [],
  )

  const filtered = useMemo(() => {
    let list = [...units]
    if (currentUser.role === 'matam') {
      // Show all for discovery; matam's units sorted first
      list.sort((a, b) => {
        const aMine = a.matamId === currentUser.id ? 0 : 1
        const bMine = b.matamId === currentUser.id ? 0 : 1
        if (aMine !== bMine) return aMine - bMine
        return Number(b.needsAttention) - Number(a.needsAttention)
      })
    }
    if (region !== 'all') list = list.filter((u) => u.region === region)
    if (attentionOnly) list = list.filter((u) => u.needsAttention)
    const q = searchQuery.trim()
    if (q) {
      list = list.filter(
        (u) =>
          u.familyName.includes(q) ||
          u.region.includes(q) ||
          u.members.some((m) => m.name.includes(q)),
      )
    }
    return list
  }, [searchQuery, region, attentionOnly, currentUser])

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-[28px] font-bold">יחידות טיפול</h1>
        <p className="mt-1 text-[14px] text-slate-gray">
          חיפוש וסינון · מעבר לתיק מלא
        </p>
      </div>

      <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
        <Input
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="חיפוש משפחה / בן משפחה…"
          className="sm:max-w-sm"
        />
        <select
          className="h-10 rounded-md border border-hairline bg-pebble px-3 text-[13px]"
          value={region}
          onChange={(e) => setRegion(e.target.value)}
          aria-label="אזור"
        >
          <option value="all">כל האזורים</option>
          {regions.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>
        <label className="inline-flex items-center gap-2 text-[13px]">
          <input
            type="checkbox"
            checked={attentionOnly}
            onChange={(e) => setAttentionOnly(e.target.checked)}
            className="accent-signal-blue"
          />
          דורשות התייחסות בלבד
        </label>
      </div>

      <Panel className="!p-0 overflow-hidden">
        <ul className="divide-y divide-hairline">
          {filtered.map((u) => (
            <li key={u.id}>
              <Link
                to={`/units/${u.id}`}
                className="flex flex-col gap-2 px-4 py-4 hover:bg-pebble/70 sm:flex-row sm:items-center sm:justify-between sm:px-6"
              >
                <div>
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="text-[16px] font-semibold">
                      משפחת {u.familyName}
                    </span>
                    <Badge tone="muted">{u.region}</Badge>
                    {u.needsAttention && (
                      <Badge tone="danger">דורשת התייחסות</Badge>
                    )}
                  </div>
                  <p className="mt-1 text-[13px] text-slate-gray">{u.summary}</p>
                  <p className="mt-1 text-[12px] text-mist-gray">
                    פעילות אחרונה · {formatRelativeHe(u.lastActivityAt)}
                  </p>
                </div>
                <div className="flex gap-4 text-[13px] sm:text-end">
                  <div>
                    <div className="font-semibold tabular-nums">{u.openTasks}</div>
                    <div className="text-mist-gray">פתוחות</div>
                  </div>
                  <div>
                    <div
                      className={`font-semibold tabular-nums ${u.overdueTasks ? 'text-danger' : ''}`}
                    >
                      {u.overdueTasks}
                    </div>
                    <div className="text-mist-gray">חורגות</div>
                  </div>
                </div>
              </Link>
            </li>
          ))}
          {filtered.length === 0 && (
            <li className="px-4 py-10 text-center text-[14px] text-slate-gray">
              לא נמצאו יחידות
            </li>
          )}
        </ul>
      </Panel>
    </div>
  )
}
