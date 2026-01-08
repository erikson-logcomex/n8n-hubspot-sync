# Script para exportar configuração atual do GCP para comparação
# Uso: .\scripts\export-gcp-config.ps1

$namespace = "n8n"
$exportDir = "exports/gcp-config-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "📦 Exportando configuração do namespace '$namespace'..." -ForegroundColor Cyan

# Criar diretório de exportação
New-Item -ItemType Directory -Force -Path $exportDir | Out-Null
Write-Host "📁 Diretório criado: $exportDir" -ForegroundColor Green

# Exportar Deployments
Write-Host "🚀 Exportando Deployments..." -ForegroundColor Yellow
kubectl get deployments -n $namespace -o yaml | Out-File -FilePath "$exportDir/deployments.yaml" -Encoding UTF8

# Exportar Services
Write-Host "🔌 Exportando Services..." -ForegroundColor Yellow
kubectl get services -n $namespace -o yaml | Out-File -FilePath "$exportDir/services.yaml" -Encoding UTF8

# Exportar Ingress
Write-Host "🌐 Exportando Ingress..." -ForegroundColor Yellow
kubectl get ingress -n $namespace -o yaml | Out-File -FilePath "$exportDir/ingress.yaml" -Encoding UTF8

# Exportar PVCs
Write-Host "💾 Exportando PVCs..." -ForegroundColor Yellow
kubectl get pvc -n $namespace -o yaml | Out-File -FilePath "$exportDir/pvcs.yaml" -Encoding UTF8

# Exportar ConfigMaps
Write-Host "📋 Exportando ConfigMaps..." -ForegroundColor Yellow
kubectl get configmaps -n $namespace -o yaml | Out-File -FilePath "$exportDir/configmaps.yaml" -Encoding UTF8

# Exportar Secrets (sem valores sensíveis)
Write-Host "🔐 Exportando Secrets (estrutura apenas)..." -ForegroundColor Yellow
kubectl get secrets -n $namespace -o yaml | Out-File -FilePath "$exportDir/secrets.yaml" -Encoding UTF8

# Exportar StorageClasses
Write-Host "💿 Exportando StorageClasses..." -ForegroundColor Yellow
kubectl get storageclass -o yaml | Out-File -FilePath "$exportDir/storageclasses.yaml" -Encoding UTF8

# Exportar CronJobs
Write-Host "⏰ Exportando CronJobs..." -ForegroundColor Yellow
kubectl get cronjobs -n $namespace -o yaml | Out-File -FilePath "$exportDir/cronjobs.yaml" -Encoding UTF8

# Exportar ManagedCertificates (GKE específico)
Write-Host "🔒 Exportando ManagedCertificates..." -ForegroundColor Yellow
kubectl get managedcertificates -n $namespace -o yaml 2>$null | Out-File -FilePath "$exportDir/managedcertificates.yaml" -Encoding UTF8

# Criar arquivo de resumo
$summary = @"
# Configuração Exportada do GCP - Namespace: $namespace
Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Cluster: $(kubectl config current-context)

## Arquivos Exportados:
- deployments.yaml - Todos os deployments
- services.yaml - Todos os services
- ingress.yaml - Todos os ingress
- pvcs.yaml - Todos os persistent volume claims
- configmaps.yaml - Todos os configmaps
- secrets.yaml - Estrutura dos secrets (valores não incluídos por segurança)
- storageclasses.yaml - Storage classes disponíveis
- cronjobs.yaml - CronJobs configurados
- managedcertificates.yaml - Certificados gerenciados (GKE)

## Comandos Úteis:

### Ver diferenças com arquivos locais:
Compare-Object (Get-Content clusters/n8n-cluster/production/n8n-deployment.yaml) (Get-Content $exportDir/deployments.yaml)

### Aplicar configuração exportada:
kubectl apply -f $exportDir/deployments.yaml

### Ver recursos específicos:
kubectl get deployment n8n -n $namespace -o yaml
kubectl get deployment n8n-worker -n $namespace -o yaml
"@

$summary | Out-File -FilePath "$exportDir/README.md" -Encoding UTF8

Write-Host "`n✅ Exportação concluída!" -ForegroundColor Green
Write-Host "📁 Arquivos salvos em: $exportDir" -ForegroundColor Cyan
Write-Host "`n📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Revisar arquivos exportados" -ForegroundColor White
Write-Host "   2. Comparar com arquivos locais em clusters/n8n-cluster/production/" -ForegroundColor White
Write-Host "   3. Atualizar arquivos locais conforme necessário" -ForegroundColor White




