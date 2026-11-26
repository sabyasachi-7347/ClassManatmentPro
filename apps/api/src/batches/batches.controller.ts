import { Body, Controller, Get, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { tenantOf } from '../common/tenant';
import { CreateBatchDto, UpdateBatchDto, UpdateEnrollmentsDto, UpdateSyllabusDto } from './batches.dto';
import { BatchesService } from './batches.service';

@ApiTags('batches')
@ApiBearerAuth()
@Controller()
export class BatchesController {
  constructor(private readonly svc: BatchesService) {}

  @Get('batches')
  list(@CurrentUser() user: AuthUser, @Query('archived') archived?: string) {
    return this.svc.list(user, archived === 'true');
  }

  @Get('batches/:id')
  get(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.svc.get(user, id);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post('batches')
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateBatchDto) {
    return this.svc.create(tenantOf(user), dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Patch('batches/:id')
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateBatchDto) {
    return this.svc.update(tenantOf(user), id, dto);
  }

  /** Teachers log coverage here; staff can also restructure the chapter list. */
  @Roles(Role.Owner, Role.Admin, Role.Teacher)
  @Put('batches/:id/syllabus')
  syllabus(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateSyllabusDto) {
    return this.svc.updateSyllabus(user, id, dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Put('enrollments')
  enroll(@CurrentUser() user: AuthUser, @Body() dto: UpdateEnrollmentsDto) {
    return this.svc.updateEnrollments(tenantOf(user), dto);
  }
}
