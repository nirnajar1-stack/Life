import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  createTask,
  fetchChatter,
  fetchTask,
  fetchTasks,
  postChatter,
  updateTaskStatus,
} from '@/api/stubs'
import { users } from '@/data/mock'
import type {
  ChatterMessage,
  ChatterVisibility,
  Task,
  TaskStatus,
  User,
  UserRole,
} from '@/types'

interface AppState {
  currentUser: User
  setRole: (role: UserRole) => void
  switchUser: (userId: string) => void
  tasks: Task[]
  refreshTasks: () => Promise<void>
  getTask: (id: string) => Promise<Task | undefined>
  changeStatus: (taskId: string, status: TaskStatus) => Promise<void>
  addChatter: (
    taskId: string,
    body: string,
    visibility: ChatterVisibility,
  ) => Promise<void>
  loadChatter: (taskId: string) => Promise<ChatterMessage[]>
  createNewTask: Parameters<typeof createTask>[0] extends infer T
    ? (input: T) => Promise<Task>
    : never
  searchQuery: string
  setSearchQuery: (q: string) => void
  toast: string | null
  showToast: (msg: string) => void
}

const AppContext = createContext<AppState | null>(null)

const roleDefaultUser: Record<UserRole, string> = {
  matam: 'u-nir',
  molecule: 'u-dana',
  family: 'u-family-cohen',
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [currentUser, setCurrentUser] = useState<User>(users[0])
  const [tasks, setTasks] = useState<Task[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [toast, setToast] = useState<string | null>(null)

  const showToast = useCallback((msg: string) => {
    setToast(msg)
    window.setTimeout(() => setToast(null), 2800)
  }, [])

  const refreshTasks = useCallback(async () => {
    setTasks(await fetchTasks())
  }, [])

  const setRole = useCallback((role: UserRole) => {
    const u = users.find((x) => x.id === roleDefaultUser[role])
    if (u) setCurrentUser(u)
  }, [])

  const switchUser = useCallback((userId: string) => {
    const u = users.find((x) => x.id === userId)
    if (u) setCurrentUser(u)
  }, [])

  const getTask = useCallback(async (id: string) => fetchTask(id), [])

  const changeStatus = useCallback(
    async (taskId: string, status: TaskStatus) => {
      if (currentUser.role !== 'matam') {
        showToast('למולקולה אין הרשאה לשנות סטטוס')
        return
      }
      await updateTaskStatus(taskId, status)
      await refreshTasks()
      showToast('הסטטוס עודכן')
    },
    [currentUser.role, refreshTasks, showToast],
  )

  const addChatter = useCallback(
    async (taskId: string, body: string, visibility: ChatterVisibility) => {
      await postChatter({
        taskId,
        authorId: currentUser.id,
        body,
        visibility,
      })
      await refreshTasks()
      showToast('התגובה נשמרה (דמה)')
    },
    [currentUser.id, refreshTasks, showToast],
  )

  const loadChatter = useCallback(
    async (taskId: string) => fetchChatter(taskId),
    [],
  )

  const createNewTask = useCallback(
    async (input: Parameters<typeof createTask>[0]) => {
      const task = await createTask(input)
      await refreshTasks()
      showToast(`משימה ${task.number} נוצרה`)
      return task
    },
    [refreshTasks, showToast],
  )

  const value = useMemo(
    () => ({
      currentUser,
      setRole,
      switchUser,
      tasks,
      refreshTasks,
      getTask,
      changeStatus,
      addChatter,
      loadChatter,
      createNewTask,
      searchQuery,
      setSearchQuery,
      toast,
      showToast,
    }),
    [
      currentUser,
      setRole,
      switchUser,
      tasks,
      refreshTasks,
      getTask,
      changeStatus,
      addChatter,
      loadChatter,
      createNewTask,
      searchQuery,
      toast,
      showToast,
    ],
  )

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>
}

export function useApp() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp must be used within AppProvider')
  return ctx
}
