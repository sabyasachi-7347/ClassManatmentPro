import { Module } from '@nestjs/common';
import { BatchesModule } from '../batches/batches.module';
import { StudentsModule } from '../students/students.module';
import { TestsController } from './tests.controller';
import { TestsService } from './tests.service';

@Module({
  imports: [BatchesModule, StudentsModule],
  controllers: [TestsController],
  providers: [TestsService],
})
export class TestsModule {}
