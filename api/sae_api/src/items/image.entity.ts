import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { Recognition } from './recognition.entity';

@Entity()
export class Image {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  device_id: string;

  @Column()
  path: string;

  @OneToMany(() => Recognition, recognition => recognition.image)
  recognitions: Recognition[];
}

