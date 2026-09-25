import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthUser, Role } from './auth.types';
import { IS_PUBLIC_KEY, ROLES_KEY } from './decorators';

/**
 * Every non-public route requires membership of an institute unless it is
 * explicitly marked with @Roles() and no roles (onboarding endpoints).
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const targets = [ctx.getHandler(), ctx.getClass()];
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, targets)) return true;

    const roles = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES_KEY, targets);
    const user: AuthUser = ctx.switchToHttp().getRequest().user;

    // @Roles() with no arguments = any signed-in user, even without an institute yet.
    if (roles && roles.length === 0) return true;

    if (!user.instituteId || !user.role) {
      throw new ForbiddenException('You are not a member of any institute yet');
    }
    if (roles && !roles.includes(user.role)) {
      throw new ForbiddenException(`Requires role: ${roles.join(', ')}`);
    }
    return true;
  }
}
