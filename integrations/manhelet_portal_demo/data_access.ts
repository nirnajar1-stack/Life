/**
 * Manhelet Portal — data-access contracts (Salesforce-swappable).
 * First adapter: Supabase/PostgREST. Do not call Supabase from UI directly.
 */

export type Id = string;

export type AppRole =
  | 'super_admin'
  | 'system_admin'
  | 'content_editor'
  | 'content_approver'
  | 'case_manager'
  | 'government_representative'
  | 'department_manager'
  | 'executive'
  | 'headquarters_staff'
  | 'family_member';

export type TaskStatus =
  | 'open'
  | 'in_progress'
  | 'waiting_external'
  | 'waiting_family'
  | 'blocked'
  | 'completed'
  | 'cancelled';

export type ChannelType = 'family_portal' | 'internal' | 'interagency';

export interface ProfileDto {
  id: Id;
  email: string;
  fullNameHe: string;
  roles: AppRole[];
}

export interface TreatmentUnitDto {
  id: Id;
  unitCode: string;
  titleHe: string;
  familyId: Id;
  openTaskCount?: number;
}

export interface TaskDto {
  id: Id;
  titleHe: string;
  status: TaskStatus;
  treatmentUnitId: Id;
  personId?: Id;
  dueAt?: string;
  familyVisible?: boolean;
}

export interface ThreadDto {
  id: Id;
  channelType: ChannelType;
  subjectHe: string;
  familyId?: Id;
  treatmentUnitId?: Id;
}

export interface SituationSummaryDto {
  openFamilies: number;
  activeUnits: number;
  personsCaptive: number;
  personsMissing: number;
  personsReturned: number;
  openTasks: number;
  criticalOpenTasks: number;
  activeRehabPlans: number;
}

export interface AuthDirectoryService {
  getMyProfile(): Promise<ProfileDto>;
  listMyRoles(): Promise<AppRole[]>;
}

export interface CaseloadService {
  listMyUnits(): Promise<TreatmentUnitDto[]>;
  getUnit(id: Id): Promise<TreatmentUnitDto>;
  listPersons(unitId: Id): Promise<unknown[]>;
  getFamily(id: Id): Promise<unknown>;
}

export interface TaskService {
  getMyTasks(): Promise<TaskDto[]>;
  listUnitTasks(unitId: Id): Promise<TaskDto[]>;
  getTask(id: Id): Promise<TaskDto>;
  createTask(input: Partial<TaskDto> & { titleHe: string; treatmentUnitId: Id }): Promise<TaskDto>;
  updateTaskStatus(id: Id, status: TaskStatus): Promise<TaskDto>;
  assignTask(id: Id, profileId: Id): Promise<void>;
}

export interface CommunicationService {
  listThreads(filter: { channelType?: ChannelType; unitId?: Id; familyId?: Id }): Promise<ThreadDto[]>;
  listMessages(threadId: Id): Promise<unknown[]>;
  postMessage(threadId: Id, bodyHe: string): Promise<unknown>;
  createThread(input: Omit<ThreadDto, 'id'>): Promise<ThreadDto>;
}

export interface InteractionService {
  listInteractions(unitId: Id): Promise<unknown[]>;
  logInteraction(input: Record<string, unknown>): Promise<unknown>;
}

export interface RehabService {
  getPlansForPerson(personId: Id): Promise<unknown[]>;
  listActivities(planId: Id): Promise<unknown[]>;
  upsertMilestone(planId: Id, input: Record<string, unknown>): Promise<unknown>;
}

export interface BenefitsService {
  listEntitlements(scope: { familyId?: Id; personId?: Id }): Promise<unknown[]>;
  updateEntitlementStatus(id: Id, status: string): Promise<unknown>;
}

export interface EventsService {
  listPublishedEvents(): Promise<unknown[]>;
  register(eventId: Id): Promise<unknown>;
}

export interface ContentService {
  listPublished(audience: string): Promise<unknown[]>;
  submitForReview(id: Id): Promise<unknown>;
  approve(id: Id): Promise<unknown>;
}

export interface KnowledgeService {
  searchArticles(q: string): Promise<unknown[]>;
  getArticle(slug: string): Promise<unknown>;
}

export interface NotificationService {
  listMine(): Promise<unknown[]>;
  markRead(id: Id): Promise<void>;
}

export interface ExecutiveService {
  getSituationSummary(): Promise<SituationSummaryDto>;
}

export interface AuditService {
  listForEntity(table: string, id: Id): Promise<unknown[]>;
}

/** Facade composing all portal services — implement per backend. */
export interface ManheletPortalDataAccess {
  auth: AuthDirectoryService;
  caseload: CaseloadService;
  tasks: TaskService;
  communications: CommunicationService;
  interactions: InteractionService;
  rehab: RehabService;
  benefits: BenefitsService;
  events: EventsService;
  content: ContentService;
  knowledge: KnowledgeService;
  notifications: NotificationService;
  executive: ExecutiveService;
  audit: AuditService;
}
