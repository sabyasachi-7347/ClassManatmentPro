import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

export const STUDENT_STATUSES = ['active', 'inactive'] as const;

export class CreateStudentDto {
  @ApiProperty() @IsString() @Length(1, 120) name: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 20) phone?: string;
  @ApiPropertyOptional() @IsOptional() @IsEmail() email?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 120) guardianName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 20) guardianPhone?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 40) grade?: string;
  @ApiPropertyOptional({ type: [String] })
  @IsOptional() @IsArray() @ArrayMaxSize(20) @IsString({ each: true })
  batchIds?: string[];
}

export class UpdateStudentDto extends PartialType(CreateStudentDto) {
  @ApiPropertyOptional({ enum: STUDENT_STATUSES })
  @IsOptional() @IsIn(STUDENT_STATUSES)
  status?: (typeof STUDENT_STATUSES)[number];
}
