# Script PowerShell para criar tabela no banco hubspot-sync
# Executa automaticamente o SQL com as credenciais corretas

Write-Host "🚀 CRIANDO TABELA HUBSPOT NO BANCO CORRETO" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

# Verificar se arquivo SQL existe
if (-not (Test-Path "hubspot_contacts_table_PADRAO_CORRETO.sql")) {
    Write-Host "❌ Arquivo hubspot_contacts_table_PADRAO_CORRETO.sql não encontrado!" -ForegroundColor Red
    exit 1
}

# Credenciais do banco hubspot-sync
$env:PGHOST = "35.239.64.56"
$env:PGPORT = "5432"
$env:PGDATABASE = "hubspot-sync"
$env:PGUSER = "meetrox_user"
$env:PGPASSWORD = ":NZ%A{%Yi$3\p=mC"

Write-Host "🐘 Conectando ao banco hubspot-sync..." -ForegroundColor Yellow
Write-Host "   Host: $env:PGHOST" -ForegroundColor Gray
Write-Host "   Database: $env:PGDATABASE" -ForegroundColor Gray
Write-Host "   User: $env:PGUSER" -ForegroundColor Gray

try {
    # Executar SQL
    Write-Host "`n📄 Executando SQL..." -ForegroundColor Yellow
    psql -f hubspot_contacts_table_PADRAO_CORRETO.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ TABELA CRIADA COM SUCESSO!" -ForegroundColor Green
        
        # Verificar se tabela foi criada
        Write-Host "`n🔍 Verificando tabela criada..." -ForegroundColor Yellow
        $checkQuery = "SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_name = 'contacts' ORDER BY ordinal_position LIMIT 10;"
        psql -c $checkQuery
        
        Write-Host "`n📊 Verificando estatísticas..." -ForegroundColor Yellow
        $statsQuery = "SELECT COUNT(*) as total_colunas FROM information_schema.columns WHERE table_name = 'contacts';"
        psql -c $statsQuery
        
    } else {
        Write-Host "`n❌ ERRO na criação da tabela!" -ForegroundColor Red
        Write-Host "   Código de saída: $LASTEXITCODE" -ForegroundColor Red
    }
    
} catch {
    Write-Host "`n❌ ERRO ao executar SQL:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`n💡 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Importar workflow n8n: n8n_workflow_hubspot_sync_PADRAO_CORRETO.json" -ForegroundColor Gray
Write-Host "   2. Configurar credenciais no n8n" -ForegroundColor Gray
Write-Host "   3. Executar primeira sincronização" -ForegroundColor Gray

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
