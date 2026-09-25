import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';
import { Role } from '../auth/auth.types';

export class CreateInstituteDto {
  @ApiProperty() @IsString() @Length(2, 120) name: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 80) city?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 20) phone?: string;
}

const INVITABLE_ROLES = [Role.Admin, Role.Teacher, Role.Student, Role.Parent];

export class InviteMemberDto {
  @ApiProperty() @IsEmail() email: string;
  @ApiProperty() @IsString() @Length(1, 120) name: string;
  @ApiProperty({ enum: INVITABLE_ROLES }) @IsIn(INVITABLE_ROLES) role: Role;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(0, 20) phone?: string;
  @ApiPropertyOptional({ description: 'Student records this student/parent account can see' })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  studentIds?: string[];
}

export class UpdateMemberDto {
  @ApiPropertyOptional({ enum: INVITABLE_ROLES }) @IsOptional() @IsIn(INVITABLE_ROLES) role?: Role;
  @ApiPropertyOptional() @IsOptional() @IsArray() @ArrayMaxSize(10) @IsString({ each: true })
  studentIds?: string[];
}
