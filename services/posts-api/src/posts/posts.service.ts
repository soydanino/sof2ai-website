import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { Post } from './entities/post.entity';
import { CreatePostDto } from './dto/create-post.dto';

@Injectable()
export class PostsService {
  private readonly s3: S3Client;
  private readonly notificationsUrl: string;

  constructor(
    @InjectRepository(Post)
    private readonly postsRepository: Repository<Post>,
    private readonly config: ConfigService,
  ) {
    this.s3 = new S3Client({ region: config.get('AWS_REGION') });
    this.notificationsUrl = config.get('NOTIFICATIONS_API_URL') ?? 'http://localhost:3004';
  }

  async create(dto: CreatePostDto, file?: Express.Multer.File) {
    let assetUrl: string | undefined;

    if (file) {
      const key = `posts/${Date.now()}-${file.originalname}`;
      const bucket = this.config.get('S3_BUCKET_NAME');
      const region = this.config.get('AWS_REGION');

      await this.s3.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: key,
          Body: file.buffer,
          ContentType: file.mimetype,
        }),
      );
      assetUrl = `https://${bucket}.s3.${region}.amazonaws.com/${key}`;
    }

    const post = this.postsRepository.create({ ...dto, assetUrl });
    const saved = await this.postsRepository.save(post);

    try {
      await fetch(`${this.notificationsUrl}/notifications`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: saved.userId,
          type: 'POST_CREATED',
          message: `New post created: "${saved.title}"`,
        }),
      });
    } catch (e) {
      console.warn('Notification failed:', e.message);
    }

    return saved;
  }

  async findAll(page = 1, limit = 10) {
    const [posts, total] = await this.postsRepository.findAndCount({
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { posts, total, page, limit };
  }

  async findOne(id: string) {
    const post = await this.postsRepository.findOne({ where: { id } });
    if (!post) throw new NotFoundException('Post not found');
    return post;
  }

  async remove(id: string) {
    const post = await this.postsRepository.findOne({ where: { id } });
    if (!post) throw new NotFoundException('Post not found');
    await this.postsRepository.remove(post);
    return { message: 'Post deleted' };
  }
}
