import { Module } from '@nestjs/common';
import { AttendanceModule } from '../attendance/attendance.module';
import { BatchesModule } from '../batches/batches.module';
import { FeesModule } from '../fees/fees.module';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';

@Module({
  imports: [BatchesModule, AttendanceModule, FeesModule],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}
