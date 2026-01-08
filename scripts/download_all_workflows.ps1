# 📥 DOWNLOAD DE TODOS OS WORKFLOWS DO N8N
# Script para baixar todos os workflows do n8n

Write-Host "📥 DOWNLOAD DE TODOS OS WORKFLOWS DO N8N" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Lista de workflows encontrados no n8n
$workflows = @(
    @{id="kwLVbguMZ5DRT8y3"; name="Get Hubspot Owners"},
    @{id="yYQlLG9Vzgn9Wwqa"; name="Get Deals pipelines+Stages"},
    @{id="wi4DtlBmFMdhf1wH"; name="Association - Company to Deals [batch]"},
    @{id="EkvVZZKAx9oOT4wq"; name="Get last modified deals [batch] 30min"},
    @{id="BJCkK1ZYtRFc6OHe"; name="n8n-deal-hubspot-postgre-realtime 2"},
    @{id="3d5XDqg3jL4cFh6q"; name="My workflow"},
    @{id="255mOU4cp7JMmVHp"; name="Deals Export batch"},
    @{id="SClbecXQfg7tJDAZ"; name="deals-streaming-realtime-hsworkflow"},
    @{id="vdg5HZSbMJwwPYD4"; name="get-recent-modifieddeals-hubspot"},
    @{id="WBTunruPYkX7jJaA"; name="n8n-deal-hubspot-postgre-realtime"},
    @{id="VuGvuDbhh6HvB9Aa"; name="Association - Deal Contacts"},
    @{id="zDIH0ZEN0FQlEqBU"; name="Association - Company to Deals realtime"},
    @{id="aQbmPVxy4kCfKOpr"; name="Get all deals [batch]"},
    @{id="XL0ICZZM3oKmB4ZI"; name="Hubspot-companies-recent-modified"},
    @{id="0An63ict0sFPi1cz"; name="Association - Company to Contacts [batch]"},
    @{id="sgbhBkyDHCUfvdHy"; name="Association - Company to Contacts [batch] - recursivo"},
    @{id="ra8MPMqAd09DZnPo"; name="Hubspot Score de Crédito"},
    @{id="edaSCh0Wh45ZEaNG"; name="Association - Company to Deals [daily]"},
    @{id="WisqcYsanfOiYcL9"; name="My workflow 2"},
    @{id="yf9AMwZVeC7bSGR6"; name="Association - Company to Contacts realtime"},
    @{id="htanZgc0PdBahWu6"; name="eazybe_whatsapp_db"},
    @{id="6JpBbUMyYg759BWh"; name="Get all items de linha [batch]"},
    @{id="8WGJmvZ9fq8eERwE"; name="Get items de linha recentes [30min]"},
    @{id="egWL3bsVvXh4KYmr"; name="Get last modified contacts [batch 20min]"},
    @{id="FX3jgBa6of6Ee8FK"; name="Hist_pipe_diario"}
)

Write-Host "`n📊 WORKFLOWS ENCONTRADOS NO N8N: $($workflows.Count)" -ForegroundColor Green

# Listar workflows locais
$localWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }
Write-Host "📁 WORKFLOWS LOCAIS: $($localWorkflows.Count)" -ForegroundColor Yellow

Write-Host "`n📥 BAIXANDO WORKFLOWS FALTANTES..." -ForegroundColor Cyan

$downloaded = 0
$skipped = 0

foreach ($workflow in $workflows) {
    # Criar nome de arquivo seguro
    $safeName = $workflow.name -replace '[^\w\s-]', '' -replace '\s+', '_'
    $fileName = "${safeName}_${workflow.id}.json"
    $filePath = "workflows/$fileName"
    
    if (Test-Path $filePath) {
        Write-Host "⏭️  Pulando: $($workflow.name) (já existe)" -ForegroundColor Yellow
        $skipped++
    } else {
        Write-Host "📥 Baixando: $($workflow.name)" -ForegroundColor Green
        
        # Baixar workflow usando n8n CLI
        $downloadCmd = "n8n export:workflow --id=$($workflow.id) --output=$filePath"
        
        try {
            kubectl exec -n n8n deployment/n8n -- $downloadCmd
            if (Test-Path $filePath) {
                Write-Host "✅ Baixado: $fileName" -ForegroundColor Green
                $downloaded++
            } else {
                Write-Host "❌ Falha ao baixar: $($workflow.name)" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Erro ao baixar: $($workflow.name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n📊 RESUMO:" -ForegroundColor Cyan
Write-Host "• Workflows baixados: $downloaded" -ForegroundColor Green
Write-Host "• Workflows pulados: $skipped" -ForegroundColor Yellow
Write-Host "• Total no n8n: $($workflows.Count)" -ForegroundColor White

Write-Host "`n📁 WORKFLOWS LOCAIS ATUALIZADOS:" -ForegroundColor Yellow
$updatedWorkflows = Get-ChildItem "workflows/*.json" | ForEach-Object { $_.Name }
foreach ($workflow in $updatedWorkflows) {
    Write-Host "  • $workflow" -ForegroundColor White
}

Write-Host "`n✅ Download concluído em $(Get-Date)" -ForegroundColor Green
