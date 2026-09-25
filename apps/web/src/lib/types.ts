export type Role = 'owner' | 'admin' | 'teacher' | 'student' | 'parent';
export type AttendanceStatus = 'present' | 'absent' | 'late' | 'excused';

export interface Institute { id: string; name: string; city?: string; phone?: string }
export interface Me {
  uid: string;
  email?: string;
  role?: Role;
  studentIds?: string[];
  institute: Institute | null;
  member?: { name: string } | null;
}
export interface Slot { day: number; start: string; end: string }
export interface Batch {
  id: string;
  name: string;
  subject: string;
  teacherIds: string[];
  schedule: Slot[];
  room?: string;
  capacity?: number;
  monthlyFee?: number;
  archived?: boolean;
}
export interface Student {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  guardianName?: string;
  guardianPhone?: string;
  grade?: string;
  batchIds: string[];
  status: 'active' | 'inactive';
}
export interface Member { id: string; name: string; email?: string; role: Role; phone?: string }
export interface Fee {
  id: string;
  studentId: string;
  studentName?: string;
  amount: number;
  dueDate: string;
  period?: string;
  status: 'due' | 'paid' | 'waived';
  overdue?: boolean;
  payment?: { method: string; paidOn: string; reference?: string };
}
export interface AttendanceSession {
  id: string;
  batchId: string;
  date: string;
  records: Record<string, AttendanceStatus>;
  summary: { total: number; present: number; late: number; absent: number; excused: number };
}
export interface Announcement {
  id: string;
  title: string;
  body: string;
  batchIds: string[];
  authorName?: string;
  createdAt?: string;
}
export interface TodayClass {
  batchId: string;
  name: string;
  subject: string;
  room?: string;
  start: string;
  end: string;
  attendanceMarked: boolean;
}
export interface Dashboard {
  date: string;
  role: Role;
  batchCount: number;
  todaysClasses: TodayClass[];
  activeStudents?: number;
  attendanceToday?: { present: number; total: number; rate: number | null };
  fees?: { dueCount: number; dueAmount: number; overdueCount: number };
  pendingAttendance?: number;
  students?: { id: string; name: string; attendanceRate30d: number | null }[];
  dues?: Fee[];
}

export const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
export const isStaff = (r?: Role) => r === 'owner' || r === 'admin';
export const today = () => new Date().toLocaleDateString('en-CA');
export const initials = (name = '') =>
  name.split(/\s+/).filter(Boolean).slice(0, 2).map((p) => p[0]!.toUpperCase()).join('');
export const money = (n: number) =>
  new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(n);
