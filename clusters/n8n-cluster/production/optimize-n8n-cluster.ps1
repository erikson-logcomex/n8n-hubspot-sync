Write-Host "🚀 Iniciando otimização do cluster N8N..." -ForegroundColor Green

# 1. Reduzir número de nós do cluster (de 3 para 1)
Write-Host "📉 Reduzindo número de nós do cluster..." -ForegroundColor Yellow
gcloud container node-pools resize n8n-cluster-default-pool --cluster=n8n-cluster --zone=southamerica-east1-a --num-nodes=1 --quiet

# 2. Ajustar recursos do N8N principal (2 réplicas, 250m CPU, 512Mi RAM cada)
Write-Host "⚙️ Ajustando recursos do N8N principal..." -ForegroundColor Yellow
kubectl patch deployment n8n -n n8n -p '{"spec":{"replicas":2,"template":{"spec":{"containers":[{"name":"n8n","resources":{"requests":{"cpu":"250m","memory":"512Mi"},"limits":{"cpu":"250m","memory":"512Mi"}}}]}}}}'

# 3. Ajustar recursos dos N8N workers (3 réplicas, 800m CPU, 3Gi RAM cada)
Write-Host "⚙️ Ajustando recursos dos N8N workers..." -ForegroundColor Yellow
kubectl patch deployment n8n-worker -n n8n -p '{"spec":{"replicas":3,"template":{"spec":{"containers":[{"name":"worker","resources":{"requests":{"cpu":"800m","memory":"3Gi"},"limits":{"cpu":"800m","memory":"3Gi"}}}]}}}}'

# 4. Verificar status dos deployments
Write-Host "✅ Verificando status dos deployments..." -ForegroundColor Green
kubectl get deployments -n n8n

Write-Host "✅ Verificando pods..." -ForegroundColor Green
kubectl get pods -n n8n

Write-Host "✅ Verificando recursos dos nós..." -ForegroundColor Green
kubectl top nodes

Write-Host "`n🎉 Otimização concluída!" -ForegroundColor Green
Write-Host "📊 Resumo da configuração:" -ForegroundColor Cyan
Write-Host "   - N8N Principal: 2 réplicas (0.5 vCPU + 1GB RAM)" -ForegroundColor White
Write-Host "   - N8N Workers: 3 réplicas (2.4 vCPU + 9GB RAM)" -ForegroundColor White
Write-Host "   - Redis: 1 réplica (~0.2 vCPU + 0.5GB RAM)" -ForegroundColor White
Write-Host "   - Total: ~3.1 vCPU + 10.5GB RAM" -ForegroundColor White
Write-Host "   - Nós do cluster: 1 (otimizado)" -ForegroundColor White


