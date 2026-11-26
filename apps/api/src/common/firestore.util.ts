import { DocumentSnapshot, Timestamp } from 'firebase-admin/firestore';

/** Recursively converts Firestore Timestamps to ISO strings so they serialize cleanly. */
function normalize(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, normalize(v)]));
  }
  return value;
}

export function toDto<T = Record<string, unknown>>(snap: DocumentSnapshot): T & { id: string } {
  return { id: snap.id, ...(normalize(snap.data()) as T) };
}

/** Firestore path helpers — all institute data lives under institutes/{instituteId}. */
export const paths = {
  institute: (iid: string) => `institutes/${iid}`,
  members: (iid: string) => `institutes/${iid}/members`,
  batches: (iid: string) => `institutes/${iid}/batches`,
  students: (iid: string) => `institutes/${iid}/students`,
  attendance: (iid: string) => `institutes/${iid}/attendance`,
  fees: (iid: string) => `institutes/${iid}/fees`,
  announcements: (iid: string) => `institutes/${iid}/announcements`,
  absences: (iid: string) => `institutes/${iid}/absences`,
  tests: (iid: string) => `institutes/${iid}/tests`,
};

/**
 * Firestore rejects objects with custom prototypes, and ValidationPipe turns nested
 * DTOs into class instances — strip them back to plain data before writing.
 */
export function plain<T extends object>(dto: T): T {
  return JSON.parse(JSON.stringify(dto)) as T;
}
