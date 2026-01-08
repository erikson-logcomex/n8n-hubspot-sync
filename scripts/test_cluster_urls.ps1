# Script para testar qual cluster está respondendo nas URLs
# Identifica se está acessando o cluster antigo ou novo

Write-Host "🔍 TESTANDO QUAL CLUSTER ESTÁ RESPONDENDO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# URLs para testar
$grafanaUrl = "https://grafana-logcomex.34-8-167-169.nip.io"
$prometheusUrl = "https://prometheus-logcomex.35-186-250-84.nip.io"

Write-Host "`n📊 Testando Grafana..." -ForegroundColor Yellow
try {
    $grafanaResponse = Invoke-WebRequest -Uri $grafanaUrl -Method GET -TimeoutSec 10 -SkipCertificateCheck
    Write-Host "✅ Grafana: Status $($grafanaResponse.StatusCode)" -ForegroundColor Green
    Write-Host "   URL: $grafanaUrl" -ForegroundColor White
    
    # Verificar se é o cluster correto (novo)
    if ($grafanaResponse.Content -match "Grafana") {
        Write-Host "   ✅ Resposta do Grafana detectada" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Grafana: Erro - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📈 Testando Prometheus..." -ForegroundColor Yellow
try {
    $prometheusResponse = Invoke-WebRequest -Uri $prometheusUrl -Method GET -TimeoutSec 10 -SkipCertificateCheck
    Write-Host "✅ Prometheus: Status $($prometheusResponse.StatusCode)" -ForegroundColor Green
    Write-Host "   URL: $prometheusUrl" -ForegroundColor White
    
    # Verificar se é o cluster correto (novo)
    if ($prometheusResponse.Content -match "Prometheus") {
        Write-Host "   ✅ Resposta do Prometheus detectada" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Prometheus: Erro - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🔍 VERIFICAÇÃO ADICIONAL:" -ForegroundColor Cyan
Write-Host "1. Acesse as URLs no navegador:" -ForegroundColor White
Write-Host "   - Grafana: $grafanaUrl" -ForegroundColor Yellow
Write-Host "   - Prometheus: $prometheusUrl" -ForegroundColor Yellow

Write-Host "`n2. Verifique se consegue fazer login no Grafana:" -ForegroundColor White
Write-Host "   - Usuário: admin" -ForegroundColor Yellow
Write-Host "   - Senha: admin123" -ForegroundColor Yellow

Write-Host "`n3. Se funcionar, está acessando o cluster NOVO (otimizado)" -ForegroundColor Green
Write-Host "4. Se não funcionar, ainda está acessando o cluster ANTIGO" -ForegroundColor Red

Write-Host "`n💡 DICA: Para ter certeza, você pode:" -ForegroundColor Cyan
Write-Host "   - Fazer login no Grafana" -ForegroundColor White
Write-Host "   - Verificar se os dashboards estão lá" -ForegroundColor White
Write-Host "   - Verificar se os dados do Prometheus estão sendo coletados" -ForegroundColor White

Write-Host "`n📊 Teste concluído em $(Get-Date)" -ForegroundColor Cyan


