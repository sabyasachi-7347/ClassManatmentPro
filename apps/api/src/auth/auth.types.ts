export enum Role {
  Owner = 'owner',
  Admin = 'admin',
  Teacher = 'teacher',
  Student = 'student',
  Parent = 'parent',
}

export const STAFF_ROLES = [Role.Owner, Role.Admin] as const;

/** Shape of the Firebase custom claims we set on every member. */
export interface MemberClaims {
  role?: Role;
  instituteId?: string;
  /** For student/parent accounts: the student record(s) they can see. */
  studentIds?: string[];
}

export interface AuthUser extends MemberClaims {
  uid: string;
  email?: string;
  name?: string;
}
