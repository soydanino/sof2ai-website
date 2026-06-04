import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import {
  SQSClient,
  ReceiveMessageCommand,
  DeleteMessageCommand,
} from '@aws-sdk/client-sqs';
import { NotificationsService } from './notifications.service';

@Injectable()
export class SqsConsumer {
  private readonly logger = new Logger(SqsConsumer.name);
  private readonly sqs: SQSClient;
  private readonly queueUrl: string;

  constructor(
    private readonly config: ConfigService,
    private readonly notificationsService: NotificationsService,
  ) {
    this.sqs = new SQSClient({ region: config.get('AWS_REGION') });
    this.queueUrl = config.get('SQS_QUEUE_URL');
  }

  @Cron(CronExpression.EVERY_5_SECONDS)
  async pollMessages() {
    try {
      const response = await this.sqs.send(
        new ReceiveMessageCommand({
          QueueUrl: this.queueUrl,
          MaxNumberOfMessages: 10,
          WaitTimeSeconds: 0,
        }),
      );

      if (!response.Messages || response.Messages.length === 0) return;

      for (const message of response.Messages) {
        await this.processMessage(message);

        await this.sqs.send(
          new DeleteMessageCommand({
            QueueUrl: this.queueUrl,
            ReceiptHandle: message.ReceiptHandle,
          }),
        );
      }
    } catch (err) {
      this.logger.error('SQS poll error', err);
    }
  }

  private async processMessage(message: any) {
    try {
      const body = JSON.parse(message.Body);

      if (body.type === 'POST_CREATED') {
        await this.notificationsService.create(
          body.userId,
          'POST_CREATED',
          `New post created: "${body.title}"`,
        );
      } else if (body.type === 'COMMENT_CREATED') {
        await this.notificationsService.create(
          body.userId,
          'COMMENT_CREATED',
          `New comment on post ${body.postId}`,
        );
      }
    } catch (err) {
      this.logger.error('Failed to process SQS message', err);
    }
  }
}
