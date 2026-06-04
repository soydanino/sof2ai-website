# SOF2AI

Reddit-like platform with a microservices architecture deployed on AWS (EC2 → SQS → Lambda → S3).

## Architecture

```
Client
  │
  ├── users-api     :3001  (NestJS + PostgreSQL)
  ├── posts-api     :3002  (NestJS + PostgreSQL + S3 + SQS)
  ├── comments-api  :3003  (NestJS + PostgreSQL + SQS)
  └── notifications-api :3004  (NestJS + PostgreSQL + SQS polling)
                                         │
                                    SQS Queue
                                         │
                                   Lambda (validator)
```

## Prerequisites

- Docker + Docker Compose v2
- Node.js 20+
- AWS CLI v2 (for deployment)
- Terraform >= 1.6

## Local Development

### 1. Configure environment variables

Copy and fill in the env files for each service:

```bash
cp services/users-api/.env.example         services/users-api/.env
cp services/posts-api/.env.example         services/posts-api/.env
cp services/comments-api/.env.example      services/comments-api/.env
cp services/notifications-api/.env.example services/notifications-api/.env
```

Create a root `.env` for docker-compose AWS variables:

```bash
cat > .env <<EOF
JWT_SECRET=your_super_secret_jwt_key
AWS_REGION=us-east-1
SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/ACCOUNT_ID/sof2ai-events
S3_BUCKET_NAME=sof2ai-assets-ACCOUNT_ID
AWS_ACCESS_KEY_ID=your_key_id
AWS_SECRET_ACCESS_KEY=your_secret_key
EOF
```

### 2. Start everything

```bash
docker compose up --build
```

Services will be available at:
| Service | URL |
|---|---|
| users-api | http://localhost:3001 |
| posts-api | http://localhost:3002 |
| comments-api | http://localhost:3003 |
| notifications-api | http://localhost:3004 |

## API Reference

### users-api (:3001)

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | /users/register | `{name, email, password}` | Register user |
| POST | /users/login | `{email, password}` | Login, returns JWT |
| GET | /users/:id | — | Get user profile |
| PUT | /users/:id | `{name?, password?}` | Update profile |

### posts-api (:3002)

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | /posts | `{title, content, userId}` + optional `asset` file | Create post |
| GET | /posts | `?page=1&limit=10` | List posts (paginated) |
| GET | /posts/:id | — | Get post detail |
| DELETE | /posts/:id | — | Delete post |

### comments-api (:3003)

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | /comments | `{content, postId, userId}` | Create comment |
| GET | /comments/post/:postId | — | List comments for a post |
| DELETE | /comments/:id | — | Delete comment |

### notifications-api (:3004)

| Method | Path | Description |
|--------|------|-------------|
| GET | /notifications/:userId | List notifications for user |

## AWS Deployment

### 1. Provision infrastructure with Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

This creates: ECR repositories, S3 bucket, SQS queues, Lambda function, EC2 instance, IAM roles.

### 2. Build Docker images

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

### 3. Push images to ECR

```bash
chmod +x scripts/push-ecr.sh
./scripts/push-ecr.sh
```

### 4. Deploy on EC2

SSH into the EC2 instance and run docker-compose with production env vars:

```bash
EC2_IP=$(cd infra && terraform output -raw ec2_public_ip)
ssh ec2-user@$EC2_IP

# On the EC2 instance:
# Pull images from ECR, create .env, run docker-compose up -d
```

## SQS Event Schema

Events published to `sof2ai-events`:

```json
// POST_CREATED
{ "type": "POST_CREATED", "postId": "uuid", "userId": "uuid", "title": "...", "content": "..." }

// COMMENT_CREATED
{ "type": "COMMENT_CREATED", "commentId": "uuid", "postId": "uuid", "userId": "uuid", "content": "..." }
```

The Lambda validator checks all events for banned words: `["spam", "banned", "prohibited"]`.

## Project Structure

```
sof2ai/
├── services/
│   ├── users-api/          # NestJS, port 3001
│   ├── posts-api/          # NestJS, port 3002
│   ├── comments-api/       # NestJS, port 3003
│   └── notifications-api/  # NestJS, port 3004
├── validator/
│   └── index.js            # Lambda function (Node.js)
├── infra/                  # Terraform
│   ├── main.tf
│   ├── ecr.tf
│   ├── s3.tf
│   ├── sqs.tf
│   ├── lambda.tf
│   ├── ec2.tf
│   ├── iam.tf
│   └── outputs.tf
├── scripts/
│   ├── build.sh            # Build all Docker images
│   └── push-ecr.sh        # Push images to ECR
└── docker-compose.yml
```
