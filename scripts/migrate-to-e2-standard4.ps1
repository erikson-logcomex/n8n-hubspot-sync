# Script de Migração para e2-standard-4
# Data: 25/09/2025
# Migra todos os recursos para o nó e2-standard-4

Write-Host "🚀 Iniciando migração para e2-standard-4..." -ForegroundColor Green
Write-Host "📊 Plano de recursos:" -ForegroundColor Yellow
Write-Host "   n8n: 2 réplicas × (250m CPU, 512Mi RAM)" -ForegroundColor Cyan
Write-Host "   Workers: 3 réplicas × (800m CPU, 3GB RAM)" -ForegroundColor Cyan
Write-Host "   Redis: 1 réplica × (200m CPU, 500Mi RAM)" -ForegroundColor Cyan
Write-Host "   Total: 3.1 vCPU + 10.5GB RAM" -ForegroundColor Green

# 1. Verificar status atual
Write-Host "`n📋 Status atual dos pods:" -ForegroundColor Yellow
kubectl get pods -n n8n -o wide

# 2. Verificar recursos do nó e2-standard-4
Write-Host "`n🔍 Verificando recursos do nó e2-standard-4:" -ForegroundColor Yellow
kubectl describe node gke-n8n-cluster-pool-cpu4-82e1bc53-c415 | Select-String "Allocatable|Capacity"

# 3. Aplicar configuração otimizada do Redis
Write-Host "`n📡 Aplicando configuração otimizada do Redis..." -ForegroundColor Yellow
kubectl apply -f redis-deployment-optimized.yaml

# 4. Aguardar Redis estar pronto
Write-Host "`n⏳ Aguardando Redis estar pronto..." -ForegroundColor Yellow
kubectl rollout status statefulset/redis-master -n n8n --timeout=300s

# 5. Aplicar configuração otimizada dos Workers
Write-Host "`n👷 Aplicando configuração otimizada dos Workers..." -ForegroundColor Yellow
kubectl apply -f n8n-worker-deployment-optimized.yaml

# 6. Aguardar Workers estarem prontos
Write-Host "`n⏳ Aguardando Workers estarem prontos..." -ForegroundColor Yellow
kubectl rollout status deployment/n8n-worker -n n8n --timeout=300s

# 7. Aplicar configuração otimizada do n8n principal
Write-Host "`n🔧 Aplicando configuração otimizada do n8n principal..." -ForegroundColor Yellow
kubectl apply -f n8n-deployment-optimized.yaml

# 8. Aguardar n8n principal estar pronto
Write-Host "`n⏳ Aguardando n8n principal estar pronto..." -ForegroundColor Yellow
kubectl rollout status deployment/n8n -n n8n --timeout=300s

# 9. Verificar status final
Write-Host "`n✅ Verificando status final:" -ForegroundColor Green
kubectl get pods -n n8n -o wide

# 10. Verificar recursos alocados
Write-Host "`n📊 Recursos alocados no nó e2-standard-4:" -ForegroundColor Yellow
kubectl describe node gke-n8n-cluster-pool-cpu4-82e1bc53-c415 | Select-String "Allocated resources" -A 10

# 11. Verificar uso de recursos
Write-Host "`n📈 Uso atual de recursos:" -ForegroundColor Yellow
kubectl top pods -n n8n

# 12. Verificar se não há mais OOM kills
Write-Host "`n🔍 Verificando eventos recentes (últimos 5 minutos):" -ForegroundColor Yellow
kubectl get events -n n8n --sort-by='.lastTimestamp' | Select-Object -Last 10

Write-Host "`n🎉 Migração concluída com sucesso!" -ForegroundColor Green
Write-Host "🌐 Acesse: https://n8n-logcomex.34-8-101-220.nip.io" -ForegroundColor Cyan
Write-Host "`n📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Monitorar logs por 10-15 minutos" -ForegroundColor White
Write-Host "   2. Verificar se não há mais OOM kills" -ForegroundColor White
Write-Host "   3. Testar execução de workflows" -ForegroundColor White
Write-Host "   4. Considerar desativar o nó e2-medium" -ForegroundColor White
