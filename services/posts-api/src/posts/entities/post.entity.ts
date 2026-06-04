import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('posts')
export class Post {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column('text')
  content: string;

  @Column()
  userId: string;

  @Column({ nullable: true })
  assetUrl: string;

  @CreateDateColumn()
  createdAt: Date;
}
