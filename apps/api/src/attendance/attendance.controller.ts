import { Body, Controller, Get, Param, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { AttendanceRangeQuery, MarkAttendanceDto } from './attendance.dto';
import { AttendanceService } from './attendance.service';

@ApiTags('attendance')
@ApiBearerAuth()
@Controller('attendance')
export class AttendanceController {
  constructor(private readonly svc: AttendanceService) {}

  @Roles(Role.Owner, Role.Admin, Role.Teacher)
  @Put('batches/:batchId/:date')
  mark(
    @CurrentUser() user: AuthUser,
    @Param('batchId') batchId: string,
    @Param('date') date: string,
    @Body() dto: MarkAttendanceDto,
  ) {
    return this.svc.mark(user, batchId, date, dto);
  }

  @Get('batches/:batchId')
  forBatch(
    @CurrentUser() user: AuthUser,
    @Param('batchId') batchId: string,
    @Query() q: AttendanceRangeQuery,
  ) {
    return this.svc.forBatch(user, batchId, q);
  }

  @Get('students/:studentId')
  forStudent(
    @CurrentUser() user: AuthUser,
    @Param('studentId') studentId: string,
    @Query() q: AttendanceRangeQuery,
  ) {
    return this.svc.forStudent(user, studentId, q);
  }
}
