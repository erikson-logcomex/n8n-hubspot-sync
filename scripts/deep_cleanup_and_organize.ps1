# 🧹 LIMPEZA PROFUNDA E REORGANIZAÇÃO COMPLETA DO PROJETO N8N
# Script para limpeza profunda, remoção de arquivos obsoletos e reorganização

Write-Host "🧹 LIMPEZA PROFUNDA E REORGANIZAÇÃO DO PROJETO" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# 1. ANÁLISE DA PASTA SCRIPTS/ (41 arquivos - muitos obsoletos)
Write-Host "`n📁 ANÁLISE DA PASTA SCRIPTS/:" -ForegroundColor Yellow

$scriptsToRemove = @(
    # Scripts de primeira carga obsoletos (já implementados)
    "scripts/primeira_carga_hubspot.py",
    "scripts/primeira_carga_hubspot_otimizada.py", 
    "scripts/primeira_carga_hubspot_final.py",
    "scripts/primeira_carga_funcional.py",
    "scripts/primeira_carga_inteligente.py",
    "scripts/primeira_carga_simples.py",
    
    # Scripts de análise obsoletos/duplicados
    "scripts/analise_amostra_10k.py",
    "scripts/analise_amostra_maior.py",
    "scripts/analise_completa_549_propriedades.py",
    "scripts/analise_lotes_propriedades.py",
    "scripts/analise_monitoring_simples.ps1",
    
    # Scripts de organização obsoletos
    "scripts/organize-project.ps1",
    "scripts/organize-simple.ps1", 
    "scripts/organize_files.ps1",
    "scripts/organize_simple.ps1",
    
    # Scripts de deploy obsoletos
    "scripts/deploy_table.py",
    "scripts/deploy_table_python.py",
    "scripts/deploy_hubspot_table.ps1",
    "scripts/deploy-fixed.ps1",
    
    # Scripts de teste obsoletos
    "scripts/teste_simples.py",
    "scripts/test_hubspot_properties.py",
    "scripts/test_hubspot_sync_db.py",
    
    # Scripts de descoberta obsoletos
    "scripts/descobrir_todas_propriedades.py",
    "scripts/discover_real_properties.py",
    
    # Scripts de verificação obsoletos
    "scripts/verificar_tabela_otimizada.py",
    "scripts/verificar_tabela_real.py",
    "scripts/verify_company.py",
    
    # Scripts de cálculo obsoletos
    "scripts/calcular_media_api.py",
    
    # Scripts de execução obsoletos
    "scripts/executar_sql.py",
    
    # Scripts de migração obsoletos
    "scripts/migrate_cluster_single_zone.ps1",
    
    # Scripts de backup obsoletos
    "scripts/backup_monitoring_data.ps1",
    
    # Scripts de teste de URL obsoletos
    "scripts/test_cluster_urls.ps1",
    
    # Scripts de health check obsoletos
    "scripts/health-check.ps1",
    
    # Scripts de análise obsoletos
    "scripts/run_hubspot_analysis.ps1"
)

Write-Host "🗑️ Scripts obsoletos identificados para remoção:" -ForegroundColor Red
foreach ($script in $scriptsToRemove) {
    if (Test-Path $script) {
        Write-Host "  • $script" -ForegroundColor Red
    }
}

# 2. ARQUIVOS SOLTOS NA RAIZ
Write-Host "`n📄 ARQUIVOS SOLTOS NA RAIZ:" -ForegroundColor Yellow
$rootFilesToMove = @{
    "n8n-dashboard-container-metrics.yaml" = "clusters/monitoring-cluster/production/grafana/"
    "authorized-networks.json" = "config/"
}

Write-Host "📁 Arquivos para mover:" -ForegroundColor Yellow
foreach ($file in $rootFilesToMove.GetEnumerator()) {
    if (Test-Path $file.Key) {
        Write-Host "  • $($file.Key) → $($file.Value)" -ForegroundColor Yellow
    }
}

# 3. PASTA WORKFLOWS/ - VERIFICAR SE ESTÁ COMPLETA
Write-Host "`n🔄 PASTA WORKFLOWS/:" -ForegroundColor Yellow
Write-Host "  • Workflows locais: $(Get-ChildItem workflows/*.json | Measure-Object).Count arquivos"
Write-Host "  • ⚠️  Necessário verificar workflows reais no n8n"

# 4. DASHBOARDS DO METABASE - FALTANDO DOCUMENTAÇÃO
Write-Host "`n📊 DASHBOARDS DO METABASE:" -ForegroundColor Yellow
Write-Host "  • ⚠️  Nenhuma documentação encontrada sobre dashboards do Metabase"
Write-Host "  • Necessário acessar Metabase e documentar dashboards existentes"

# 5. DOCUMENTAÇÃO EM DOCS/ - VERIFICAR PRECISÃO
Write-Host "`n📚 DOCUMENTAÇÃO EM DOCS/:" -ForegroundColor Yellow
$docsToReview = @(
    "docs/STATUS_ATUAL_24_09_2025.md",
    "docs/PERFORMANCE_ANALYSIS_22_09_2025.md", 
    "docs/COST_ANALYSIS_IMPROVEMENTS.md",
    "docs/N8N_KUBERNETES_BEST_PRACTICES_ANALYSIS.md",
    "docs/GRAFANA_CAPABILITIES_ANALYSIS.md"
)

Write-Host "📋 Documentos para revisar:" -ForegroundColor Yellow
foreach ($doc in $docsToReview) {
    if (Test-Path $doc) {
        Write-Host "  • $doc" -ForegroundColor Yellow
    }
}

# 6. PASTA TEMP/ - VERIFICAR SE PODE SER REMOVIDA
Write-Host "`n🗂️ PASTA TEMP/:" -ForegroundColor Yellow
if (Test-Path "temp") {
    $tempFiles = Get-ChildItem "temp" -Recurse | Measure-Object
    Write-Host "  • $($tempFiles.Count) arquivos na pasta temp/"
    Write-Host "  • ⚠️  Verificar se pode ser removida"
} else {
    Write-Host "  • ✅ Pasta temp/ não existe"
}

# 7. PASTA __pycache__ - REMOVER
Write-Host "`n🐍 PASTA __pycache__:" -ForegroundColor Yellow
if (Test-Path "scripts/__pycache__") {
    Write-Host "  • ⚠️  Pasta __pycache__ encontrada - deve ser removida"
} else {
    Write-Host "  • ✅ Pasta __pycache__ não encontrada"
}

Write-Host "`n💡 AÇÕES RECOMENDADAS:" -ForegroundColor Green
Write-Host "1. Remover $($scriptsToRemove.Count) scripts obsoletos" -ForegroundColor White
Write-Host "2. Mover arquivos soltos da raiz para pastas apropriadas" -ForegroundColor White
Write-Host "3. Sincronizar workflows/ com n8n real" -ForegroundColor White
Write-Host "4. Documentar dashboards do Metabase" -ForegroundColor White
Write-Host "5. Revisar toda documentação em docs/" -ForegroundColor White
Write-Host "6. Limpar pastas temp/ e __pycache__" -ForegroundColor White

Write-Host "`n⚠️ ATENÇÃO:" -ForegroundColor Red
Write-Host "Este script apenas identifica problemas." -ForegroundColor Yellow
Write-Host "Execute as ações manualmente após revisão." -ForegroundColor Yellow

Write-Host "`n📊 Análise concluída em $(Get-Date)" -ForegroundColor Cyan
