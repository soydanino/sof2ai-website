import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';
import { Comment } from './entities/comment.entity';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommentsService {
  private readonly sqs: SQSClient;

  constructor(
    @InjectRepository(Comment)
    private readonly commentsRepository: Repository<Comment>,
    private readonly config: ConfigService,
  ) {
    this.sqs = new SQSClient({ region: config.get('AWS_REGION') });
  }

  async create(dto: CreateCommentDto) {
    const comment = this.commentsRepository.create(dto);
    const saved = await this.commentsRepository.save(comment);

    await this.sqs.send(
      new SendMessageCommand({
        QueueUrl: this.config.get('SQS_QUEUE_URL'),
        MessageBody: JSON.stringify({
          type: 'COMMENT_CREATED',
          commentId: saved.id,
          postId: saved.postId,
          userId: saved.userId,
          content: saved.content,
        }),
      }),
    );

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
