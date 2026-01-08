# 🧹 LIMPEZA E ORGANIZAÇÃO DO PROJETO N8N
# Script para remover arquivos obsoletos e atualizar documentação

Write-Host "🧹 LIMPEZA E ORGANIZAÇÃO DO PROJETO" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Estado real dos clusters (baseado na auditoria)
$realState = @{
    clusters = @{
        "n8n-cluster" = @{
            zone = "southamerica-east1-a"
            namespace = "n8n"
            url = "n8n-logcomex.34-8-101-220.nip.io"
            components = @("n8n", "n8n-worker", "redis-master")
        }
        "monitoring-cluster-optimized" = @{
            zone = "southamerica-east1-a"
            namespace = "monitoring-new"
            urls = @{
                grafana = "grafana-logcomex.34-8-167-169.nip.io"
                prometheus = "prometheus-logcomex.35-186-250-84.nip.io"
            }
            components = @("grafana", "prometheus")
        }
        "metabase-cluster" = @{
            zone = "southamerica-east1"
            namespace = "metabase"
            url = "metabase.34.13.117.77.nip.io"
            components = @("metabase-app")
        }
    }
}

Write-Host "`n📊 ESTADO REAL DOS CLUSTERS:" -ForegroundColor Yellow
foreach ($cluster in $realState.clusters.GetEnumerator()) {
    Write-Host "• $($cluster.Key): $($cluster.Value.namespace)" -ForegroundColor Green
}

# Arquivos obsoletos identificados
$obsoleteFiles = @(
    # URLs desatualizadas na documentação
    "docs/STATUS_ATUAL_24_09_2025.md",
    "README.md",
    
    # Configurações obsoletas do monitoring
    "clusters/monitoring-cluster/production/prometheus/prometheus-config.yaml",
    "clusters/monitoring-cluster/production/README.md",
    
    # Arquivos de correção que já foram aplicados
    "clusters/monitoring-cluster/production/CORRECOES_MONITORING_HTTPS.md",
    "clusters/monitoring-cluster/production/fix-monitoring-https.ps1",
    "clusters/monitoring-cluster/production/cleanup.ps1",
    "clusters/monitoring-cluster/production/cleanup.sh",
    
    # Arquivos de backup antigos
    "backup_monitoring_20250925_134946/",
    "cluster_export_20250925_141411/",
    
    # Scripts de análise que podem estar desatualizados
    "scripts/analise_monitoring_cluster.ps1"
)

Write-Host "`n🗑️ ARQUIVOS OBSOLETOS IDENTIFICADOS:" -ForegroundColor Yellow
foreach ($file in $obsoleteFiles) {
    if (Test-Path $file) {
        Write-Host "• $file" -ForegroundColor Red
    }
}

# Arquivos duplicados no monitoring
$duplicateFiles = @(
    "clusters/monitoring-cluster/production/grafana/n8n-*.json",
    "clusters/monitoring-cluster/production/archive/",
    "clusters/monitoring-cluster/production/monitoring-*.yaml",
    "clusters/monitoring-cluster/production/prometheus-*.yaml",
    "clusters/monitoring-cluster/production/grafana-*.yaml"
)

Write-Host "`n📁 ARQUIVOS DUPLICADOS IDENTIFICADOS:" -ForegroundColor Yellow
foreach ($pattern in $duplicateFiles) {
    $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Write-Host "• $($file.FullName)" -ForegroundColor Red
    }
}

Write-Host "`n💡 AÇÕES RECOMENDADAS:" -ForegroundColor Green
Write-Host "1. Atualizar URLs na documentação" -ForegroundColor White
Write-Host "2. Remover arquivos de correção já aplicados" -ForegroundColor White
Write-Host "3. Consolidar configurações duplicadas" -ForegroundColor White
Write-Host "4. Limpar arquivos de backup antigos" -ForegroundColor White
Write-Host "5. Atualizar scripts de análise" -ForegroundColor White

Write-Host "`n⚠️ ATENÇÃO:" -ForegroundColor Red
Write-Host "Este script apenas identifica arquivos obsoletos." -ForegroundColor Yellow
Write-Host "Execute as ações manualmente após revisão." -ForegroundColor Yellow

Write-Host "`n📊 Análise concluída em $(Get-Date)" -ForegroundColor Cyan
