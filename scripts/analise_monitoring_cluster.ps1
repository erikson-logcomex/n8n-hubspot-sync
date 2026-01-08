# 📊 ANÁLISE DE USO E DESEMPENHO - MONITORING CLUSTER
# Script para análise de recursos e otimização de custos

Write-Host "🔍 ANÁLISE DO MONITORING CLUSTER" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Configurações do cluster
$clusterName = "monitoring-cluster-optimized"
$region = "southamerica-east1-a"
$nodeCount = 2
$machineType = "e2-small"
$diskSize = 100
$diskType = "pd-balanced"

# Especificações e2-small
$e2SmallSpecs = @{
    vCPUs = 2
    Memory = "2 GB"
    MonthlyCost = 24.27  # USD por mês (região southamerica-east1)
}

Write-Host "`n📋 CONFIGURAÇÃO ATUAL DO CLUSTER:" -ForegroundColor Yellow
Write-Host "• Nome: $clusterName"
Write-Host "• Região: $region"
Write-Host "• Número de nós: $nodeCount"
Write-Host "• Tipo de máquina: $machineType"
Write-Host "• vCPUs por nó: $($e2SmallSpecs.vCPUs)"
Write-Host "• Memória por nó: $($e2SmallSpecs.Memory)"
Write-Host "• Disco por nó: ${diskSize}GB ($diskType)"

# Cálculo de custos
$totalvCPUs = $nodeCount * $e2SmallSpecs.vCPUs
$totalMemory = $nodeCount * 2  # GB
$monthlyCost = $nodeCount * $e2SmallSpecs.MonthlyCost

Write-Host "`n💰 CUSTOS ATUAIS:" -ForegroundColor Yellow
Write-Host "• Total de vCPUs: $totalvCPUs"
Write-Host "• Total de memória: ${totalMemory}GB"
Write-Host "• Custo mensal estimado: $${monthlyCost:F2} USD"

# Análise de uso atual (baseado nos dados coletados)
$currentUsage = @{
    CPU = @{
        Node1 = 2   # m (Prometheus)
        Node2 = 3   # m (Grafana)
        Total = 5   # m
    }
    Memory = @{
        Node1 = 8   # Mi (Prometheus)
        Node2 = 35  # Mi (Grafana)
        Total = 43  # Mi
    }
}

$totalCPUUsage = $currentUsage.CPU.Total
$totalMemoryUsage = $currentUsage.Memory.Total

# Conversão para percentuais
$cpuUsagePercent = ($totalCPUUsage / ($totalvCPUs * 1000)) * 100
$memoryUsagePercent = ($totalMemoryUsage / ($totalMemory * 1024)) * 100

Write-Host "`n📊 USO ATUAL DE RECURSOS:" -ForegroundColor Yellow
Write-Host "• CPU total usado: ${totalCPUUsage}m ($($cpuUsagePercent.ToString('F1'))%)"
Write-Host "• Memória total usada: ${totalMemoryUsage}Mi ($($memoryUsagePercent.ToString('F1'))%)"

# Análise de eficiência
Write-Host "`n⚡ ANÁLISE DE EFICIÊNCIA:" -ForegroundColor Yellow

if ($cpuUsagePercent -lt 30) {
    Write-Host "• CPU: SUBUTILIZADO - Uso muito baixo ($($cpuUsagePercent.ToString('F1'))%)" -ForegroundColor Red
} elseif ($cpuUsagePercent -lt 60) {
    Write-Host "• CPU: ADEQUADO - Uso moderado ($($cpuUsagePercent.ToString('F1'))%)" -ForegroundColor Green
} else {
    Write-Host "• CPU: ALTO USO - Pode precisar de mais recursos ($($cpuUsagePercent.ToString('F1'))%)" -ForegroundColor Yellow
}

if ($memoryUsagePercent -lt 30) {
    Write-Host "• Memória: SUBUTILIZADO - Uso muito baixo ($($memoryUsagePercent.ToString('F1'))%)" -ForegroundColor Red
} elseif ($memoryUsagePercent -lt 70) {
    Write-Host "• Memória: ADEQUADO - Uso moderado ($($memoryUsagePercent.ToString('F1'))%)" -ForegroundColor Green
} else {
    Write-Host "• Memória: ALTO USO - Pode precisar de mais recursos ($($memoryUsagePercent.ToString('F1'))%)" -ForegroundColor Yellow
}

