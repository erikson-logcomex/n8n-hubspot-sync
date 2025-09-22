# Deploy Script - n8n Cluster com Correções
# Data: 22/09/2025
# Correções aplicadas: DNS Redis + DB_TYPE PostgreSQL

Write-Host "🚀 Iniciando deploy do n8n cluster com correções..." -ForegroundColor Green

# 1. Aplicar patch do serviço Redis
Write-Host "📡 Aplicando correção do serviço Redis..." -ForegroundColor Yellow
kubectl patch svc redis-master -n n8n --patch-file redis-service-patch.yaml

# 2. Deploy do n8n principal
Write-Host "🔧 Deploy do n8n principal..." -ForegroundColor Yellow
kubectl apply -f n8n-deployment.yaml

# 3. Deploy dos workers
Write-Host "👷 Deploy dos workers..." -ForegroundColor Yellow
kubectl apply -f n8n-worker-deployment.yaml

# 4. Aguardar rollout
Write-Host "⏳ Aguardando rollout..." -ForegroundColor Yellow
kubectl rollout status deployment/n8n -n n8n
kubectl rollout status deployment/n8n-worker -n n8n

# 5. Verificar status
Write-Host "✅ Verificando status final..." -ForegroundColor Green
kubectl get pods -n n8n
kubectl get svc -n n8n

Write-Host "🎉 Deploy concluído com sucesso!" -ForegroundColor Green
Write-Host "🌐 Acesse: https://n8n-logcomex.34-8-101-220.nip.io" -ForegroundColor Cyan
