import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { ISO_DATE } from '../common/dates';

export class CreateTestDto {
  @ApiProperty() @IsString() batchId: string;
  @ApiProperty({ example: 'Weekly Test 14 — Physics' }) @IsString() @Length(1, 120) title: string;
  @ApiProperty({ example: 80 }) @IsInt() @Min(1) @Max(1000) maxMarks: number;
  @ApiProperty({ example: '2026-08-05' }) @Matches(ISO_DATE) date: string;
}

export class MarkEntryDto {
  @ApiProperty() @IsString() studentId: string;
  @ApiPropertyOptional({ description: 'null clears the mark (absent from test)', nullable: true })
  @IsOptional() @IsNumber() @Min(0) score?: number | null;
  @ApiPropertyOptional({ description: 'Shown to the parent next to the mark' })
  @IsOptional() @IsString() @Length(0, 300) note?: string;
}

export class EnterMarksDto {
  @ApiProperty({ type: [MarkEntryDto] })
  @IsArray() @ArrayMaxSize(500) @ValidateNested({ each: true }) @Type(() => MarkEntryDto)
  marks: MarkEntryDto[];
}
