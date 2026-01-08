#!/bin/bash

# 🧹 Script para Limpeza de Dashboards JSON Locais não utilizados
# Data: $(date)
# Objetivo: Remover apenas arquivos JSON locais que não estão em produção

echo "🔍 AUDITORIA: Identificando Dashboards em Produção vs Locais"
echo "=========================================================="

echo ""
echo "📊 Dashboards atualmente em PRODUÇÃO (Kubernetes):"

# Conectar ao cluster de monitoramento primeiro
gcloud container clusters get-credentials monitoring-cluster-optimized --zone=southamerica-east1-a --quiet

# Listar dashboards em produção
PRODUCTION_DASHBOARDS=($(kubectl get configmaps -n monitoring-new | grep dashboard | awk '{print $1}'))

echo "ConfigMaps em produção:"
for dashboard in "${PRODUCTION_DASHBOARDS[@]}"; do
    echo "  ✅ $dashboard"
done

echo ""
echo "📁 Dashboards JSON LOCAIS encontrados:"

# Encontrar todos os arquivos JSON de dashboard locais
LOCAL_JSON_FILES=($(find clusters/monitoring-cluster/production/grafana/ -name "*.json" -type f))

echo "Arquivos JSON locais:"
for file in "${LOCAL_JSON_FILES[@]}"; do
    filename=$(basename "$file")
    echo "  📄 $filename"
done

echo ""
echo "🗑️ Identificando arquivos JSON locais para REMOÇÃO:"

# Lista de arquivos a serem removidos (não estão em produção)
TO_REMOVE=()

for file in "${LOCAL_JSON_FILES[@]}"; do
    filename=$(basename "$file" .json)
    
    # Verificar se existe um ConfigMap correspondente em produção
    FOUND=false
    for prod_dashboard in "${PRODUCTION_DASHBOARDS[@]}"; do
        if [[ "$prod_dashboard" == *"$filename"* ]] || [[ "$filename" == *"$(echo $prod_dashboard | sed 's/-dashboard//' | sed 's/-configmap//')"* ]]; then
            FOUND=true
            break
        fi
    done
    
    if [ "$FOUND" = false ]; then
        TO_REMOVE+=("$file")
        echo "  ❌ $(basename $file) - Não está em produção"
    else
        echo "  ✅ $(basename $file) - MANTIDO (está em uso)"
    fi
done

echo ""
if [ ${#TO_REMOVE[@]} -eq 0 ]; then
    echo "✨ RESULTADO: Nenhum arquivo para remover. Todos os JSONs locais estão sendo usados!"
else
    echo "🧹 LIMPEZA: Removendo ${#TO_REMOVE[@]} arquivo(s) não utilizados..."
    
    for file in "${TO_REMOVE[@]}"; do
        echo "  🗑️ Removendo: $(basename $file)"
        rm "$file"
    done
    
    echo ""
    echo "✅ CONCLUÍDO: Limpeza realizada com sucesso!"
fi

echo ""
echo "📊 RESUMO FINAL:"
echo "  • Dashboards em produção: ${#PRODUCTION_DASHBOARDS[@]}"
echo "  • Arquivos JSON locais encontrados: ${#LOCAL_JSON_FILES[@]}"
echo "  • Arquivos removidos: ${#TO_REMOVE[@]}"
echo "  • Arquivos mantidos: $((${#LOCAL_JSON_FILES[@]} - ${#TO_REMOVE[@]}))"

echo ""
echo "🎯 PRÓXIMOS PASSOS RECOMENDADOS:"
echo "  1. Testar novo dashboard completo com métricas de containers"
echo "  2. Configurar cAdvisor para métricas detalhadas dos pods"
echo "  3. Implementar alertas baseados nas novas métricas"