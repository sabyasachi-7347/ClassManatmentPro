import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AbsencesModule } from './absences/absences.module';
import { AnnouncementsModule } from './announcements/announcements.module';
import { AttendanceModule } from './attendance/attendance.module';
import { AuthModule } from './auth/auth.module';
import { BatchesModule } from './batches/batches.module';
import configuration from './config/configuration';
import { DashboardModule } from './dashboard/dashboard.module';
import { FeesModule } from './fees/fees.module';
import { FirebaseModule } from './firebase/firebase.module';
import { HealthController } from './health.controller';
import { InstitutesModule } from './institutes/institutes.module';
import { PushModule } from './push/push.module';
import { StudentsModule } from './students/students.module';
import { TestsModule } from './tests/tests.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    FirebaseModule,
    PushModule,
    AuthModule,
    InstitutesModule,
    BatchesModule,
    StudentsModule,
    AttendanceModule,
    FeesModule,
    AnnouncementsModule,
    DashboardModule,
    AbsencesModule,
    TestsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
