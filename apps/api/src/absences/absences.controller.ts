import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { tenantOf } from '../common/tenant';
import { PushService } from '../push/push.service';
import { ListAbsencesQuery, NudgeDto, RegisterDeviceDto } from './absences.dto';
import { AbsencesService } from './absences.service';

@ApiTags('absences')
@ApiBearerAuth()
@Controller()
export class AbsencesController {
  constructor(
    private readonly svc: AbsencesService,
    private readonly push: PushService,
  ) {}

  /** Staff/teachers: one day's alerts (default today). Parents/students: their children's recent alerts. */
  @Get('absences')
  list(@CurrentUser() user: AuthUser, @Query() q: ListAbsencesQuery) {
    return this.svc.list(user, q);
  }

  @Roles(Role.Parent)
  @Post('absences/:id/ack')
  ack(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.svc.acknowledge(user, id);
  }

  @Roles(Role.Owner, Role.Admin, Role.Teacher)
  @Post('absences/nudge')
  nudge(@CurrentUser() user: AuthUser, @Body() dto: NudgeDto) {
    return this.svc.nudge(user, dto.ids, dto.date);
  }

  /** The app registers its FCM token here after sign-in. */
  @Post('me/devices')
  async register(@CurrentUser() user: AuthUser, @Body() dto: RegisterDeviceDto) {
    await this.push.registerToken(tenantOf(user), user.uid, dto.token);
    return { registered: true };
  }

  @Delete('me/devices/:token')
  async unregister(@CurrentUser() user: AuthUser, @Param('token') token: string) {
    await this.push.removeToken(tenantOf(user), user.uid, token);
    return { removed: true };
  }
}
