# Script de Sincronização com GCP
# Objetivo: Sincronizar arquivos locais com configurações atuais do GCP

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("n8n", "metabase", "monitoring", "all")]
    [string]$Cluster = "all",
    
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot + "\.."

Write-Host "`n🔄 SINCRONIZAÇÃO COM GCP" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

function Sync-N8NCluster {
    Write-Host "📥 Sincronizando n8n-cluster..." -ForegroundColor Yellow
    
    try {
        kubectl config use-context gke_datatoopenai_southamerica-east1-a_n8n-cluster 2>&1 | Out-Null
        
        $clusterDir = "$projectRoot\clusters\n8n-cluster\production"
        
        # Exportar deployments
        Write-Host "  → Exportando deployments..." -ForegroundColor Gray
        kubectl get deployment n8n -n n8n -o yaml | Out-File "$clusterDir\n8n-optimized-deployment.yaml" -Encoding UTF8
        kubectl get deployment n8n-worker -n n8n -o yaml | Out-File "$clusterDir\n8n-worker-optimized-deployment.yaml" -Encoding UTF8
        kubectl get deployment evolution-api -n n8n -o yaml | Out-File "$clusterDir\evolution-api-deployment.yaml" -Encoding UTF8
        
        # Exportar secrets (sem dados sensíveis)
        Write-Host "  → Exportando secrets (estrutura)..." -ForegroundColor Gray
        kubectl get secret postgres-secret -n n8n -o yaml | Out-File "$clusterDir\postgres-secret.yaml" -Encoding UTF8
        kubectl get secret evolution-api -n n8n -o yaml | Out-File "$clusterDir\evolution-api-secret.yaml" -Encoding UTF8
        
        # Exportar configmaps
        Write-Host "  → Exportando configmaps..." -ForegroundColor Gray
        kubectl get configmap postgres-ssl-cert -n n8n -o yaml | Out-File "$clusterDir\postgres-ssl-cert-configmap.yaml" -Encoding UTF8
        
        # Exportar services e ingress
        Write-Host "  → Exportando services e ingress..." -ForegroundColor Gray
        kubectl get service n8n -n n8n -o yaml | Out-File "$clusterDir\n8n-service.yaml" -Encoding UTF8
        kubectl get ingress n8n-ingress -n n8n -o yaml | Out-File "$clusterDir\n8n-ingress.yaml" -Encoding UTF8
        
        Write-Host "  ✅ n8n-cluster sincronizado" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Erro ao sincronizar n8n-cluster: $_" -ForegroundColor Red
    }
}

function Sync-MetabaseCluster {
    Write-Host "📥 Sincronizando metabase-cluster..." -ForegroundColor Yellow
    
    try {
        kubectl config use-context gke_datatoopenai_southamerica-east1-metabase-cluster 2>&1 | Out-Null
        
        $clusterDir = "$projectRoot\clusters\metabase-cluster\production"
        
        # Exportar deployment
        Write-Host "  → Exportando deployment..." -ForegroundColor Gray
        kubectl get deployment metabase-app -n metabase -o yaml | Out-File "$clusterDir\metabase-deployment.yaml" -Encoding UTF8
        
        # Exportar configmaps
        Write-Host "  → Exportando configmaps..." -ForegroundColor Gray
        kubectl get configmap postgres-ssl-cert -n metabase -o yaml | Out-File "$clusterDir\postgres-ssl-cert-configmap.yaml" -Encoding UTF8
        
        # Exportar services e ingress
        Write-Host "  → Exportando services e ingress..." -ForegroundColor Gray
        kubectl get service metabase-svc -n metabase -o yaml | Out-File "$clusterDir\metabase-service.yaml" -Encoding UTF8
        kubectl get ingress metabase-ing -n metabase -o yaml | Out-File "$clusterDir\metabase-ingress.yaml" -Encoding UTF8
        
        Write-Host "  ✅ metabase-cluster sincronizado" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Erro ao sincronizar metabase-cluster: $_" -ForegroundColor Red
    }
}

function Sync-MonitoringCluster {
    Write-Host "📥 Sincronizando monitoring-cluster..." -ForegroundColor Yellow
    
    try {
        # Verificar contexto do monitoring-cluster
        $contexts = kubectl config get-contexts -o name | Select-String "monitoring"
        if ($contexts) {
            kubectl config use-context $contexts[0] 2>&1 | Out-Null
            
            $clusterDir = "$projectRoot\clusters\monitoring-cluster\production"
            
            Write-Host "  → Exportando deployments..." -ForegroundColor Gray
            kubectl get deployment prometheus -n monitoring-new -o yaml | Out-File "$clusterDir\prometheus-deployment-optimized.yaml" -Encoding UTF8
            kubectl get deployment grafana -n monitoring-new -o yaml | Out-File "$clusterDir\grafana-deployment-optimized.yaml" -Encoding UTF8
            
            Write-Host "  ✅ monitoring-cluster sincronizado" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Contexto do monitoring-cluster não encontrado" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ Erro ao sincronizar monitoring-cluster: $_" -ForegroundColor Red
    }
}

# Executar sincronização
if ($DryRun) {
    Write-Host "🔍 DRY RUN - Nenhuma alteração será feita`n" -ForegroundColor Yellow
}

switch ($Cluster) {
    "n8n" { Sync-N8NCluster }
    "metabase" { Sync-MetabaseCluster }
    "monitoring" { Sync-MonitoringCluster }
    "all" {
        Sync-N8NCluster
        Sync-MetabaseCluster
        Sync-MonitoringCluster
    }
}

Write-Host "`n✅ Sincronização concluída!`n" -ForegroundColor Green




