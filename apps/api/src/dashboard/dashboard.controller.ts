import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators';
import { ISO_DATE } from '../common/dates';
import { DashboardService } from './dashboard.service';

@ApiTags('dashboard')
@ApiBearerAuth()
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly svc: DashboardService) {}

  /** Role-aware summary. Pass the client's local `date` so "today" matches the user's timezone. */
  @ApiQuery({ name: 'date', required: false, example: '2026-09-25' })
  @Get()
  get(@CurrentUser() user: AuthUser, @Query('date') date?: string) {
    if (date && !ISO_DATE.test(date)) throw new BadRequestException('date must be YYYY-MM-DD');
    return this.svc.get(user, date);
  }
}
