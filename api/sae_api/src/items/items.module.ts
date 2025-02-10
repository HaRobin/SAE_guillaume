import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ItemsService } from './items.service';
import { ItemsController } from './items.controller';
import { Image } from './image.entity';
import { Recognition } from './recognition.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Image, Recognition])],
  providers: [ItemsService],
  controllers: [ItemsController],
})
export class ItemsModule {}
