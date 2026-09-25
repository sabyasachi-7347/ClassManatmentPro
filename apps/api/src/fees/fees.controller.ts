import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthUser, Role } from '../auth/auth.types';
import { CurrentUser, Roles } from '../auth/decorators';
import { tenantOf } from '../common/tenant';
import { CreateFeeDto, GenerateFeesDto, ListFeesQuery, RecordPaymentDto } from './fees.dto';
import { FeesService } from './fees.service';

@ApiTags('fees')
@ApiBearerAuth()
@Controller('fees')
export class FeesController {
  constructor(private readonly svc: FeesService) {}

  @Get()
  list(@CurrentUser() user: AuthUser, @Query() q: ListFeesQuery) {
    return this.svc.list(user, q);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateFeeDto) {
    return this.svc.create(tenantOf(user), dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post('generate')
  generate(@CurrentUser() user: AuthUser, @Body() dto: GenerateFeesDto) {
    return this.svc.generate(tenantOf(user), dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post(':id/pay')
  pay(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: RecordPaymentDto) {
    return this.svc.recordPayment(user, id, dto);
  }

  @Roles(Role.Owner, Role.Admin)
  @Post(':id/waive')
  waive(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.svc.waive(tenantOf(user), id);
  }
}
