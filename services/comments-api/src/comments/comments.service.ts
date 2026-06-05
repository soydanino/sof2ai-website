import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Comment } from './entities/comment.entity';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommentsService {
  private readonly notificationsUrl: string;

  constructor(
    @InjectRepository(Comment)
    private readonly commentsRepository: Repository<Comment>,
    private readonly config: ConfigService,
  ) {
    this.notificationsUrl = config.get('NOTIFICATIONS_API_URL') ?? 'http://localhost:3004';
  }

  async create(dto: CreateCommentDto) {
    const comment = this.commentsRepository.create(dto);
    const saved = await this.commentsRepository.save(comment);

    try {
      await fetch(`${this.notificationsUrl}/notifications`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: saved.userId,
          type: 'COMMENT_CREATED',
          message: `New comment on post ${saved.postId}`,
        }),
      });
    } catch (e) {
      console.warn('Notification failed:', e.message);
    }

    return saved;
  }

  async findByPost(postId: string) {
    return this.commentsRepository.find({
      where: { postId },
      order: { createdAt: 'ASC' },
    });
  }

  async remove(id: string) {
    const comment = await this.commentsRepository.findOne({ where: { id } });
    if (!comment) throw new NotFoundException('Comment not found');
    await this.commentsRepository.remove(comment);
    return { message: 'Comment deleted' };
  }
}
