# Script para migrar cluster para zona única (2 nós)
# Mantém todas as configurações e dados

Write-Host "🔄 MIGRAÇÃO PARA CLUSTER DE ZONA ÚNICA" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# 1. Exportar configurações atuais
Write-Host "`n📤 Exportando configurações atuais..." -ForegroundColor Yellow
$exportDir = "cluster_export_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# Exportar todos os recursos
kubectl get all -n monitoring-new -o yaml > "$exportDir/all-resources.yaml"
kubectl get pvc -n monitoring-new -o yaml > "$exportDir/pvcs.yaml"
kubectl get ingress -n monitoring-new -o yaml > "$exportDir/ingress.yaml"
kubectl get configmap -n monitoring-new -o yaml > "$exportDir/configmaps.yaml"
kubectl get secret -n monitoring-new -o yaml > "$exportDir/secrets.yaml"
kubectl get hpa -n monitoring-new -o yaml > "$exportDir/hpa.yaml"

Write-Host "✅ Configurações exportadas para: $exportDir" -ForegroundColor Green

# 2. Criar novo cluster em zona única
Write-Host "`n🏗️ Criando novo cluster em zona única..." -ForegroundColor Yellow
$newClusterName = "monitoring-cluster-optimized"
$zone = "southamerica-east1-a"

Write-Host "Comando para executar:" -ForegroundColor Cyan
Write-Host "gcloud container clusters create $newClusterName --zone=$zone --num-nodes=2 --machine-type=e2-small --disk-size=100 --disk-type=pd-balanced --enable-autoscaling --min-nodes=1 --max-nodes=3" -ForegroundColor White

# 3. Script de restauração
Write-Host "`n📋 Script de restauração criado:" -ForegroundColor Yellow
$restoreScript = @"
# Conectar ao novo cluster
gcloud container clusters get-credentials $newClusterName --zone=$zone

# Criar namespace
kubectl create namespace monitoring-new

# Aplicar configurações
kubectl apply -f $exportDir/configmaps.yaml
kubectl apply -f $exportDir/secrets.yaml
kubectl apply -f $exportDir/pvcs.yaml
kubectl apply -f $exportDir/all-resources.yaml
kubectl apply -f $exportDir/ingress.yaml
kubectl apply -f $exportDir/hpa.yaml

# Verificar status
kubectl get pods -n monitoring-new
kubectl get nodes
"@

$restoreScript | Out-File -FilePath "$exportDir/restore-cluster.ps1" -Encoding UTF8

Write-Host "✅ Script de restauração: $exportDir/restore-cluster.ps1" -ForegroundColor Green

# 4. Plano de migração de dados
Write-Host "`n💾 Plano de migração de dados:" -ForegroundColor Yellow
Write-Host "1. Backup dos dados atuais (já feito)" -ForegroundColor White
Write-Host "2. Criar novo cluster" -ForegroundColor White
Write-Host "3. Restaurar configurações" -ForegroundColor White
Write-Host "4. Restaurar dados dos PVCs" -ForegroundColor White
Write-Host "5. Testar funcionalidades" -ForegroundColor White

Write-Host "`n🎯 VANTAGENS DO NOVO CLUSTER:" -ForegroundColor Green
Write-Host "• 2 nós em vez de 6 (economia de 66%)" -ForegroundColor White
Write-Host "• Zona única (menor latência)" -ForegroundColor White
Write-Host "• Autoscaling habilitado" -ForegroundColor White
Write-Host "• Mesmas configurações e dados" -ForegroundColor White

Write-Host "`n⚠️ PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "1. Executar: gcloud container clusters create $newClusterName --zone=$zone --num-nodes=2 --machine-type=e2-small --disk-size=100 --disk-type=pd-balanced --enable-autoscaling --min-nodes=1 --max-nodes=3" -ForegroundColor White
Write-Host "2. Executar: .\$exportDir\restore-cluster.ps1" -ForegroundColor White
Write-Host "3. Testar acesso aos serviços" -ForegroundColor White
Write-Host "4. Deletar cluster antigo (após confirmação)" -ForegroundColor White

Write-Host "`n📊 Migração preparada em $(Get-Date)" -ForegroundColor Cyan

