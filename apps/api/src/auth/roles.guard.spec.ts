import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthUser, Role } from './auth.types';
import { IS_PUBLIC_KEY, ROLES_KEY } from './decorators';
import { RolesGuard } from './roles.guard';

function ctxFor(user: Partial<AuthUser>): ExecutionContext {
  return {
    getHandler: () => undefined,
    getClass: () => undefined,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

function guardWith(meta: Record<string, unknown>) {
  const reflector = { getAllAndOverride: (key: string) => meta[key] } as unknown as Reflector;
  return new RolesGuard(reflector);
}

describe('RolesGuard', () => {
  const teacher = { uid: 't1', role: Role.Teacher, instituteId: 'i1' };

  it('allows public routes', () => {
    expect(guardWith({ [IS_PUBLIC_KEY]: true }).canActivate(ctxFor({}))).toBe(true);
  });

  it('allows onboarding routes (@Roles() with no roles) without an institute', () => {
    expect(guardWith({ [ROLES_KEY]: [] }).canActivate(ctxFor({ uid: 'u' }))).toBe(true);
  });

  it('rejects members without an institute on normal routes', () => {
    expect(() => guardWith({}).canActivate(ctxFor({ uid: 'u' }))).toThrow(ForbiddenException);
  });

  it('allows any member when no roles are required', () => {
    expect(guardWith({}).canActivate(ctxFor(teacher))).toBe(true);
  });

  it('enforces required roles', () => {
    const guard = guardWith({ [ROLES_KEY]: [Role.Owner, Role.Admin] });
    expect(() => guard.canActivate(ctxFor(teacher))).toThrow(ForbiddenException);
    expect(guard.canActivate(ctxFor({ ...teacher, role: Role.Admin }))).toBe(true);
  });
});
