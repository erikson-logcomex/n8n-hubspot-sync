# Script de Organização e Limpeza do Projeto n8n
# Objetivo: Sincronizar projeto local com GCP e organizar estrutura

param(
    [switch]$DryRun = $false,
    [switch]$ExportGCP = $true
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot + "\.."

Write-Host "`n🧹 ORGANIZAÇÃO DO PROJETO N8N" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# ============================================
# 1. EXPORTAR CONFIGURAÇÕES ATUAIS DO GCP
# ============================================
if ($ExportGCP) {
    Write-Host "📥 Exportando configurações do GCP..." -ForegroundColor Yellow
    
    $exportDir = "$projectRoot\exports\gcp-current-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    
    # Exportar n8n-cluster
    Write-Host "  → Exportando n8n-cluster..." -ForegroundColor Gray
    $n8nDir = "$exportDir\n8n-cluster"
    New-Item -ItemType Directory -Path $n8nDir -Force | Out-Null
    
    try {
        kubectl config use-context gke_datatoopenai_southamerica-east1-a_n8n-cluster 2>&1 | Out-Null
        kubectl get deployment n8n -n n8n -o yaml > "$n8nDir\n8n-deployment.yaml" 2>&1
        kubectl get deployment n8n-worker -n n8n -o yaml > "$n8nDir\n8n-worker-deployment.yaml" 2>&1
        kubectl get deployment evolution-api -n n8n -o yaml > "$n8nDir\evolution-api-deployment.yaml" 2>&1
        kubectl get configmap postgres-ssl-cert -n n8n -o yaml > "$n8nDir\postgres-ssl-cert-configmap.yaml" 2>&1
        kubectl get secret postgres-secret -n n8n -o yaml > "$n8nDir\postgres-secret.yaml" 2>&1
        kubectl get secret evolution-api -n n8n -o yaml > "$n8nDir\evolution-api-secret.yaml" 2>&1
        kubectl get service n8n -n n8n -o yaml > "$n8nDir\n8n-service.yaml" 2>&1
        kubectl get ingress n8n-ingress -n n8n -o yaml > "$n8nDir\n8n-ingress.yaml" 2>&1
    } catch {
        Write-Host "    ⚠️  Erro ao exportar n8n-cluster: $_" -ForegroundColor Yellow
    }
    
    # Exportar metabase-cluster
    Write-Host "  → Exportando metabase-cluster..." -ForegroundColor Gray
    $metabaseDir = "$exportDir\metabase-cluster"
    New-Item -ItemType Directory -Path $metabaseDir -Force | Out-Null
    
    try {
        kubectl config use-context gke_datatoopenai_southamerica-east1-metabase-cluster 2>&1 | Out-Null
        kubectl get deployment metabase-app -n metabase -o yaml > "$metabaseDir\metabase-deployment.yaml" 2>&1
        kubectl get configmap postgres-ssl-cert -n metabase -o yaml > "$metabaseDir\postgres-ssl-cert-configmap.yaml" 2>&1
        kubectl get service metabase-svc -n metabase -o yaml > "$metabaseDir\metabase-service.yaml" 2>&1
        kubectl get ingress metabase-ing -n metabase -o yaml > "$metabaseDir\metabase-ingress.yaml" 2>&1
    } catch {
        Write-Host "    ⚠️  Erro ao exportar metabase-cluster: $_" -ForegroundColor Yellow
    }
    
    Write-Host "  ✅ Exportação concluída: $exportDir" -ForegroundColor Green
}

# ============================================
# 2. IDENTIFICAR ARQUIVOS PARA LIMPEZA
# ============================================
Write-Host "`n🔍 Identificando arquivos para limpeza..." -ForegroundColor Yellow

$filesToRemove = @()
$filesToArchive = @()

# Arquivos temporários
$filesToRemove += Get-ChildItem -Path $projectRoot -Filter "temp*.yaml" -Recurse -ErrorAction SilentlyContinue
$filesToRemove += Get-ChildItem -Path $projectRoot -Filter "*temp*.yaml" -Recurse -ErrorAction SilentlyContinue
$filesToRemove += Get-ChildItem -Path $projectRoot -Filter "*current*.yaml" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*current*" -and $_.Name -notlike "*gcp*" }

# Backups antigos (manter apenas os 3 mais recentes)
$backupDirs = Get-ChildItem -Path "$projectRoot\exports" -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "backup-*" -or $_.Name -like "gcp-current-*" } |
    Sort-Object LastWriteTime -Descending | Select-Object -Skip 3
$filesToArchive += $backupDirs

# Arquivos duplicados (manter apenas os principais)
$duplicatePatterns = @(
    @{ Pattern = "*deployment-gcp.yaml"; Keep = "*deployment.yaml" },
    @{ Pattern = "*deployment-current.yaml"; Keep = "*deployment.yaml" },
    @{ Pattern = "*configmaps-gcp.yaml"; Keep = "*configmaps.yaml" },
    @{ Pattern = "*configmaps-current.yaml"; Keep = "*configmaps.yaml" },
    @{ Pattern = "*secrets-gcp.yaml"; Keep = "*secrets.yaml" },
    @{ Pattern = "*secrets-current.yaml"; Keep = "*secrets.yaml" }
)

