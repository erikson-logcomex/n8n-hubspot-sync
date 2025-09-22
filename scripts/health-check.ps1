# Health Check Script - n8n Cluster
# Data: 22/09/2025
# Verifica saúde do cluster após correções

Write-Host "🔍 Verificando saúde do cluster n8n..." -ForegroundColor Green

# 1. Verificar pods
Write-Host "`n📦 Status dos Pods:" -ForegroundColor Yellow
kubectl get pods -n n8n

# 2. Verificar serviços
Write-Host "`n🌐 Status dos Serviços:" -ForegroundColor Yellow
kubectl get svc -n n8n

# 3. Verificar conectividade Redis
Write-Host "`n🔗 Testando conectividade Redis via DNS:" -ForegroundColor Yellow
kubectl run test-pod --image=busybox --rm -it --restart=Never -n n8n -- sh -c "echo 'test' | nc redis-master.n8n.svc.cluster.local 6379"

# 4. Verificar logs do n8n
Write-Host "`n📋 Logs do n8n (últimas 10 linhas):" -ForegroundColor Yellow
kubectl logs deployment/n8n -n n8n --tail=10

# 5. Verificar logs dos workers
Write-Host "`n👷 Logs dos workers (últimas 5 linhas):" -ForegroundColor Yellow
kubectl logs deployment/n8n-worker -n n8n --tail=5

# 6. Verificar resolução DNS
Write-Host "`n🌍 Testando resolução DNS:" -ForegroundColor Yellow
kubectl run test-pod --image=busybox --rm -it --restart=Never -n n8n -- sh -c "nslookup redis-master.n8n.svc.cluster.local"

# 7. Verificar ingress
Write-Host "`n🚪 Status do Ingress:" -ForegroundColor Yellow
kubectl get ingress -n n8n

Write-Host "`n✅ Verificação concluída!" -ForegroundColor Green
Write-Host "🌐 Acesse: https://n8n-logcomex.34-8-101-220.nip.io" -ForegroundColor Cyan
