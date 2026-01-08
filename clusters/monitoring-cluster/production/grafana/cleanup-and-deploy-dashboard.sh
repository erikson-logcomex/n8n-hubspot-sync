#!/bin/bash

# 🧹 Script de Limpeza e Implementação do Dashboard N8N Otimizado
# Data: $(date)
# Objetivo: Substituir dashboard atual por versão focada em workflows

echo "🔍 AUDITORIA: Dashboards N8N - Limpeza e Otimização"
echo "=================================================="

echo ""
echo "📊 Situação Atual dos Dashboards:"
kubectl get configmaps -n monitoring-new | grep dashboard

echo ""
echo "🗑️ Removendo dashboards antigos desnecessários..."

# Lista de dashboards antigos para remoção
OLD_DASHBOARDS=(
    "n8n-simple-working-dashboard"
    "n8n-dashboard-clean"
    "grafana-dashboard-empresas"
    "grafana-dashboard-meetrox"
    "grafana-dashboard-personas"
    "grafana-dashboard-processamento-massa"
)

for dashboard in "${OLD_DASHBOARDS[@]}"; do
    if kubectl get configmap "$dashboard" -n monitoring-new &> /dev/null; then
        echo "  ❌ Removendo: $dashboard"
        kubectl delete configmap "$dashboard" -n monitoring-new
    else
        echo "  ✅ Não encontrado: $dashboard (já limpo)"
    fi
done

echo ""
echo "🚀 Implementando novo dashboard focado em workflows..."

# Backup do dashboard atual (caso necessário)
echo "  💾 Fazendo backup do dashboard atual..."
kubectl get configmap n8n-complete-dashboard -n monitoring-new -o yaml > "backup-n8n-complete-dashboard-$(date +%Y%m%d-%H%M%S).yaml"

# Aplicar novo dashboard
echo "  🔧 Aplicando novo dashboard workflow-focused..."
kubectl apply -f n8n-workflow-focused-configmap.yaml

echo ""
echo "🔄 Reiniciando Grafana para aplicar mudanças..."
kubectl rollout restart deployment grafana -n monitoring-new

echo ""
echo "⏳ Aguardando Grafana ficar pronto..."
kubectl rollout status deployment grafana -n monitoring-new

echo ""
echo "✅ CONCLUÍDO: Dashboard N8N Otimizado Implementado!"
echo ""
echo "🌐 Acesse o Grafana em: https://grafana-logcomex.34-8-167-169.nip.io"
echo ""
echo "📊 Novo Dashboard Características:"
echo "  • ✅ Foco em métricas de workflows (não apenas sistema)"
echo "  • ✅ Execuções por hora/minuto"
echo "  • ✅ Taxa de sucesso/falha em tempo real"
echo "  • ✅ Top workflows mais executados"
echo "  • ✅ Métricas de performance específicas do N8N"
echo ""
echo "🧹 Dashboards removidos (limpeza):"
for dashboard in "${OLD_DASHBOARDS[@]}"; do
    echo "  • $dashboard"
done