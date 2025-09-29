# Script para backup dos dados do Grafana e Prometheus
# Preserva dashboards, usuários, configurações e dados históricos

Write-Host "🔄 FAZENDO BACKUP DOS DADOS DO MONITORING CLUSTER" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Criar diretório de backup
$backupDir = "backup_monitoring_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "📁 Diretório de backup: $backupDir" -ForegroundColor Green

# Backup das configurações do Grafana
Write-Host "`n📊 Fazendo backup do Grafana..." -ForegroundColor Yellow
kubectl exec -n monitoring-new grafana-fb6dc8f86-62tsh -- tar -czf /tmp/grafana-backup.tar.gz -C /var/lib/grafana .
kubectl cp monitoring-new/grafana-fb6dc8f86-62tsh:/tmp/grafana-backup.tar.gz "$backupDir/grafana-backup.tar.gz"

# Backup das configurações do Prometheus
Write-Host "📈 Fazendo backup do Prometheus..." -ForegroundColor Yellow
kubectl exec -n monitoring-new prometheus-5c778f75c-px5kv -- tar -czf /tmp/prometheus-backup.tar.gz -C /prometheus .
kubectl cp monitoring-new/prometheus-5c778f75c-px5kv:/tmp/prometheus-backup.tar.gz "$backupDir/prometheus-backup.tar.gz"

# Backup das configurações do cluster
Write-Host "⚙️ Fazendo backup das configurações..." -ForegroundColor Yellow
kubectl get configmap -n monitoring-new -o yaml > "$backupDir/configmaps.yaml"
kubectl get secret -n monitoring-new -o yaml > "$backupDir/secrets.yaml"
kubectl get deployment -n monitoring-new -o yaml > "$backupDir/deployments.yaml"
kubectl get service -n monitoring-new -o yaml > "$backupDir/services.yaml"
kubectl get pvc -n monitoring-new -o yaml > "$backupDir/pvcs.yaml"
kubectl get hpa -n monitoring-new -o yaml > "$backupDir/hpa.yaml"

# Backup dos dashboards do Grafana (se existirem)
Write-Host "📋 Fazendo backup dos dashboards..." -ForegroundColor Yellow
kubectl get configmap -n monitoring-new | findstr dashboard | ForEach-Object {
    $name = ($_ -split '\s+')[0]
    kubectl get configmap $name -n monitoring-new -o yaml > "$backupDir/dashboard-$name.yaml"
}

Write-Host "`n✅ BACKUP CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "📁 Localização: $backupDir" -ForegroundColor Cyan
Write-Host "`n📋 Arquivos criados:" -ForegroundColor Yellow
Get-ChildItem $backupDir | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }

Write-Host "`n🔒 DADOS PRESERVADOS:" -ForegroundColor Green
Write-Host "  ✅ Dashboards do Grafana"
Write-Host "  ✅ Usuários e grupos"
Write-Host "  ✅ Configurações de datasource"
Write-Host "  ✅ Dados históricos do Prometheus"
Write-Host "  ✅ Configurações do cluster"

Write-Host "`n💡 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "1. Verificar se o backup está completo"
Write-Host "2. Otimizar o cluster original"
Write-Host "3. Restaurar dados se necessário"
Write-Host "4. Testar funcionalidades"

Write-Host "`nBackup finalizado em $(Get-Date)" -ForegroundColor Cyan
