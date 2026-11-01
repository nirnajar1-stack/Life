/**
 * API stubs — structure for future Salesforce / backend wiring.
 * All functions currently resolve against in-memory mock data.
 */
import {
  chatterSeed,
  documents,
  familyRequests,
  getUnit,
  knowledgeItems,
  notifications,
  orgNews,
  rehabNotes,
  tasks as seedTasks,
  units,
  visits,
} from '@/data/mock'
import type {
  ChatterMessage,
  Task,
  TaskStatus,
  TreatmentUnit,
} from '@/types'

let tasksStore: Task[] = [...seedTasks]
let chatterStore: ChatterMessage[] = [...chatterSeed]

export async function fetchTasks(): Promise<Task[]> {
  return structuredClone(tasksStore)
}

export async function fetchTask(id: string): Promise<Task | undefined> {
  return structuredClone(tasksStore.find((t) => t.id === id))
}

export async function fetchUnits(): Promise<TreatmentUnit[]> {
  return structuredClone(units)
}

export async function fetchUnit(id: string) {
  return structuredClone(getUnit(id))
}

export async function fetchChatter(taskId: string): Promise<ChatterMessage[]> {
  return structuredClone(chatterStore.filter((c) => c.taskId === taskId))
}

export async function postChatter(
  message: Omit<ChatterMessage, 'id' | 'createdAt'>,
): Promise<ChatterMessage> {
  const created: ChatterMessage = {
    ...message,
    id: `ch-${Date.now()}`,
    createdAt: new Date().toISOString(),
  }
  chatterStore = [...chatterStore, created]
  tasksStore = tasksStore.map((t) =>
    t.id === message.taskId
      ? {
          ...t,
          hasNewReply: true,
          updatedAt: created.createdAt,
          lastActivity: 'תגובה חדשה נוספה',
        }
      : t,
  )
  return created
}

export async function updateTaskStatus(
  taskId: string,
  status: TaskStatus,
): Promise<Task | undefined> {
  tasksStore = tasksStore.map((t) =>
    t.id === taskId
      ? {
          ...t,
          status,
          updatedAt: new Date().toISOString(),
          lastActivity: `סטטוס עודכן`,
        }
      : t,
  )
  return fetchTask(taskId)
}

export async function createTask(
  input: Omit<
    Task,
    | 'id'
    | 'number'
    | 'createdAt'
    | 'updatedAt'
    | 'hasNewReply'
    | 'lastActivity'
    | 'participantIds'
    | 'waitingOnIds'
    | 'status'
  > & { status?: TaskStatus },
): Promise<Task> {
  const n = 1000 + tasksStore.length + 1
  const now = new Date().toISOString()
  const task: Task = {
    ...input,
    id: `t-${n}`,
    number: `TSK-${n}`,
    status: input.status ?? 'open',
    participantIds: [],
    waitingOnIds: [],
    createdAt: now,
    updatedAt: now,
    hasNewReply: false,
    lastActivity: 'נוצרה משימה',
  }
  tasksStore = [task, ...tasksStore]
  return structuredClone(task)
}

export async function fetchNotifications() {
  return structuredClone(notifications)
}

export async function fetchOrgNews() {
  return structuredClone(orgNews)
}

export async function fetchKnowledge() {
  return structuredClone(knowledgeItems)
}

export async function fetchFamilyRequests() {
  return structuredClone(familyRequests)
}

export async function fetchUnitExtras(unitId: string) {
  return {
    visits: visits.filter((v) => v.unitId === unitId),
    rehab: rehabNotes.filter((r) => r.unitId === unitId),
    documents: documents.filter((d) => d.unitId === unitId),
  }
}

export function resetMockStores() {
  tasksStore = [...seedTasks]
  chatterStore = [...chatterSeed]
}
