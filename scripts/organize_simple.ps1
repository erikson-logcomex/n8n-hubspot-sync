# Script para organizar arquivos do projeto n8n HubSpot Sync
# Execute com: powershell -ExecutionPolicy Bypass .\organize_simple.ps1

Write-Host "ORGANIZANDO ARQUIVOS DO PROJETO..." -ForegroundColor Cyan

# Criar estrutura se nao existir
Write-Host "Criando estrutura de pastas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "temp" -Force | Out-Null

# Mover workflows obsoletos para temp
Write-Host "Movendo workflows obsoletos para temp..." -ForegroundColor Yellow
$obsoleteWorkflows = @(
    "workflow_contacts_sql_1h.json",
    "workflow_contacts_sql_debug.json", 
    "workflow_contacts_sql_fixed.json",
    "workflow_contacts_sql_robust.json",
    "workflow_contacts_sql_simple.json"
)

foreach ($file in $obsoleteWorkflows) {
    if (Test-Path $file) {
        Move-Item $file "temp\" -Force
        Write-Host "  Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  Nao encontrado: $file" -ForegroundColor Gray
    }
}

# Mover arquivos SQL temporarios para temp
Write-Host "Movendo arquivos SQL temporarios para temp..." -ForegroundColor Yellow
$tempSqlFiles = @(
    "fix_field_sizes.sql",
    "fix_table_not_null.sql"
)

foreach ($file in $tempSqlFiles) {
    if (Test-Path $file) {
        Move-Item $file "temp\" -Force
        Write-Host "  Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  Nao encontrado: $file" -ForegroundColor Gray
    }
}

# Mover scripts de correcao para scripts/fixes
Write-Host "Movendo scripts de correcao para scripts/fixes..." -ForegroundColor Yellow
$fixScripts = @(
    "fix_field_sizes.py"
)

foreach ($file in $fixScripts) {
    if (Test-Path $file) {
        Move-Item $file "scripts\fixes\" -Force
        Write-Host "  Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  Nao encontrado: $file" -ForegroundColor Gray
    }
}

# Mover documentacao para docs
Write-Host "Movendo documentacao..." -ForegroundColor Yellow
if (Test-Path "STATUS_WORKFLOW.md") {
    Move-Item "STATUS_WORKFLOW.md" "docs\" -Force
    Write-Host "  Movido: STATUS_WORKFLOW.md" -ForegroundColor Green
}

if (Test-Path "CORREÇÕES_APLICADAS.md") {
    Move-Item "CORREÇÕES_APLICADAS.md" "docs\" -Force  
    Write-Host "  Movido: CORREÇÕES_APLICADAS.md" -ForegroundColor Green
}

# Verificar estrutura final
Write-Host "ESTRUTURA FINAL:" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASTA RAIZ (limpa):" -ForegroundColor Green
Get-ChildItem -File | Where-Object {$_.Name -like "*.md" -or $_.Name -like "*.env" -or $_.Name -like "*.txt" -or $_.Name -like "*.ps1"} | Select-Object Name

Write-Host ""
Write-Host "temp/ (para remover depois):" -ForegroundColor Yellow
if (Test-Path "temp") {
    Get-ChildItem "temp" | Select-Object Name
}

Write-Host ""
Write-Host "ORGANIZACAO CONCLUIDA!" -ForegroundColor Green
Write-Host ""
Write-Host "ARQUIVO PRINCIPAL: final/workflows/contacts_sync_final.json" -ForegroundColor Cyan
Write-Host "STATUS COMPLETO: PROJECT_STATUS_FINAL.md" -ForegroundColor Cyan

