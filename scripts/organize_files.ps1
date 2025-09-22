# Script para organizar arquivos do projeto n8n HubSpot Sync
# Execute com: powershell -ExecutionPolicy Bypass .\organize_files.ps1

Write-Host "🧹 ORGANIZANDO ARQUIVOS DO PROJETO..." -ForegroundColor Cyan

# Criar estrutura se não existir
Write-Host "📁 Criando estrutura de pastas..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "temp" -Force | Out-Null
New-Item -ItemType Directory -Path "scripts\fixes" -Force | Out-Null  
New-Item -ItemType Directory -Path "final\workflows" -Force | Out-Null

# Mover workflows obsoletos para temp
Write-Host "🗑️ Movendo workflows obsoletos para temp..." -ForegroundColor Yellow
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
        Write-Host "  ✅ Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Não encontrado: $file" -ForegroundColor Gray
    }
}

# Mover arquivos SQL temporários para temp
Write-Host "🗑️ Movendo arquivos SQL temporários para temp..." -ForegroundColor Yellow
$tempSqlFiles = @(
    "fix_field_sizes.sql",
    "fix_table_not_null.sql"
)

foreach ($file in $tempSqlFiles) {
    if (Test-Path $file) {
        Move-Item $file "temp\" -Force
        Write-Host "  ✅ Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Não encontrado: $file" -ForegroundColor Gray
    }
}

# Mover scripts de correção para scripts/fixes
Write-Host "🔧 Movendo scripts de correção para scripts/fixes..." -ForegroundColor Yellow
$fixScripts = @(
    "fix_field_sizes.py",
    "fix_contacts_table.py"
)

foreach ($file in $fixScripts) {
    if (Test-Path $file) {
        Move-Item $file "scripts\fixes\" -Force
        Write-Host "  ✅ Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Não encontrado: $file" -ForegroundColor Gray
    }
}

# Mover documentação para docs
Write-Host "📚 Movendo documentação para docs..." -ForegroundColor Yellow
$docFiles = @(
    "STATUS_WORKFLOW.md"
)

foreach ($file in $docFiles) {
    if (Test-Path $file) {
        Move-Item $file "docs\" -Force
        Write-Host "  ✅ Movido: $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Não encontrado: $file" -ForegroundColor Gray
    }
}

# Verificar estrutura final
Write-Host "📋 ESTRUTURA FINAL:" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 PASTA RAIZ (limpa):" -ForegroundColor Green
Get-ChildItem -File | Where-Object {$_.Name -like "*.md" -or $_.Name -like "*.env" -or $_.Name -like "*.txt" -or $_.Name -like "*.ps1"} | Select-Object Name | Format-Table -HideTableHeaders

Write-Host "📁 final/workflows/:" -ForegroundColor Green  
if (Test-Path "final\workflows") {
    Get-ChildItem "final\workflows" | Select-Object Name | Format-Table -HideTableHeaders
}

Write-Host "📁 scripts/fixes/:" -ForegroundColor Green
if (Test-Path "scripts\fixes") {
    Get-ChildItem "scripts\fixes" | Select-Object Name | Format-Table -HideTableHeaders
}

Write-Host "📁 temp/:" -ForegroundColor Yellow
if (Test-Path "temp") {
    Get-ChildItem "temp" | Select-Object Name | Format-Table -HideTableHeaders
}

Write-Host ""
Write-Host "✅ ORGANIZAÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 ARQUIVO PRINCIPAL: final/workflows/contacts_sync_final.json" -ForegroundColor Cyan
Write-Host "📋 STATUS COMPLETO: PROJECT_STATUS_FINAL.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🗑️ Para limpar completamente, delete a pasta temp/ quando confirmar que tudo está funcionando." -ForegroundColor Gray
