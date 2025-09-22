# Script de Organização - Projeto n8n
# Data: 22/09/2025
# Organiza arquivos após correções aplicadas

Write-Host "🗂️ Organizando projeto n8n..." -ForegroundColor Green

# 1. Mover arquivos de análise para pasta analysis
Write-Host "📊 Organizando análises..." -ForegroundColor Yellow
if (!(Test-Path "analysis")) { New-Item -ItemType Directory -Name "analysis" }
Move-Item "ANALISE_CAUSAS_RAIZ_22_09_2025.md" "analysis/" -Force
Move-Item "ANALISE_FINAL_DNS_REDIS_22_09_2025.md" "analysis/" -Force

# 2. Mover documentação para pasta docs
Write-Host "📚 Organizando documentação..." -ForegroundColor Yellow
if (!(Test-Path "docs")) { New-Item -ItemType Directory -Name "docs" }
Move-Item "DOCUMENTACAO_IMPLEMENTACAO_N8N_GKE.md" "docs/" -Force
Move-Item "STATUS_RECOVERY_22_09_2025.md" "docs/" -Force
Move-Item "RESOLUCAO_FINAL_22_09_2025.md" "docs/" -Force

# 3. Mover resumos para pasta reports
Write-Host "📋 Organizando relatórios..." -ForegroundColor Yellow
if (!(Test-Path "reports")) { New-Item -ItemType Directory -Name "reports" }
Move-Item "RESUMO_SLACK_TEAM.md" "reports/" -Force

# 4. Mover scripts para pasta scripts
Write-Host "🔧 Organizando scripts..." -ForegroundColor Yellow
if (!(Test-Path "scripts")) { New-Item -ItemType Directory -Name "scripts" }
Move-Item "n8n-kubernetes-hosting/deploy-fixed.ps1" "scripts/" -Force
Move-Item "n8n-kubernetes-hosting/health-check.ps1" "scripts/" -Force

# 5. Criar arquivo de índice
Write-Host "📑 Criando índice..." -ForegroundColor Yellow
$indexContent = @"
# 📋 ÍNDICE DO PROJETO n8n

## 🗂️ ESTRUTURA ORGANIZADA

### 📊 Análises
- analysis/ANALISE_CAUSAS_RAIZ_22_09_2025.md - Análise das causas do problema
- analysis/ANALISE_FINAL_DNS_REDIS_22_09_2025.md - Análise final do DNS Redis

### 📚 Documentação
- docs/DOCUMENTACAO_IMPLEMENTACAO_N8N_GKE.md - Documentação de implementação
- docs/STATUS_RECOVERY_22_09_2025.md - Status do processo de recovery
- docs/RESOLUCAO_FINAL_22_09_2025.md - Resolução final completa

### 📋 Relatórios
- reports/RESUMO_SLACK_TEAM.md - Resumo para o time (Slack)

### 🔧 Scripts
- scripts/deploy-fixed.ps1 - Script de deploy com correções
- scripts/health-check.ps1 - Script de verificação de saúde

### ⚙️ Configurações Kubernetes
- n8n-kubernetes-hosting/n8n-deployment.yaml - Deployment principal (corrigido)
- n8n-kubernetes-hosting/n8n-worker-deployment.yaml - Workers (corrigido)
- n8n-kubernetes-hosting/redis-service-patch.yaml - Patch do serviço Redis
- n8n-kubernetes-hosting/n8n-config-consolidated.yaml - Configuração consolidada

## 🚀 COMO USAR

### Deploy Rápido
```powershell
cd n8n-kubernetes-hosting
kubectl apply -f n8n-config-consolidated.yaml
```

### Verificação de Saúde
```powershell
cd scripts
.\health-check.ps1
```

## 📊 STATUS ATUAL
- ✅ Sistema 100% funcional
- ✅ Redis via DNS (resiliente)
- ✅ PostgreSQL conectado
- ✅ 24 workflows ativos
- ✅ Resiliência a mudanças de IP

---
*Organizado em: 22/09/2025*
"@

$indexContent | Out-File -FilePath "INDEX.md" -Encoding UTF8

Write-Host "✅ Projeto organizado com sucesso!" -ForegroundColor Green
Write-Host "📁 Estrutura criada:" -ForegroundColor Cyan
Write-Host "  - analysis/ (análises)" -ForegroundColor White
Write-Host "  - docs/ (documentação)" -ForegroundColor White
Write-Host "  - reports/ (relatórios)" -ForegroundColor White
Write-Host "  - scripts/ (scripts)" -ForegroundColor White
Write-Host "  - n8n-kubernetes-hosting/ (configurações K8s)" -ForegroundColor White
Write-Host "  - INDEX.md (índice do projeto)" -ForegroundColor White
