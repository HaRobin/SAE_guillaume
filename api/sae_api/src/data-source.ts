import { DataSource } from 'typeorm';
import { Image } from './items/image.entity'; // Adjust path if necessary
import { Recognition } from './items/recognition.entity'; // Adjust path if necessary

export const AppDataSource = new DataSource({
  type: 'mariadb',
  host: '127.0.0.1',
  port: 3306,
  username: 'saeuser',
  password: 'SAEpassword*',
  database: 'sae_bdd',
  entities: [Image, Recognition], 
  synchronize: false,  
  logging: true,
});
