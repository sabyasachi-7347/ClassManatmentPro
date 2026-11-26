import { Body, Controller, Get, Param, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { CreateTestDto, EnterMarksDto } from './tests.dto';
import { TestsService } from './tests.service';

@ApiTags('tests')
@ApiBearerAuth()
@Controller()
export class TestsController {
  constructor(private readonly svc: TestsService) {}

  @ApiQuery({ name: 'batchId', required: false })
  @Get('tests')
  list(@CurrentUser() user: AuthUser, @Query('batchId') batchId?: string) {
    return this.svc.list(user, batchId);
  }

  @Roles(Role.Owner, Role.Admin, Role.Teacher)
  @Post('tests')
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateTestDto) {
    return this.svc.create(user, dto);
  }

  @Get('tests/:id')
  get(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.svc.get(user, id);
  }

  @Roles(Role.Owner, Role.Admin, Role.Teacher)
  @Put('tests/:id/marks')
  marks(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: EnterMarksDto) {
    return this.svc.enterMarks(user, id, dto);
  }

  @Get('students/:studentId/results')
  results(@CurrentUser() user: AuthUser, @Param('studentId') studentId: string) {
    return this.svc.resultsFor(user, studentId);
  }
}
