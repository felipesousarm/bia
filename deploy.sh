#!/bin/bash

./build.sh

# Descobre a última revisão da Task Definition
TASK_DEFINITION=$(aws ecs list-task-definitions \
  --family-prefix tark-def-bia-alb \
  --status ACTIVE \
  --sort DESC \
  --max-items 1 \
  --query 'taskDefinitionArns[0]' \
  --output text \
  --profile formacao)

echo "Task Definition encontrada:"
echo "$TASK_DEFINITION"

# Atualiza o ECS usando a última revisão
aws ecs update-service \
  --cluster cluster-bia-alb \
  --service service-bia-alb \
  --force-new-deployment \
  --profile formacao

cd client

./build_front.sh
