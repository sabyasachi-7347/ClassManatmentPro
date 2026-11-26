import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

const HHMM = /^([01]\d|2[0-3]):[0-5]\d$/;

export class ScheduleSlotDto {
  @ApiProperty({ description: '0 = Sunday … 6 = Saturday' }) @IsInt() @Min(0) @Max(6) day: number;
  @ApiProperty({ example: '17:00' }) @Matches(HHMM) start: string;
  @ApiProperty({ example: '18:30' }) @Matches(HHMM) end: string;
}

export const CHAPTER_STATUSES = ['todo', 'current', 'done'] as const;

export class SyllabusChapterDto {
  @ApiProperty() @IsString() @Length(1, 120) title: string;
  @ApiProperty({ enum: CHAPTER_STATUSES }) @IsIn(CHAPTER_STATUSES) status: (typeof CHAPTER_STATUSES)[number];
}

export class UpdateSyllabusDto {
  @ApiProperty({ type: [SyllabusChapterDto] })
  @IsArray() @ArrayMaxSize(200) @ValidateNested({ each: true }) @Type(() => SyllabusChapterDto)
  chapters: SyllabusChapterDto[];
}

export class CreateBatchDto {
  @ApiProperty() @IsString() @Length(1, 80) name: string;
  @ApiProperty() @IsString() @Length(1, 80) subject: string;
  @ApiPropertyOptional({ type: [String] })
  @IsOptional() @IsArray() @ArrayMaxSize(10) @IsString({ each: true })
  teacherIds?: string[];
  @ApiPropertyOptional({ type: [ScheduleSlotDto] })
  @IsOptional() @IsArray() @ArrayMaxSize(14) @ValidateNested({ each: true }) @Type(() => ScheduleSlotDto)
  schedule?: ScheduleSlotDto[];
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 40) room?: string;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(1) @Max(1000) capacity?: number;
  @ApiPropertyOptional({ description: 'Monthly fee for this batch' })
  @IsOptional() @IsInt() @Min(0) monthlyFee?: number;
  @ApiPropertyOptional({ type: [SyllabusChapterDto] })
  @IsOptional() @IsArray() @ArrayMaxSize(200) @ValidateNested({ each: true }) @Type(() => SyllabusChapterDto)
  syllabus?: SyllabusChapterDto[];
}

export class UpdateBatchDto extends PartialType(CreateBatchDto) {
  @ApiPropertyOptional() @IsOptional() @IsBoolean() archived?: boolean;
}

export class EnrollmentChangeDto {
  @ApiProperty() @IsString() studentId: string;
  @ApiProperty() @IsString() batchId: string;
  @ApiProperty() @IsBoolean() enrolled: boolean;
}

export class UpdateEnrollmentsDto {
  @ApiProperty({ type: [EnrollmentChangeDto] })
  @IsArray() @ArrayMaxSize(450) @ValidateNested({ each: true }) @Type(() => EnrollmentChangeDto)
  changes: EnrollmentChangeDto[];
}
