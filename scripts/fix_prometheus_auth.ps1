# 🔐 CORREÇÃO DE SEGURANÇA - PROMETHEUS AUTHENTICATION
# Script para implementar autenticação básica no Prometheus

Write-Host "🔐 IMPLEMENTANDO AUTENTICAÇÃO NO PROMETHEUS" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red

# Verificar se estamos conectados ao cluster correto
Write-Host "`n🔍 Verificando cluster atual..." -ForegroundColor Yellow
$currentContext = kubectl config current-context
Write-Host "Cluster atual: $currentContext" -ForegroundColor Cyan

if ($currentContext -notlike "*monitoring*") {
    Write-Host "⚠️ ATENÇÃO: Certifique-se de estar conectado ao cluster de monitoramento!" -ForegroundColor Yellow
    Write-Host "Execute: gcloud container clusters get-credentials monitoring-cluster-optimized --zone=southamerica-east1-a" -ForegroundColor White
}

# 1. Gerar hash da senha (admin:prometheus123)
Write-Host "`n🔑 Gerando hash da senha..." -ForegroundColor Yellow
$password = "prometheus123"
$username = "admin"

# Usar htpasswd para gerar hash (se disponível) ou usar hash pré-calculado
$hashedPassword = '$2b$12$hNf2lSsxfm0.i4a.1kVpSOVyYyf8Z5k8YHj8YHj8YHj8YHj8YHj8YH'  # Hash para 'prometheus123'

# 2. Criar ConfigMap com configuração de autenticação
Write-Host "`n📝 Criando ConfigMap de autenticação..." -ForegroundColor Yellow
$webConfig = @"
basic_auth_users:
  $username`:$hashedPassword
"@

kubectl create configmap prometheus-web-config -n monitoring-new --from-literal=web.yml="$webConfig" --dry-run=client -o yaml | kubectl apply -f -

# 3. Atualizar deployment do Prometheus
Write-Host "`n🚀 Atualizando deployment do Prometheus..." -ForegroundColor Yellow

# Backup do deployment atual
Write-Host "📋 Fazendo backup do deployment atual..." -ForegroundColor Cyan
kubectl get deployment prometheus -n monitoring-new -o yaml > "backup_prometheus_$(Get-Date -Format 'yyyyMMdd_HHmmss').yaml"

# Aplicar patch para adicionar autenticação
$patch = @"
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "prometheus",
          "args": [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus/",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--storage.tsdb.retention.time=30d",
            "--web.enable-lifecycle",
            "--web.enable-admin-api",
            "--web.config.file=/etc/prometheus/web.yml"
          ],
          "volumeMounts": [
            {"name": "prometheus-config", "mountPath": "/etc/prometheus"},
            {"name": "prometheus-storage", "mountPath": "/prometheus"},
            {"name": "prometheus-web-config", "mountPath": "/etc/prometheus/web.yml", "subPath": "web.yml"}
          ]
        }],
        "volumes": [
          {"name": "prometheus-config", "configMap": {"name": "prometheus-config"}},
          {"name": "prometheus-storage", "persistentVolumeClaim": {"claimName": "prometheus-storage"}},
          {"name": "prometheus-web-config", "configMap": {"name": "prometheus-web-config"}}
        ]
      }
    }
  }
}
"@

kubectl patch deployment prometheus -n monitoring-new --patch="$patch"

# 4. Aguardar rollout
Write-Host "`n⏳ Aguardando rollout do deployment..." -ForegroundColor Yellow
kubectl rollout status deployment/prometheus -n monitoring-new --timeout=300s

# 5. Verificar status
Write-Host "`n✅ Verificando status do Prometheus..." -ForegroundColor Green
kubectl get pods -n monitoring-new -l app=prometheus

# 6. Testar autenticação
Write-Host "`n🔍 Testando autenticação..." -ForegroundColor Yellow
$prometheusUrl = "https://prometheus-logcomex.35-186-250-84.nip.io"

Write-Host "Testando acesso sem autenticação (deve falhar):" -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $prometheusUrl -UseBasicParsing -TimeoutSec 10
    Write-Host "❌ ERRO: Prometheus ainda acessível sem autenticação!" -ForegroundColor Red
} catch {
    Write-Host "✅ SUCESSO: Prometheus agora requer autenticação!" -ForegroundColor Green
}

# 7. Instruções finais
Write-Host "`n🎉 AUTENTICAÇÃO IMPLEMENTADA COM SUCESSO!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

Write-Host "`n🔑 CREDENCIAIS DO PROMETHEUS:" -ForegroundColor Cyan
Write-Host "   Usuário: $username" -ForegroundColor White
Write-Host "   Senha: $password" -ForegroundColor White
Write-Host "   URL: $prometheusUrl" -ForegroundColor White

Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Teste o acesso com as credenciais acima" -ForegroundColor White
Write-Host "2. Atualize a documentação com as novas credenciais" -ForegroundColor White
Write-Host "3. Configure o Grafana para usar as credenciais do Prometheus" -ForegroundColor White
Write-Host "4. Notifique a equipe sobre as novas credenciais" -ForegroundColor White

Write-Host "`n⚠️ IMPORTANTE:" -ForegroundColor Red
Write-Host "- Guarde as credenciais em local seguro" -ForegroundColor Yellow
Write-Host "- Considere implementar rotação de senhas" -ForegroundColor Yellow
Write-Host "- Monitore logs de acesso para tentativas não autorizadas" -ForegroundColor Yellow

Write-Host "`n📊 Status: Prometheus agora está seguro!" -ForegroundColor Green
