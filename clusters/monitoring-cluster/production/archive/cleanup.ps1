Write-Host "🧹 LIMPEZA DO CLUSTER MONITORING-NEW" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Conectar ao cluster
Write-Host "📡 Conectando ao monitoring-cluster..." -ForegroundColor Yellow
gcloud container clusters get-credentials monitoring-cluster --zone southamerica-east1 --project datatoopenai

# Deletar recursos desnecessários
Write-Host "🗑️ Deletando Ingress duplicado..." -ForegroundColor Red
kubectl delete ingress monitoring-https-ingress -n monitoring-new

Write-Host "🗑️ Deletando certificado duplicado..." -ForegroundColor Red
kubectl delete managedcertificate monitoring-https-cert -n monitoring-new

Write-Host "🗑️ Deletando IP não utilizado..." -ForegroundColor Red
gcloud compute addresses delete monitoring-https-ip --global --quiet

Write-Host "✅ Limpeza concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 STATUS FINAL:" -ForegroundColor Cyan
kubectl get all -n monitoring-new
Write-Host ""
kubectl get ingress -n monitoring-new
Write-Host ""
kubectl get managedcertificate -n monitoring-new
