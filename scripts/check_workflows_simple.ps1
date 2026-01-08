# 📋 VERIFICAR WORKFLOWS DO N8N - VERSÃO SIMPLES
# Script para orientar verificação manual dos workflows

Write-Host "📋 VERIFICAÇÃO DE WORKFLOWS DO N8N" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Verificar port-forward
Write-Host "`n🔍 Verificando port-forward..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5678" -Method GET -TimeoutSec 5
    Write-Host "✅ n8n está acessível em http://localhost:5678" -ForegroundColor Green
} catch {
    Write-Host "❌ n8n não está acessível" -ForegroundColor Red
    Write-Host "Execute: kubectl port-forward service/n8n 5678:80 -n n8n" -ForegroundColor Yellow
    exit 1
}

# Listar workflows locais
Write-Host "`n📁 WORKFLOWS LOCAIS ATUAIS:" -ForegroundColor Yellow
$localWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }
$localCount = $localWorkflows.Count
Write-Host "Total: $localCount workflows" -ForegroundColor Green

foreach ($workflow in $localWorkflows) {
    Write-Host "  • $workflow" -ForegroundColor White
}

Write-Host "`n🌐 INSTRUÇÕES PARA VERIFICAR WORKFLOWS NO N8N:" -ForegroundColor Cyan
Write-Host "1. Abra o navegador e acesse: http://localhost:5678" -ForegroundColor White
Write-Host "2. Faça login no n8n" -ForegroundColor White
Write-Host "3. Clique em 'Workflows' no menu lateral" -ForegroundColor White
Write-Host "4. Conte quantos workflows existem" -ForegroundColor White
Write-Host "5. Compare com os $localCount workflows locais" -ForegroundColor White

Write-Host "`n📥 PARA BAIXAR WORKFLOWS FALTANTES:" -ForegroundColor Green
Write-Host "1. Para cada workflow no n8n:" -ForegroundColor White
Write-Host "   - Clique no workflow" -ForegroundColor White
Write-Host "   - Clique no menu '...' (três pontos)" -ForegroundColor White
Write-Host "   - Selecione 'Download'" -ForegroundColor White
Write-Host "   - Salve na pasta workflows/ com nome descritivo" -ForegroundColor White

Write-Host "`n🗑️ PARA REMOVER WORKFLOWS OBSOLETOS:" -ForegroundColor Red
Write-Host "1. Verifique se o workflow ainda existe no n8n" -ForegroundColor White
Write-Host "2. Se não existir mais, remova o arquivo local" -ForegroundColor White
Write-Host "3. Mantenha apenas workflows ativos" -ForegroundColor White

Write-Host "`n💡 DICAS DE NOMENCLATURA:" -ForegroundColor Blue
Write-Host "• Use nomes descritivos: 'hubspot_contacts_sync.json'" -ForegroundColor White
Write-Host "• Inclua data se necessário: 'backup_workflow_20250930.json'" -ForegroundColor White
Write-Host "• Evite caracteres especiais e espaços" -ForegroundColor White

Write-Host "`n📊 Análise concluída em $(Get-Date)" -ForegroundColor Cyan
