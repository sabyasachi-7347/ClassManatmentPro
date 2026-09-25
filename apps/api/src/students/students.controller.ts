import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { tenantOf } from '../common/tenant';
import { CreateStudentDto, UpdateStudentDto } from './students.dto';
import { StudentsService } from './students.service';

@ApiTags('students')
@ApiBearerAuth()
@Controller('students')
export class StudentsController {
  constructor(private readonly svc: StudentsService) {}

  @ApiQuery({ name: 'batchId', required: false })
  @Get()
  list(@CurrentUser() user: AuthUser, @Query('batchId') batchId?: string) {
    return this.svc.list(user, batchId);
  }

  @Get(':id')
  get(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.svc.get(user, id);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateStudentDto) {
    return this.svc.create(tenantOf(user), dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Patch(':id')
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateStudentDto) {
    return this.svc.update(tenantOf(user), id, dto);
  }
}
