import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsIn, IsOptional, IsString, Matches } from 'class-validator';
import { ISO_DATE } from '../common/dates';

export const ABSENCE_STATES = ['waiting', 'acknowledged', 'silent'] as const;

export class ListAbsencesQuery {
  @ApiPropertyOptional({ description: 'Defaults to today for staff', example: '2026-09-25' })
  @IsOptional() @Matches(ISO_DATE) date?: string;
  @ApiPropertyOptional({ description: 'Parents/students only: history start' })
  @IsOptional() @Matches(ISO_DATE) from?: string;
  @ApiPropertyOptional({ enum: ABSENCE_STATES }) @IsOptional() @IsIn(ABSENCE_STATES) state?: string;
}

export class NudgeDto {
  @ApiPropertyOptional({ type: [String], description: 'Absence ids; omit to nudge every unacknowledged absence for the date' })
  @IsOptional() @IsArray() @ArrayMaxSize(200) @IsString({ each: true }) ids?: string[];
  @ApiPropertyOptional() @IsOptional() @Matches(ISO_DATE) date?: string;
}

export class RegisterDeviceDto {
  @ApiProperty() @IsString() token: string;
}
