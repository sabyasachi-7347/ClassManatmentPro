import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsIn, IsOptional, IsString, Matches, ValidateNested } from 'class-validator';
import { ISO_DATE } from '../common/dates';

export const ATTENDANCE_STATUSES = ['present', 'absent', 'late', 'excused'] as const;
export type AttendanceStatus = (typeof ATTENDANCE_STATUSES)[number];

export class AttendanceRecordDto {
  @ApiProperty() @IsString() studentId: string;
  @ApiProperty({ enum: ATTENDANCE_STATUSES }) @IsIn(ATTENDANCE_STATUSES) status: AttendanceStatus;
}

export class MarkAttendanceDto {
  @ApiProperty({ type: [AttendanceRecordDto] })
  @IsArray() @ArrayMaxSize(500) @ValidateNested({ each: true }) @Type(() => AttendanceRecordDto)
  records: AttendanceRecordDto[];
  @ApiPropertyOptional() @IsOptional() @IsString() topic?: string;
}

export class AttendanceRangeQuery {
  @ApiPropertyOptional({ example: '2026-09-01' }) @IsOptional() @Matches(ISO_DATE) from?: string;
  @ApiPropertyOptional({ example: '2026-09-30' }) @IsOptional() @Matches(ISO_DATE) to?: string;
}
