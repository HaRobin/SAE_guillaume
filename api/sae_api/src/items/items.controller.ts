import { Controller, Get, Post, Body } from '@nestjs/common';
import { ItemsService } from './items.service';

@Controller('items')
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Get('images')
  findAllImages() {
    return this.itemsService.findAllImages();
  }

  @Post('images')
  createImage(@Body('device_id') device_id: string, @Body('path') path: string) {
    return this.itemsService.createImage(device_id, path);
  }

  @Post('recognitions')
  createRecognition(
    @Body('image_id') image_id: number,
    @Body('recognition') recognition: string,
    @Body('confidence') confidence: number,
  ) {
    return this.itemsService.createRecognition(image_id, recognition, confidence);
  }
}
