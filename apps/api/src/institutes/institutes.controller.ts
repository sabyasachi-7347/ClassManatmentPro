import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { tenantOf } from '../common/tenant';
import { CreateInstituteDto, InviteMemberDto, UpdateMemberDto } from './institutes.dto';
import { InstitutesService } from './institutes.service';

@ApiTags('institute')
@ApiBearerAuth()
@Controller()
export class InstitutesController {
  constructor(private readonly svc: InstitutesService) {}

  /** Onboarding: create an institute and become its owner. Refresh the ID token afterwards. */
  @Roles()
  @Post('institutes')
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateInstituteDto) {
    return this.svc.create(user, dto);
  }

  @Roles()
  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.svc.me(user);
  }

  @Roles(Role.Owner, Role.Admin, Role.Teacher)
  @ApiQuery({ name: 'role', enum: Role, required: false })
  @Get('members')
  list(@CurrentUser() user: AuthUser, @Query('role') role?: Role) {
    return this.svc.listMembers(tenantOf(user), role);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post('members')
  invite(@CurrentUser() user: AuthUser, @Body() dto: InviteMemberDto) {
    return this.svc.invite(tenantOf(user), dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Patch('members/:uid')
  update(@CurrentUser() user: AuthUser, @Param('uid') uid: string, @Body() dto: UpdateMemberDto) {
    return this.svc.updateMember(tenantOf(user), uid, dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Delete('members/:uid')
  remove(@CurrentUser() user: AuthUser, @Param('uid') uid: string) {
    return this.svc.removeMember(tenantOf(user), uid);
  }
}
