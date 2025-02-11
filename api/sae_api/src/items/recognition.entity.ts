import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Image } from './image.entity';

@Entity()
export class Recognition {
  @PrimaryGeneratedColumn()
  id?: number; 

  @Column()
  recognition: string;

  @Column('float')
  confidence: number;

  @ManyToOne(() => Image, image => image.recognitions)
  @JoinColumn({ name: 'image_id' })
  image: Image;

  @Column()
  image_id: number;
}
