import { ForbiddenException } from '@nestjs/common';
import { AuthUser } from '../auth/auth.types';

/** Returns the caller's institute id; RolesGuard already guarantees it for member routes. */
export function tenantOf(user: AuthUser): string {
  if (!user.instituteId) throw new ForbiddenException('No institute');
  return user.instituteId;
}
