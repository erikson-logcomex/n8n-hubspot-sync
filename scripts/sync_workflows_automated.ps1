# 🔄 SINCRONIZAÇÃO AUTOMÁTICA DE WORKFLOWS DO N8N
# Script para listar e baixar workflows automaticamente

Write-Host "🔄 SINCRONIZAÇÃO AUTOMÁTICA DE WORKFLOWS" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Conectar ao cluster
Write-Host "`n📡 Conectando ao n8n-cluster..." -ForegroundColor Yellow
gcloud container clusters get-credentials n8n-cluster --zone southamerica-east1-a

# Verificar pods
Write-Host "`n🔍 Verificando pods do n8n..." -ForegroundColor Yellow
$n8nPods = kubectl get pods -n n8n --no-headers | Select-String "n8n.*Running"
if ($n8nPods) {
    $podName = ($n8nPods[0] -split '\s+')[0]
    Write-Host "✅ Usando pod: $podName" -ForegroundColor Green
} else {
    Write-Host "❌ Nenhum pod n8n encontrado" -ForegroundColor Red
    exit 1
}

# Tentar acessar o banco de dados do n8n
Write-Host "`n🗄️ Verificando banco de dados do n8n..." -ForegroundColor Yellow
try {
    $dbCheck = kubectl exec -n n8n $podName -- ls -la /home/node/.n8n/ 2>$null
    if ($dbCheck) {
        Write-Host "✅ Diretório n8n encontrado" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Não foi possível acessar diretório n8n" -ForegroundColor Yellow
}

# Listar workflows locais
Write-Host "`n📁 WORKFLOWS LOCAIS:" -ForegroundColor Yellow
$localWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }
$localCount = $localWorkflows.Count
Write-Host "Total: $localCount workflows" -ForegroundColor Green

foreach ($workflow in $localWorkflows) {
    Write-Host "  • $workflow" -ForegroundColor White
}

# Tentar acessar API do n8n via kubectl port-forward
Write-Host "`n🌐 Configurando acesso à API do n8n..." -ForegroundColor Yellow
Write-Host "Iniciando port-forward em background..." -ForegroundColor White

# Iniciar port-forward em background
$portForwardJob = Start-Job -ScriptBlock {
    kubectl port-forward service/n8n 5678:80 -n n8n
}

# Aguardar port-forward inicializar
Start-Sleep -Seconds 3

# Tentar acessar API
Write-Host "`n📊 Tentando acessar API do n8n..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5678/api/v1/workflows" -Method GET -TimeoutSec 10
    Write-Host "✅ API acessível" -ForegroundColor Green
    
    # Processar resposta
    $workflows = $response.Content | ConvertFrom-Json
    $workflowCount = $workflows.data.Count
    Write-Host "Total de workflows no n8n: $workflowCount" -ForegroundColor Green
    
    Write-Host "`n📋 WORKFLOWS NO N8N:" -ForegroundColor Yellow
    foreach ($workflow in $workflows.data) {
        $status = if ($workflow.active) { "🟢 Ativo" } else { "🔴 Inativo" }
        Write-Host "  • ID: $($workflow.id) | Nome: $($workflow.name) | Status: $status" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Não foi possível acessar API (pode precisar de autenticação)" -ForegroundColor Red
    Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Parar port-forward
Stop-Job $portForwardJob
Remove-Job $portForwardJob

Write-Host "`n💡 PRÓXIMOS PASSOS:" -ForegroundColor Green
Write-Host "1. Se a API não funcionou, acesse manualmente: https://n8n-logcomex.34-8-101-220.nip.io" -ForegroundColor White
Write-Host "2. Compare o número de workflows com os $localCount locais" -ForegroundColor White
Write-Host "3. Baixe workflows faltantes ou remova obsoletos" -ForegroundColor White

Write-Host "`n📊 Análise concluída em $(Get-Date)" -ForegroundColor Cyan
