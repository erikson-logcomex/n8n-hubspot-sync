# 📋 LISTAR WORKFLOWS DO N8N
# Script para listar workflows do n8n e comparar com os locais

Write-Host "📋 LISTANDO WORKFLOWS DO N8N" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Verificar se o port-forward está ativo
Write-Host "`n🔍 Verificando conectividade com n8n..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5678/api/v1/workflows" -Method GET -TimeoutSec 10
    Write-Host "✅ Conectado ao n8n" -ForegroundColor Green
} catch {
    Write-Host "❌ Não foi possível conectar ao n8n" -ForegroundColor Red
    Write-Host "Certifique-se de que o port-forward está ativo:" -ForegroundColor Yellow
    Write-Host "kubectl port-forward service/n8n 5678:80 -n n8n" -ForegroundColor White
    exit 1
}

# Listar workflows do n8n
Write-Host "`n📊 WORKFLOWS NO N8N:" -ForegroundColor Yellow
try {
    $workflows = $response.Content | ConvertFrom-Json
    $workflowCount = $workflows.data.Count
    Write-Host "Total de workflows encontrados: $workflowCount" -ForegroundColor Green
    
    foreach ($workflow in $workflows.data) {
        $status = if ($workflow.active) { "🟢 Ativo" } else { "🔴 Inativo" }
        Write-Host "  • ID: $($workflow.id) | Nome: $($workflow.name) | Status: $status" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Erro ao processar resposta do n8n" -ForegroundColor Red
    Write-Host "Resposta: $($response.Content)" -ForegroundColor Yellow
}

# Listar workflows locais
Write-Host "`n📁 WORKFLOWS LOCAIS:" -ForegroundColor Yellow
$localWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }
$localCount = $localWorkflows.Count
Write-Host "Total de workflows locais: $localCount" -ForegroundColor Green

foreach ($workflow in $localWorkflows) {
    Write-Host "  • $workflow" -ForegroundColor White
}

# Comparar
Write-Host "`n🔍 COMPARAÇÃO:" -ForegroundColor Yellow
if ($workflowCount -gt $localCount) {
    $missing = $workflowCount - $localCount
    Write-Host "⚠️  Faltam $missing workflows locais!" -ForegroundColor Red
    Write-Host "Execute o script de sincronização para baixar os workflows faltantes." -ForegroundColor Yellow
} elseif ($workflowCount -eq $localCount) {
    Write-Host "✅ Número de workflows coincide" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Mais workflows locais que no n8n (possíveis arquivos obsoletos)" -ForegroundColor Blue
}

Write-Host "`n💡 PRÓXIMOS PASSOS:" -ForegroundColor Green
Write-Host "1. Se faltam workflows, execute: .\scripts\sync_n8n_workflows.ps1" -ForegroundColor White
Write-Host "2. Acesse http://localhost:5678 para baixar workflows manualmente" -ForegroundColor White
Write-Host "3. Remova workflows obsoletos da pasta local" -ForegroundColor White

Write-Host "`n📊 Análise concluída em $(Get-Date)" -ForegroundColor Cyan
