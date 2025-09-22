# Script de Organização Simples - Projeto n8n
# Data: 22/09/2025

Write-Host "🗂️ Organizando projeto n8n..." -ForegroundColor Green

# Criar diretórios
Write-Host "📁 Criando diretórios..." -ForegroundColor Yellow
if (!(Test-Path "analysis")) { New-Item -ItemType Directory -Name "analysis" }
if (!(Test-Path "docs")) { New-Item -ItemType Directory -Name "docs" }
if (!(Test-Path "reports")) { New-Item -ItemType Directory -Name "reports" }
if (!(Test-Path "scripts")) { New-Item -ItemType Directory -Name "scripts" }

# Mover arquivos de análise
Write-Host "📊 Movendo análises..." -ForegroundColor Yellow
if (Test-Path "ANALISE_CAUSAS_RAIZ_22_09_2025.md") { Move-Item "ANALISE_CAUSAS_RAIZ_22_09_2025.md" "analysis/" -Force }
if (Test-Path "ANALISE_FINAL_DNS_REDIS_22_09_2025.md") { Move-Item "ANALISE_FINAL_DNS_REDIS_22_09_2025.md" "analysis/" -Force }

# Mover documentação
Write-Host "📚 Movendo documentação..." -ForegroundColor Yellow
if (Test-Path "DOCUMENTACAO_IMPLEMENTACAO_N8N_GKE.md") { Move-Item "DOCUMENTACAO_IMPLEMENTACAO_N8N_GKE.md" "docs/" -Force }
if (Test-Path "STATUS_RECOVERY_22_09_2025.md") { Move-Item "STATUS_RECOVERY_22_09_2025.md" "docs/" -Force }
if (Test-Path "RESOLUCAO_FINAL_22_09_2025.md") { Move-Item "RESOLUCAO_FINAL_22_09_2025.md" "docs/" -Force }

# Mover relatórios
Write-Host "📋 Movendo relatórios..." -ForegroundColor Yellow
if (Test-Path "RESUMO_SLACK_TEAM.md") { Move-Item "RESUMO_SLACK_TEAM.md" "reports/" -Force }

# Mover scripts
Write-Host "🔧 Movendo scripts..." -ForegroundColor Yellow
if (Test-Path "n8n-kubernetes-hosting/deploy-fixed.ps1") { Move-Item "n8n-kubernetes-hosting/deploy-fixed.ps1" "scripts/" -Force }
if (Test-Path "n8n-kubernetes-hosting/health-check.ps1") { Move-Item "n8n-kubernetes-hosting/health-check.ps1" -Force }

Write-Host "✅ Projeto organizado com sucesso!" -ForegroundColor Green
Write-Host "📁 Estrutura criada:" -ForegroundColor Cyan
Write-Host "  - analysis/ (análises)" -ForegroundColor White
Write-Host "  - docs/ (documentação)" -ForegroundColor White
Write-Host "  - reports/ (relatórios)" -ForegroundColor White
Write-Host "  - scripts/ (scripts)" -ForegroundColor White
Write-Host "  - n8n-kubernetes-hosting/ (configurações K8s)" -ForegroundColor White
