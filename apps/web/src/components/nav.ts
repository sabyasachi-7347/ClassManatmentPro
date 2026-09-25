import { Role } from '../lib/types';

export interface NavItem {
  to: string;
  label: string;
  icon: string;
  roles?: Role[];
}

const STAFF: Role[] = ['owner', 'admin'];

export const NAV: NavItem[] = [
  { to: '/', label: 'Dashboard', icon: '◧' },
  { to: '/batches', label: 'Batches', icon: '▦' },
  { to: '/students', label: 'Students', icon: '◉', roles: [...STAFF, 'teacher'] },
  { to: '/enrollment', label: 'Enrollment', icon: '▤', roles: STAFF },
  { to: '/attendance', label: 'Attendance', icon: '✓', roles: [...STAFF, 'teacher'] },
  { to: '/fees', label: 'Fees', icon: '₹', roles: [...STAFF, 'student', 'parent'] },
  { to: '/announcements', label: 'Announcements', icon: '✉' },
  { to: '/members', label: 'Team & access', icon: '◎', roles: STAFF },
];

export const navFor = (role?: Role) => NAV.filter((n) => !n.roles || (role && n.roles.includes(role)));
