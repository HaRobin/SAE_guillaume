import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Image } from './image.entity';
import { Recognition } from './recognition.entity';

@Injectable()
export class ItemsService {
  constructor(
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @InjectRepository(Recognition)
    private readonly recognitionRepository: Repository<Recognition>,
  ) {}

  findAllImages(): Promise<Image[]> {
    return this.imageRepository.find({ relations: ['recognitions'] });
  }

  createImage(device_id: string, path: string): Promise<Image> {
    const image = new Image();
    image.device_id = device_id;
    image.path = path;
    return this.imageRepository.save(image);
  }

  createRecognition(image_id: number, recognition: string, confidence: number): Promise<Recognition> {
    const recognitionEntity = new Recognition();
    recognitionEntity.image_id = image_id;
    recognitionEntity.recognition = recognition;
    recognitionEntity.confidence = confidence;
    return this.recognitionRepository.save(recognitionEntity);
  }

  findRecognitionsByImageId(image_id: number): Promise<Recognition[]> {
    return this.recognitionRepository.find({ where: { image_id } });
  }

  findImagesByDeviceId(device_id: string): Promise<Image[]>{
    return this.imageRepository.find({ where: { device_id } })
  }
}
