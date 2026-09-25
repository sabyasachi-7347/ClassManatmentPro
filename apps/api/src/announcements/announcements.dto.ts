import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsOptional, IsString, Length } from 'class-validator';

export class CreateAnnouncementDto {
  @ApiProperty() @IsString() @Length(1, 120) title: string;
  @ApiProperty() @IsString() @Length(1, 4000) body: string;
  @ApiPropertyOptional({ description: 'Empty = whole institute' })
  @IsOptional() @IsArray() @ArrayMaxSize(30) @IsString({ each: true })
  batchIds?: string[];
}
