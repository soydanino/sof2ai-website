'use strict';

const BANNED_WORDS = ['spam', 'banned', 'prohibited'];

function containsBannedWords(text) {
  if (!text) return false;
  const lower = text.toLowerCase();
  return BANNED_WORDS.some((word) => lower.includes(word));
}

exports.handler = async (event) => {
  const results = [];

  for (const record of event.Records) {
    let body;
    try {
      body = JSON.parse(record.body);
    } catch {
      console.log('Invalid JSON in SQS message', record.body);
      continue;
    }

    const { type, postId, commentId, userId, title, content } = body;
    const textToCheck = [title, content].filter(Boolean).join(' ');

    if (containsBannedWords(textToCheck)) {
      console.log(
        JSON.stringify({
          level: 'WARN',
          message: 'Content contains banned words',
          type,
          postId: postId || null,
          commentId: commentId || null,
          userId,
          offendingText: textToCheck,
        }),
      );
    } else {
      console.log(
        JSON.stringify({
          level: 'INFO',
          message: 'Content validated successfully',
          type,
          postId: postId || null,
          commentId: commentId || null,
        }),
      );
    }

    results.push({ messageId: record.messageId, status: 'processed' });
  }

  return { batchItemFailures: [] };
};