foreach ($pattern in $duplicatePatterns) {
    $duplicates = Get-ChildItem -Path "$projectRoot\clusters" -Filter $pattern.Pattern -Recurse -ErrorAction SilentlyContinue
    $filesToArchive += $duplicates
}

# Arquivos na raiz que devem estar em pastas
$rootFiles = Get-ChildItem -Path $projectRoot -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.Extension -in @(".yaml", ".yml", ".json") -and 
        $_.Name -notlike "README.md" -and 
        $_.Name -notlike "*.gitignore" -and
        $_.Name -notlike "*.cursorignore" -and
        $_.Name -notlike "requirements.txt" -and
        $_.Name -notlike "env.example"
    }
$filesToArchive += $rootFiles

# Pasta temp_ssl_kubernetes (backup antigo)
if (Test-Path "$projectRoot\temp_ssl_kubernetes") {
    $filesToArchive += Get-Item "$projectRoot\temp_ssl_kubernetes"
}

# Pasta temp (arquivos temporários)
if (Test-Path "$projectRoot\temp") {
    $tempFiles = Get-ChildItem -Path "$projectRoot\temp" -Recurse -ErrorAction SilentlyContinue
    $filesToArchive += $tempFiles
}

Write-Host "  📋 Arquivos identificados:" -ForegroundColor Gray
Write-Host "     - Para remover: $($filesToRemove.Count)" -ForegroundColor White
Write-Host "     - Para arquivar: $($filesToArchive.Count)" -ForegroundColor White

# ============================================
# 3. EXECUTAR LIMPEZA
# ============================================
if (-not $DryRun) {
    Write-Host "`n🗑️  Executando limpeza..." -ForegroundColor Yellow
    
    # Criar pasta archive
    $archiveDir = "$projectRoot\archive\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    
    # Mover arquivos para archive
    foreach ($item in $filesToArchive) {
        if ($item) {
            try {
                $destPath = "$archiveDir\$($item.Name)"
                if (Test-Path $destPath) {
                    $destPath = "$archiveDir\$($item.BaseName)_$($item.LastWriteTime.ToString('yyyyMMddHHmmss'))$($item.Extension)"
                }
                Move-Item -Path $item.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
                Write-Host "  📦 Arquivado: $($item.Name)" -ForegroundColor Gray
            } catch {
                Write-Host "  ⚠️  Erro ao arquivar $($item.Name): $_" -ForegroundColor Yellow
            }
        }
    }
    
    # Remover arquivos temporários
    foreach ($item in $filesToRemove) {
        if ($item) {
            try {
                Remove-Item -Path $item.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  🗑️  Removido: $($item.Name)" -ForegroundColor Gray
            } catch {
                Write-Host "  ⚠️  Erro ao remover $($item.Name): $_" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "  ✅ Limpeza concluída" -ForegroundColor Green
    Write-Host "  📦 Arquivos arquivados em: $archiveDir" -ForegroundColor Cyan
} else {
    Write-Host "`n🔍 DRY RUN - Nenhuma alteração foi feita" -ForegroundColor Yellow
    Write-Host "  Use sem -DryRun para executar a limpeza" -ForegroundColor Gray
}

# ============================================
# 4. ORGANIZAR ESTRUTURA
# ============================================
Write-Host "`n📁 Organizando estrutura de pastas..." -ForegroundColor Yellow

# Garantir estrutura padrão
$requiredDirs = @(
    "$projectRoot\clusters\n8n-cluster\production",
    "$projectRoot\clusters\n8n-cluster\staging",
    "$projectRoot\clusters\metabase-cluster\production",
    "$projectRoot\clusters\metabase-cluster\staging",
    "$projectRoot\clusters\monitoring-cluster\production",
    "$projectRoot\clusters\monitoring-cluster\staging",
    "$projectRoot\docs",
    "$projectRoot\scripts",
    "$projectRoot\workflows",
    "$projectRoot\config",
    "$projectRoot\exports",
    "$projectRoot\archive",
    "$projectRoot\certs"
)

foreach ($dir in $requiredDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✅ Criado: $dir" -ForegroundColor Gray
    }
}

Write-Host "  ✅ Estrutura organizada" -ForegroundColor Green

# ============================================
# 5. RESUMO
# ============================================
Write-Host "`n📊 RESUMO DA ORGANIZAÇÃO" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

Write-Host "✅ Ações realizadas:" -ForegroundColor Green
if ($ExportGCP) {
    Write-Host "   ✓ Configurações do GCP exportadas" -ForegroundColor White
}
if (-not $DryRun) {
    Write-Host "   ✓ $($filesToRemove.Count) arquivos removidos" -ForegroundColor White
    Write-Host "   ✓ $($filesToArchive.Count) arquivos arquivados" -ForegroundColor White
    Write-Host "   ✓ Estrutura de pastas organizada" -ForegroundColor White
} else {
    Write-Host "   ⚠️  Modo Dry Run - Nenhuma alteração foi feita" -ForegroundColor Yellow
}

Write-Host "`n📋 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Revisar arquivos exportados do GCP" -ForegroundColor White
Write-Host "   2. Sincronizar YAMLs locais com GCP" -ForegroundColor White
Write-Host "   3. Consolidar documentação duplicada" -ForegroundColor White
Write-Host "   4. Atualizar README principal" -ForegroundColor White

Write-Host "`n✅ Organização concluída!`n" -ForegroundColor Green