# Problemas identificados
Write-Host "`n🚨 PROBLEMAS IDENTIFICADOS:" -ForegroundColor Red
Write-Host "• Uso de CPU extremamente baixo ($($cpuUsagePercent.ToString('F1'))%) - desperdício de recursos"
Write-Host "• Uso de memória muito baixo ($($memoryUsagePercent.ToString('F1'))%) - recursos subutilizados"
Write-Host "• Cluster com 2 nós para apenas 2 aplicações principais"
Write-Host "• HPA configurado mas não sendo utilizado efetivamente"

# Recomendações de otimização
Write-Host "`n💡 RECOMENDAÇÕES DE OTIMIZAÇÃO:" -ForegroundColor Green

Write-Host "`n1. REDUÇÃO DE NÓS:" -ForegroundColor Cyan
Write-Host "   • Reduzir de 2 para 1 nó (economia de ~50%)"
Write-Host "   • Custo mensal: $${monthlyCost:F2} → $${($monthlyCost * 1/2):F2} USD"
Write-Host "   • Economia mensal: $${($monthlyCost * 1/2):F2} USD"

Write-Host "`n2. OTIMIZAÇÃO DE RECURSOS:" -ForegroundColor Cyan
Write-Host "   • Definir resource requests/limits para Grafana e Prometheus"
Write-Host "   • Grafana: 256Mi RAM, 100m CPU"
Write-Host "   • Prometheus: 512Mi RAM, 250m CPU"

Write-Host "`n3. CORREÇÃO DE STORAGE:" -ForegroundColor Cyan
Write-Host "   • Resolver PVCs pendentes"
Write-Host "   • Usar storage classes adequadas"
Write-Host "   • Implementar backup automático"

Write-Host "`n4. MONITORAMENTO DE CUSTOS:" -ForegroundColor Cyan
Write-Host "   • Implementar alertas de uso de recursos"
Write-Host "   • Configurar budget alerts no GCP"
Write-Host "   • Revisar mensalmente a necessidade de recursos"

# Cenários de otimização
Write-Host "`n📈 CENÁRIOS DE OTIMIZAÇÃO:" -ForegroundColor Magenta

Write-Host "`nCENÁRIO 1 - Redução para 2 nós:" -ForegroundColor White
$scenario1Cost = $monthlyCost * 2/3
$scenario1Savings = $monthlyCost - $scenario1Cost
Write-Host "   • Custo mensal: $${scenario1Cost:F2} USD"
Write-Host "   • Economia: $${scenario1Savings:F2} USD/mês (${($scenario1Savings/$monthlyCost*100):F1}%)"

Write-Host "`nCENÁRIO 2 - Migração para e2-micro (1 nó):" -ForegroundColor White
$e2MicroCost = 12.14  # USD por mês
$scenario2Savings = $monthlyCost - $e2MicroCost
Write-Host "   • Custo mensal: $${e2MicroCost:F2} USD"
Write-Host "   • Economia: $${scenario2Savings:F2} USD/mês (${($scenario2Savings/$monthlyCost*100):F1}%)"
Write-Host "   • ⚠️  Risco: Pode ser insuficiente para picos de uso"

Write-Host "`nCENÁRIO 3 - Cluster Autopilot:" -ForegroundColor White
$autopilotCost = 0.10  # USD por vCPU/hora + 0.10 USD por GB/hora
$autopilotMonthly = ($totalvCPUs * $autopilotCost * 24 * 30) + ($totalMemory * 0.10 * 24 * 30)
$scenario3Savings = $monthlyCost - $autopilotMonthly
Write-Host "   • Custo mensal estimado: $${autopilotMonthly:F2} USD"
Write-Host "   • Economia: $${scenario3Savings:F2} USD/mês (${($scenario3Savings/$monthlyCost*100):F1}%)"
Write-Host "   • ✅ Benefício: Escalabilidade automática"

# Resumo final
Write-Host "`n🎯 RESUMO EXECUTIVO:" -ForegroundColor Yellow
Write-Host "• Cluster atual: SUBUTILIZADO ($($cpuUsagePercent.ToString('F1'))% CPU, $($memoryUsagePercent.ToString('F1'))% RAM)"
Write-Host "• Oportunidade de economia: $${($monthlyCost * 1/3):F2} - $${scenario2Savings:F2} USD/mês"
Write-Host "• Recomendação principal: Reduzir para 2 nós + corrigir configurações"
Write-Host "• Prioridade: ALTA - Desperdício significativo de recursos"

Write-Host "`n✅ PRÓXIMOS PASSOS:" -ForegroundColor Green
Write-Host "1. Resolver PVCs pendentes"
Write-Host "2. Definir resource requests/limits"
Write-Host "3. Testar com 2 nós"
Write-Host "4. Implementar monitoramento de custos"
Write-Host "5. Revisar mensalmente"

Write-Host "`n📊 Análise concluída em $(Get-Date)" -ForegroundColor Cyan
