# 🔄 SINCRONIZAÇÃO DE WORKFLOWS DO N8N
# Script para sincronizar workflows locais com os reais do n8n

Write-Host "🔄 SINCRONIZAÇÃO DE WORKFLOWS DO N8N" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Conectar ao cluster n8n
Write-Host "`n📡 Conectando ao n8n-cluster..." -ForegroundColor Yellow
gcloud container clusters get-credentials n8n-cluster --zone southamerica-east1-a

# Verificar se o n8n está rodando
Write-Host "`n🔍 Verificando status do n8n..." -ForegroundColor Yellow
$n8nPods = kubectl get pods -n n8n --no-headers | Select-String "n8n.*Running"
if ($n8nPods) {
    Write-Host "✅ n8n está rodando" -ForegroundColor Green
} else {
    Write-Host "❌ n8n não está rodando" -ForegroundColor Red
    exit 1
}

# Fazer port-forward para acessar o n8n
Write-Host "`n🌐 Configurando port-forward..." -ForegroundColor Yellow
Write-Host "Acesse o n8n em: http://localhost:5678" -ForegroundColor Green
Write-Host "Pressione Ctrl+C para parar o port-forward" -ForegroundColor Yellow

# Instruções para sincronização manual
Write-Host "`n📋 INSTRUÇÕES PARA SINCRONIZAÇÃO:" -ForegroundColor Cyan
Write-Host "1. Acesse http://localhost:5678" -ForegroundColor White
Write-Host "2. Faça login no n8n" -ForegroundColor White
Write-Host "3. Vá para 'Workflows' no menu" -ForegroundColor White
Write-Host "4. Para cada workflow:" -ForegroundColor White
Write-Host "   - Clique no workflow" -ForegroundColor White
Write-Host "   - Clique no menu '...' (três pontos)" -ForegroundColor White
Write-Host "   - Selecione 'Download' para baixar o JSON" -ForegroundColor White
Write-Host "   - Salve na pasta workflows/ com nome descritivo" -ForegroundColor White

Write-Host "`n📁 WORKFLOWS LOCAIS ATUAIS:" -ForegroundColor Yellow
$localWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }
foreach ($workflow in $localWorkflows) {
    Write-Host "  • $workflow" -ForegroundColor White
}

Write-Host "`n💡 DICAS:" -ForegroundColor Green
Write-Host "• Use nomes descritivos para os arquivos" -ForegroundColor White
Write-Host "• Exemplo: 'hubspot_contacts_sync.json'" -ForegroundColor White
Write-Host "• Mantenha apenas os workflows ativos" -ForegroundColor White
Write-Host "• Remova workflows obsoletos" -ForegroundColor White

Write-Host "`n⚠️ ATENÇÃO:" -ForegroundColor Red
Write-Host "Este script apenas configura o acesso." -ForegroundColor Yellow
Write-Host "A sincronização deve ser feita manualmente." -ForegroundColor Yellow

# Iniciar port-forward
Write-Host "`n🚀 Iniciando port-forward..." -ForegroundColor Green
kubectl port-forward service/n8n 5678:80 -n n8n
