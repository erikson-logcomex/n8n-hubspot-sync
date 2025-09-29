# ANALISE DE USO E DESEMPENHO - MONITORING CLUSTER
# Script para analise de recursos e otimizacao de custos

Write-Host "ANALISE DO MONITORING CLUSTER" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Configuracoes do cluster
$clusterName = "monitoring-cluster"
$region = "southamerica-east1"
$nodeCount = 3
$machineType = "e2-small"
$diskSize = 100
$diskType = "pd-balanced"

# Especificacoes e2-small
$e2SmallSpecs = @{
    vCPUs = 2
    Memory = "2 GB"
    MonthlyCost = 24.27  # USD por mes (regiao southamerica-east1)
}

Write-Host "`nCONFIGURACAO ATUAL DO CLUSTER:" -ForegroundColor Yellow
Write-Host "- Nome: $clusterName"
Write-Host "- Regiao: $region"
Write-Host "- Numero de nos: $nodeCount"
Write-Host "- Tipo de maquina: $machineType"
Write-Host "- vCPUs por no: $($e2SmallSpecs.vCPUs)"
Write-Host "- Memoria por no: $($e2SmallSpecs.Memory)"
Write-Host "- Disco por no: ${diskSize}GB ($diskType)"

# Calculo de custos
$totalvCPUs = $nodeCount * $e2SmallSpecs.vCPUs
$totalMemory = $nodeCount * 2  # GB
$monthlyCost = $nodeCount * $e2SmallSpecs.MonthlyCost

Write-Host "`nCUSTOS ATUAIS:" -ForegroundColor Yellow
Write-Host "- Total de vCPUs: $totalvCPUs"
Write-Host "- Total de memoria: ${totalMemory}GB"
Write-Host "- Custo mensal estimado: $${monthlyCost:F2} USD"

# Analise de uso atual (baseado nos dados coletados)
$currentUsage = @{
    CPU = @{
        Node1 = 97  # m
        Node2 = 86  # m
        Node3 = 59  # m
        Total = 242 # m
    }
    Memory = @{
        Node1 = 979  # Mi
        Node2 = 840  # Mi
        Node3 = 803  # Mi
        Total = 2622 # Mi
    }
}

$totalCPUUsage = $currentUsage.CPU.Total
$totalMemoryUsage = $currentUsage.Memory.Total

# Conversao para percentuais
$cpuUsagePercent = ($totalCPUUsage / ($totalvCPUs * 1000)) * 100
$memoryUsagePercent = ($totalMemoryUsage / ($totalMemory * 1024)) * 100

Write-Host "`nUSO ATUAL DE RECURSOS:" -ForegroundColor Yellow
Write-Host "- CPU total usado: ${totalCPUUsage}m ($($cpuUsagePercent.ToString('F1')) por cento)"
Write-Host "- Memoria total usada: ${totalMemoryUsage}Mi ($($memoryUsagePercent.ToString('F1')) por cento)"

# Analise de eficiencia
Write-Host "`nANALISE DE EFICIENCIA:" -ForegroundColor Yellow

if ($cpuUsagePercent -lt 30) {
    Write-Host "- CPU: SUBUTILIZADO - Uso muito baixo ($($cpuUsagePercent.ToString('F1')) por cento)" -ForegroundColor Red
} elseif ($cpuUsagePercent -lt 60) {
    Write-Host "- CPU: ADEQUADO - Uso moderado ($($cpuUsagePercent.ToString('F1')) por cento)" -ForegroundColor Green
} else {
    Write-Host "- CPU: ALTO USO - Pode precisar de mais recursos ($($cpuUsagePercent.ToString('F1')) por cento)" -ForegroundColor Yellow
}

if ($memoryUsagePercent -lt 30) {
    Write-Host "- Memoria: SUBUTILIZADO - Uso muito baixo ($($memoryUsagePercent.ToString('F1')) por cento)" -ForegroundColor Red
} elseif ($memoryUsagePercent -lt 70) {
    Write-Host "- Memoria: ADEQUADO - Uso moderado ($($memoryUsagePercent.ToString('F1')) por cento)" -ForegroundColor Green
} else {
    Write-Host "- Memoria: ALTO USO - Pode precisar de mais recursos ($($memoryUsagePercent.ToString('F1')) por cento)" -ForegroundColor Yellow
}

# Problemas identificados
Write-Host "`nPROBLEMAS IDENTIFICADOS:" -ForegroundColor Red
Write-Host "- PVCs em estado Pending (grafana-storage, prometheus-storage)"
Write-Host "- Grafana e Prometheus sem resource requests/limits definidos"
Write-Host "- Uso de CPU muito baixo ($($cpuUsagePercent.ToString('F1')) por cento) - desperdicio de recursos"
Write-Host "- Cluster com 3 nos para apenas 2 aplicacoes principais"

