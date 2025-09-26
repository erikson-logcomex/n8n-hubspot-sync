# Script para corrigir o cluster de monitoring HTTPS
# Execute este script para aplicar as correções

Write-Host "🔧 Iniciando correção do cluster de monitoring..." -ForegroundColor Green

# 1. Primeiro, vamos limpar as configurações conflitantes
Write-Host "🧹 Removendo configurações conflitantes..." -ForegroundColor Yellow
kubectl delete ingress monitoring-https-ingress -n monitoring-new --ignore-not-found=true
kubectl delete managedcertificate monitoring-https-cert -n monitoring-new --ignore-not-found=true

# 2. Aplicar os serviços corrigidos (ClusterIP)
Write-Host "📡 Aplicando serviços corrigidos..." -ForegroundColor Yellow
kubectl apply -f monitoring-services-fixed.yaml

# 3. Aguardar os serviços estarem prontos
Write-Host "⏳ Aguardando serviços estarem prontos..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 4. Aplicar a configuração HTTPS corrigida
Write-Host "🔒 Aplicando configuração HTTPS corrigida..." -ForegroundColor Yellow
kubectl apply -f monitoring-https-fixed.yaml

# 5. Verificar status dos recursos
Write-Host "✅ Verificando status dos recursos..." -ForegroundColor Green
Write-Host "`n📊 Status dos Serviços:" -ForegroundColor Cyan
kubectl get services -n monitoring-new

Write-Host "`n🔒 Status do Certificado:" -ForegroundColor Cyan
kubectl get managedcertificate -n monitoring-new

Write-Host "`n🌐 Status do Ingress:" -ForegroundColor Cyan
kubectl get ingress -n monitoring-new

Write-Host "`n🎯 Status dos Pods:" -ForegroundColor Cyan
kubectl get pods -n monitoring-new

# 6. Verificar se o certificado está sendo provisionado
Write-Host "`n🔍 Verificando provisionamento do certificado..." -ForegroundColor Cyan
kubectl describe managedcertificate monitoring-ssl-cert -n monitoring-new

Write-Host "`n✨ Correção concluída! Aguarde alguns minutos para o certificado ser provisionado." -ForegroundColor Green
Write-Host "🌐 URLs de acesso:" -ForegroundColor Cyan
Write-Host "   Prometheus: https://prometheus-logcomex.35-198-21-170.nip.io" -ForegroundColor White
Write-Host "   Grafana: https://grafana-logcomex.34-95-167-174.nip.io" -ForegroundColor White
