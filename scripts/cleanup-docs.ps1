# Script de Limpeza de Documentação Obsoleta
# Objetivo: Arquivar documentos que não são mais necessários

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot + "\.."
$archiveDir = "$projectRoot\archive\docs-obsoletos-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

Write-Host "`n🧹 LIMPEZA DE DOCUMENTAÇÃO OBSOLETA" -ForegroundColor Cyan
Write-Host "===================================`n" -ForegroundColor Cyan

# Documentos obsoletos para arquivar
$obsoleteDocs = @(
    "ESPELHO_PERFEITO_WORKFLOWS.md",
    "ESPELHO_COMPLETO_WORKFLOWS.md",
    "LIMPEZA_PROFUNDA_RESUMO.md",
    "LIMPEZA_PROJETO_RESUMO.md",
    "COMPARACAO_LOCAL_VS_GCP_N8N.md",
    "SINCRONIZACAO_WORKFLOWS_RESUMO.md",
    "STATUS_ATUAL_24_09_2025.md",
    "INDICE_DOCUMENTACAO.md",
    "PROXIMOS_PASSOS_SSL.md",
    "CHECKLIST_FINAL_SSL.md",
    "STATUS_IMPLEMENTACAO_SSL.md"
)

$archived = 0
foreach ($doc in $obsoleteDocs) {
    $docPath = "$projectRoot\docs\$doc"
    if (Test-Path $docPath) {
        try {
            Move-Item -Path $docPath -Destination "$archiveDir\$doc" -Force
            Write-Host "  📦 Arquivado: $doc" -ForegroundColor Gray
            $archived++
        } catch {
            Write-Host "  ⚠️  Erro ao arquivar $doc : $_" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n✅ $archived documentos arquivados em: $archiveDir" -ForegroundColor Green
Write-Host ""




