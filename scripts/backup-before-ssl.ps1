# Script para fazer backup antes de aplicar SSL
# Uso: .\scripts\backup-before-ssl.ps1

$namespace = "n8n"
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = "exports/backup-before-ssl-$timestamp"

Write-Host "💾 Criando backup antes de aplicar SSL..." -ForegroundColor Cyan

# Criar diretório de backup
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Write-Host "📁 Diretório criado: $backupDir" -ForegroundColor Green

# Backup do deployment n8n
Write-Host "📦 Fazendo backup do deployment n8n..." -ForegroundColor Yellow
kubectl get deployment n8n -n $namespace -o yaml | Out-File -FilePath "$backupDir/n8n-deployment.yaml" -Encoding UTF8
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Backup n8n criado" -ForegroundColor Green
} else {
    Write-Host "   ❌ Erro ao fazer backup do n8n" -ForegroundColor Red
}

# Backup do deployment n8n-worker
Write-Host "📦 Fazendo backup do deployment n8n-worker..." -ForegroundColor Yellow
kubectl get deployment n8n-worker -n $namespace -o yaml | Out-File -FilePath "$backupDir/n8n-worker-deployment.yaml" -Encoding UTF8
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Backup n8n-worker criado" -ForegroundColor Green
} else {
    Write-Host "   ❌ Erro ao fazer backup do n8n-worker" -ForegroundColor Red
}

# Backup do ConfigMap postgres-ssl-cert (se existir)
Write-Host "📦 Verificando ConfigMap postgres-ssl-cert..." -ForegroundColor Yellow
$null = kubectl get configmap postgres-ssl-cert -n $namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    kubectl get configmap postgres-ssl-cert -n $namespace -o yaml | Out-File -FilePath "$backupDir/postgres-ssl-cert-configmap.yaml" -Encoding UTF8
    Write-Host "   ✅ Backup ConfigMap criado" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  ConfigMap não existe ainda (normal)" -ForegroundColor Gray
}

# Criar arquivo de resumo
$currentContext = kubectl config current-context
$currentDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$readmePath = Join-Path $backupDir "README.md"

$readmeContent = @"
# Backup Antes de Aplicar SSL
Data: $currentDate
Namespace: $namespace
Cluster: $currentContext

## Arquivos de Backup:
- n8n-deployment.yaml - Deployment principal do n8n
- n8n-worker-deployment.yaml - Deployment dos workers
- postgres-ssl-cert-configmap.yaml - ConfigMap SSL (se existir)

## Como Restaurar:

### Restaurar deployment n8n:
kubectl apply -f $backupDir/n8n-deployment.yaml

### Restaurar deployment n8n-worker:
kubectl apply -f $backupDir/n8n-worker-deployment.yaml

### Restaurar ConfigMap (se necessário):
kubectl apply -f $backupDir/postgres-ssl-cert-configmap.yaml

## Rollback Rápido:
kubectl rollout undo deployment/n8n -n $namespace
kubectl rollout undo deployment/n8n-worker -n $namespace
"@

$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host ""
Write-Host "✅ Backup concluído!" -ForegroundColor Green
Write-Host "📁 Arquivos salvos em: $backupDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Revisar backups criados" -ForegroundColor White
Write-Host "   2. Aplicar SSL conforme checklist" -ForegroundColor White
Write-Host "   3. Se necessário, usar rollback: docs/PLANO_ROLLBACK_SSL.md" -ForegroundColor White
Write-Host ""
