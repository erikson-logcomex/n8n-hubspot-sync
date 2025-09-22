# Script PowerShell para executar análise de propriedades do HubSpot
# Automatiza a instalação de dependências e execução do script

Write-Host "🚀 ANÁLISE DE PROPRIEDADES HUBSPOT → POSTGRESQL" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

# Verificar se Python está instalado
Write-Host "🐍 Verificando instalação do Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python encontrado: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python não encontrado. Instale Python 3.7+ antes de continuar." -ForegroundColor Red
    Write-Host "   Download: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Verificar se arquivo .env existe
Write-Host "📋 Verificando arquivo .env..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "✅ Arquivo .env encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ Arquivo .env não encontrado!" -ForegroundColor Red
    Write-Host "   Certifique-se de que o arquivo .env está no mesmo diretório" -ForegroundColor Yellow
    exit 1
}

# Verificar se pip está disponível
Write-Host "📦 Verificando pip..." -ForegroundColor Yellow
try {
    $pipVersion = pip --version 2>&1
    Write-Host "✅ pip encontrado: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ pip não encontrado. Instale pip antes de continuar." -ForegroundColor Red
    exit 1
}

# Instalar dependências
Write-Host "📥 Instalando dependências Python..." -ForegroundColor Yellow
try {
    pip install -r requirements.txt --quiet
    Write-Host "✅ Dependências instaladas com sucesso" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao instalar dependências:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "💡 Tente executar manualmente: pip install -r requirements.txt" -ForegroundColor Yellow
    exit 1
}

# Executar script de análise
Write-Host "`n🔍 Executando análise das propriedades do HubSpot..." -ForegroundColor Yellow
Write-Host "   Isso pode levar alguns minutos..." -ForegroundColor Gray

try {
    python test_hubspot_properties.py
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "`n🎉 Análise concluída com sucesso!" -ForegroundColor Green
        Write-Host "📁 Verifique os arquivos gerados no diretório atual" -ForegroundColor Yellow
    } else {
        Write-Host "`n❌ Análise falhou com código de saída: $exitCode" -ForegroundColor Red
    }
} catch {
    Write-Host "`n❌ Erro ao executar análise:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`n📋 Arquivos que podem ter sido gerados:" -ForegroundColor Yellow
Get-ChildItem -Filter "*hubspot*" | ForEach-Object {
    Write-Host "   • $($_.Name)" -ForegroundColor Cyan
}

Write-Host "`n💡 Para executar novamente, use: .\run_hubspot_analysis.ps1" -ForegroundColor Gray
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
