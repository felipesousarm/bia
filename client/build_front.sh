#!/bin/bash

set -e

##############################################
# GARANTE EXECUÇÃO A PARTIR DA PASTA CLIENT
##############################################

cd "$(dirname "$0")"

##############################################
# CONFIGURAÇÕES
##############################################

APP_NAME="bia-frontend"
BUCKET_NAME="front-bia"
AWS_REGION="us-east-1"
BUILD_DIR="build"

# URL da API / Backend
API_URL=$(grep 'VITE_API_URL=' ../Dockerfile | sed -E 's/.*VITE_API_URL=([^ ]+).*/\1/')

# Perfil AWS SSO
AWS_PROFILE="formacao"

# Caso utilize CloudFront, informe o ID da distribuição.
# Se não utilizar, deixe vazio.
CLOUDFRONT_ID=""

##############################################

echo "=========================================="
echo "Deploy do $APP_NAME"
echo "=========================================="

echo ""
echo "[1/7] Verificando dependências..."

command -v node >/dev/null || {
    echo "❌ Node.js não instalado."
    exit 1
}

command -v npm >/dev/null || {
    echo "❌ NPM não instalado."
    exit 1
}

command -v aws >/dev/null || {
    echo "❌ AWS CLI não instalada."
    exit 1
}

echo "✔ Dependências OK"

echo ""
echo "[2/7] Verificando autenticação AWS..."

aws sts get-caller-identity \
    --profile "$AWS_PROFILE" >/dev/null || {

    echo "❌ Você não está autenticado."
    echo ""
    echo "Execute:"
    echo "aws sso login --profile $AWS_PROFILE"
    exit 1
}

echo "✔ Autenticação OK"

echo ""
echo "[3/7] Verificando acesso ao bucket..."

aws s3 ls "s3://$BUCKET_NAME" \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" >/dev/null || {

    echo "❌ Não foi possível acessar o bucket '$BUCKET_NAME'."
    exit 1
}

echo "✔ Bucket encontrado"

echo ""
echo "[4/7] Instalando dependências..."

npm install

echo ""
echo "[5/7] Gerando build..."

echo "API configurada: $API_URL"

VITE_API_URL="$API_URL" npm run build

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ A pasta '$BUILD_DIR' não foi gerada."
    exit 1
fi

echo "✔ Build gerada com sucesso"

echo ""
echo "[6/7] Enviando arquivos para o S3..."

aws s3 sync "$BUILD_DIR/" "s3://$BUCKET_NAME" \
    --delete \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE"

echo "✔ Arquivos enviados para o bucket"

if [ -n "$CLOUDFRONT_ID" ]; then

    echo ""
    echo "[7/7] Invalidando cache do CloudFront..."

    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_ID" \
        --paths "/*" \
        --profile "$AWS_PROFILE"

    echo "✔ Cache invalidado"

else

    echo ""
    echo "[7/7] CloudFront não configurado."
    echo "✔ Nenhuma invalidação necessária."

fi

echo ""
echo "=========================================="
echo "✅ Deploy realizado com sucesso!"
echo "Bucket : $BUCKET_NAME"
echo "Região : $AWS_REGION"
echo "API    : $API_URL"
echo "Perfil : $AWS_PROFILE"
echo "Pasta  : $(pwd)"
echo "=========================================="
