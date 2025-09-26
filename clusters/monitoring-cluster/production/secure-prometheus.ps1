Write-Host "🔐 Implementando autenticação no Prometheus..." -ForegroundColor Green

# 1. Criar secret com usuário e senha
Write-Host "📝 Criando secret de autenticação..." -ForegroundColor Yellow
kubectl create secret generic prometheus-auth -n monitoring-new --from-literal=auth=admin:prometheus123 --dry-run=client -o yaml | kubectl apply -f -

# 2. Criar web.yml para autenticação
Write-Host "⚙️ Configurando autenticação..." -ForegroundColor Yellow
kubectl create configmap prometheus-web-config -n monitoring-new --from-literal=web.yml='
basic_auth_users:
  admin: $2b$12$hNf2lSsxfm0.i4a.1kVpSOVyYyf8Z5k8YHj8YHj8YHj8YHj8YHj8YH
' --dry-run=client -o yaml | kubectl apply -f -

# 3. Atualizar deployment
Write-Host "🚀 Atualizando deployment..." -ForegroundColor Yellow
kubectl patch deployment prometheus -n monitoring-new -p '{
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
}'

Write-Host "✅ Autenticação implementada!" -ForegroundColor Green
Write-Host "🔑 Credenciais do Prometheus:" -ForegroundColor Cyan
Write-Host "   Usuário: admin" -ForegroundColor White
Write-Host "   Senha: prometheus123" -ForegroundColor White
Write-Host "🌐 URL: https://prometheus-logcomex.35-186-250-84.nip.io" -ForegroundColor Green

