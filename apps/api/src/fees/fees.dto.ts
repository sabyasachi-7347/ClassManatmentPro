import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsInt, IsOptional, IsString, Length, Matches, Min } from 'class-validator';
import { ISO_DATE, ISO_MONTH } from '../common/dates';

export const FEE_STATUSES = ['due', 'paid', 'waived'] as const;
export const PAYMENT_METHODS = ['cash', 'upi', 'card', 'bank', 'other'] as const;

export class CreateFeeDto {
  @ApiProperty() @IsString() studentId: string;
  @ApiProperty({ description: 'Whole currency units' }) @IsInt() @Min(1) amount: number;
  @ApiProperty({ example: '2026-10-05' }) @Matches(ISO_DATE) dueDate: string;
  @ApiPropertyOptional({ example: '2026-10' }) @IsOptional() @Matches(ISO_MONTH) period?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 200) note?: string;
}

export class GenerateFeesDto {
  @ApiProperty({ example: '2026-10' }) @Matches(ISO_MONTH) period: string;
  @ApiProperty({ example: '2026-10-05' }) @Matches(ISO_DATE) dueDate: string;
}

export class RecordPaymentDto {
  @ApiProperty({ enum: PAYMENT_METHODS }) @IsIn(PAYMENT_METHODS) method: (typeof PAYMENT_METHODS)[number];
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 80) reference?: string;
  @ApiPropertyOptional() @IsOptional() @Matches(ISO_DATE) paidOn?: string;
}

export class ListFeesQuery {
  @ApiPropertyOptional({ enum: FEE_STATUSES }) @IsOptional() @IsIn(FEE_STATUSES) status?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() studentId?: string;
  @ApiPropertyOptional() @IsOptional() @Matches(ISO_MONTH) period?: string;
}