# Recomendacoes de otimizacao
Write-Host "`nRECOMENDACOES DE OTIMIZACAO:" -ForegroundColor Green

Write-Host "`n1. REDUCAO DE NOS:" -ForegroundColor Cyan
Write-Host "   - Reduzir de 3 para 2 nos (economia de ~33 por cento)"
Write-Host "   - Custo mensal: $${monthlyCost:F2} para $${($monthlyCost * 2/3):F2} USD"
Write-Host "   - Economia mensal: $${($monthlyCost * 1/3):F2} USD"

Write-Host "`n2. OTIMIZACAO DE RECURSOS:" -ForegroundColor Cyan
Write-Host "   - Definir resource requests/limits para Grafana e Prometheus"
Write-Host "   - Grafana: 256Mi RAM, 100m CPU"
Write-Host "   - Prometheus: 512Mi RAM, 250m CPU"

Write-Host "`n3. CORRECAO DE STORAGE:" -ForegroundColor Cyan
Write-Host "   - Resolver PVCs pendentes"
Write-Host "   - Usar storage classes adequadas"
Write-Host "   - Implementar backup automatico"

Write-Host "`n4. MONITORAMENTO DE CUSTOS:" -ForegroundColor Cyan
Write-Host "   - Implementar alertas de uso de recursos"
Write-Host "   - Configurar budget alerts no GCP"
Write-Host "   - Revisar mensalmente a necessidade de recursos"

# Cenarios de otimizacao
Write-Host "`nCENARIOS DE OTIMIZACAO:" -ForegroundColor Magenta

Write-Host "`nCENARIO 1 - Reducao para 2 nos:" -ForegroundColor White
$scenario1Cost = $monthlyCost * 2/3
$scenario1Savings = $monthlyCost - $scenario1Cost
Write-Host "   - Custo mensal: $${scenario1Cost:F2} USD"
Write-Host "   - Economia: $${scenario1Savings:F2} USD/mes ($(($scenario1Savings/$monthlyCost*100).ToString('F1')) por cento)"

Write-Host "`nCENARIO 2 - Migracao para e2-micro (1 no):" -ForegroundColor White
$e2MicroCost = 12.14  # USD por mes
$scenario2Savings = $monthlyCost - $e2MicroCost
Write-Host "   - Custo mensal: $${e2MicroCost:F2} USD"
Write-Host "   - Economia: $${scenario2Savings:F2} USD/mes ($(($scenario2Savings/$monthlyCost*100).ToString('F1')) por cento)"
Write-Host "   - RISCO: Pode ser insuficiente para picos de uso"

Write-Host "`nCENARIO 3 - Cluster Autopilot:" -ForegroundColor White
$autopilotCost = 0.10  # USD por vCPU/hora + 0.10 USD por GB/hora
$autopilotMonthly = ($totalvCPUs * $autopilotCost * 24 * 30) + ($totalMemory * 0.10 * 24 * 30)
$scenario3Savings = $monthlyCost - $autopilotMonthly
Write-Host "   - Custo mensal estimado: $${autopilotMonthly:F2} USD"
Write-Host "   - Economia: $${scenario3Savings:F2} USD/mes ($(($scenario3Savings/$monthlyCost*100).ToString('F1')) por cento)"
Write-Host "   - BENEFICIO: Escalabilidade automatica"

# Resumo final
Write-Host "`nRESUMO EXECUTIVO:" -ForegroundColor Yellow
Write-Host "- Cluster atual: SUBUTILIZADO ($($cpuUsagePercent.ToString('F1')) por cento CPU, $($memoryUsagePercent.ToString('F1')) por cento RAM)"
Write-Host "- Oportunidade de economia: $${($monthlyCost * 1/3):F2} - $${scenario2Savings:F2} USD/mes"
Write-Host "- Recomendacao principal: Reduzir para 2 nos + corrigir configuracoes"
Write-Host "- Prioridade: ALTA - Desperdicio significativo de recursos"

Write-Host "`nPROXIMOS PASSOS:" -ForegroundColor Green
Write-Host "1. Resolver PVCs pendentes"
Write-Host "2. Definir resource requests/limits"
Write-Host "3. Testar com 2 nos"
Write-Host "4. Implementar monitoramento de custos"
Write-Host "5. Revisar mensalmente"

Write-Host "`nAnalise concluida em $(Get-Date)" -ForegroundColor Cyan

