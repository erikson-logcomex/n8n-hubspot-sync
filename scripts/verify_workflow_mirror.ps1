# 🔍 VERIFICAR ESPELHO DE WORKFLOWS
# Script para verificar se temos exatamente os mesmos workflows do n8n

Write-Host "🔍 VERIFICANDO ESPELHO DE WORKFLOWS" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Lista de workflows do n8n (26 total)
$n8nWorkflows = @(
    "kwLVbguMZ5DRT8y3|Get Hubspot Owners",
    "yYQlLG9Vzgn9Wwqa|Get Deals pipelines+Stages", 
    "wi4DtlBmFMdhf1wH|Association - Company to Deals [batch]",
    "EkvVZZKAx9oOT4wq|Get last modified deals [batch] 30min",
    "BJCkK1ZYtRFc6OHe|n8n-deal-hubspot-postgre-realtime 2",
    "3d5XDqg3jL4cFh6q|My workflow",
    "255mOU4cp7JMmVHp|Deals Export batch",
    "SClbecXQfg7tJDAZ|deals-streaming-realtime-hsworkflow",
    "vdg5HZSbMJwwPYD4|get-recent-modifieddeals-hubspot",
    "WBTunruPYkX7jJaA|n8n-deal-hubspot-postgre-realtime",
    "zDIH0ZEN0FQlEqBU|Association - Company to Deals realtime",
    "VuGvuDbhh6HvB9Aa|Association - Deal Contacts",
    "aQbmPVxy4kCfKOpr|Get all deals [batch]",
    "XL0ICZZM3oKmB4ZI|Hubspot-companies-recent-modified",
    "0An63ict0sFPi1cz|Association - Company to Contacts [batch]",
    "sgbhBkyDHCUfvdHy|Association - Company to Contacts [batch] - recursivo",
    "ra8MPMqAd09DZnPo|Hubspot Score de Crédito",
    "edaSCh0Wh45ZEaNG|Association - Company to Deals [daily]",
    "WisqcYsanfOiYcL9|My workflow 2",
    "yf9AMwZVeC7bSGR6|Association - Company to Contacts realtime",
    "htanZgc0PdBahWu6|eazybe_whatsapp_db",
    "6JpBbUMyYg759BWh|Get all items de linha [batch]",
    "8WGJmvZ9fq8eERwE|Get items de linha recentes [30min]",
    "egWL3bsVvXh4KYmr|Get last modified contacts [batch 20min]",
    "FX3jgBa6of6Ee8FK|Hist_pipe_diario"
)

# Lista de workflows locais
$localWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }

Write-Host "`n📊 ESTATÍSTICAS:" -ForegroundColor Yellow
Write-Host "• Workflows no n8n: $($n8nWorkflows.Count)" -ForegroundColor Green
Write-Host "• Workflows locais: $($localWorkflows.Count)" -ForegroundColor Green

# Verificar se todos os workflows do n8n estão locais
Write-Host "`n🔍 VERIFICANDO WORKFLOWS FALTANTES:" -ForegroundColor Yellow
$missing = @()
foreach ($workflow in $n8nWorkflows) {
    $id = $workflow.Split('|')[0]
    $name = $workflow.Split('|')[1]
    
    # Procurar por arquivo que contenha o ID
    $found = $localWorkflows | Where-Object { $_ -like "*$id*" }
    if (-not $found) {
        $missing += $workflow
        Write-Host "❌ FALTANDO: $name ($id)" -ForegroundColor Red
    } else {
        Write-Host "✅ ENCONTRADO: $name ($id)" -ForegroundColor Green
    }
}

# Verificar workflows extras locais
Write-Host "`n🔍 VERIFICANDO WORKFLOWS EXTRAS:" -ForegroundColor Yellow
$extra = @()
foreach ($local in $localWorkflows) {
    $found = $false
    foreach ($workflow in $n8nWorkflows) {
        $id = $workflow.Split('|')[0]
        if ($local -like "*$id*") {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $extra += $local
        Write-Host "⚠️  EXTRA: $local" -ForegroundColor Yellow
    }
}

Write-Host "`n📋 RESUMO:" -ForegroundColor Cyan
Write-Host "• Workflows faltantes: $($missing.Count)" -ForegroundColor Red
Write-Host "• Workflows extras: $($extra.Count)" -ForegroundColor Yellow

if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
    Write-Host "`n✅ ESPELHO PERFEITO!" -ForegroundColor Green
    Write-Host "Todos os workflows do n8n estão locais e não há extras." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  ESPELHO INCOMPLETO" -ForegroundColor Red
    if ($missing.Count -gt 0) {
        Write-Host "Baixar workflows faltantes:" -ForegroundColor Yellow
        foreach ($workflow in $missing) {
            $id = $workflow.Split('|')[0]
            $name = $workflow.Split('|')[1]
            Write-Host "kubectl exec -n n8n deployment/n8n -- n8n export:workflow --id=$id > workflows/$name`_$id.json" -ForegroundColor White
        }
    }
    if ($extra.Count -gt 0) {
        Write-Host "Remover workflows extras:" -ForegroundColor Yellow
        foreach ($workflow in $extra) {
            Write-Host "Remove-Item `"workflows/$workflow`" -Force" -ForegroundColor White
        }
    }
}

Write-Host "`n📊 Verificação concluída em $(Get-Date)" -ForegroundColor Cyan
