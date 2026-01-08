# Script para limpar conexões sem SSL do PostgreSQL
# Uso: .\scripts\limpar-conexoes-ssl.ps1

Write-Host "🔍 Verificando conexões ativas no PostgreSQL..." -ForegroundColor Cyan

# Obter informações do banco
$INSTANCE = "comercial-db"
$DATABASE = "n8n-postgres-db"
$USER = "n8n_user"

Write-Host "`n📊 Opções para limpar conexões sem SSL:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  REINICIAR PODS (Recomendado - Mais Simples)" -ForegroundColor Green
Write-Host "    - Força fechamento de todas as conexões"
Write-Host "    - Reconecta automaticamente com SSL"
Write-Host ""
Write-Host "2️⃣  TERMINAR CONEXÕES NO BANCO (SQL)" -ForegroundColor Yellow
Write-Host "    - Termina apenas conexões sem SSL"
Write-Host "    - Requer acesso ao banco"
Write-Host ""
Write-Host "3️⃣  HABILITAR requireSsl NO CLOUD SQL" -ForegroundColor Magenta
Write-Host "    - Força SSL em todas as conexões"
Write-Host "    - Rejeita conexões sem SSL automaticamente"
Write-Host ""

$opcao = Read-Host "Escolha uma opção (1, 2 ou 3)"

switch ($opcao) {
    "1" {
        Write-Host "`n🔄 Reiniciando pods do n8n..." -ForegroundColor Cyan
        Write-Host "Isso vai fechar todas as conexões e reconectar com SSL." -ForegroundColor Yellow
        
        kubectl rollout restart deployment/n8n -n n8n
        kubectl rollout restart deployment/n8n-worker -n n8n
        
        Write-Host "`n✅ Pods reiniciados. Aguardando rollout..." -ForegroundColor Green
        Write-Host "Verificando status..." -ForegroundColor Cyan
        
        kubectl rollout status deployment/n8n -n n8n --timeout=5m
        kubectl rollout status deployment/n8n-worker -n n8n --timeout=5m
        
        Write-Host "`n✅ Concluído! Todas as conexões foram fechadas e reconectadas com SSL." -ForegroundColor Green
    }
    
    "2" {
        Write-Host "`n🗄️  Conectando ao PostgreSQL para terminar conexões sem SSL..." -ForegroundColor Cyan
        Write-Host "⚠️  ATENÇÃO: Isso vai terminar conexões ativas sem SSL." -ForegroundColor Yellow
        
        $confirmar = Read-Host "Deseja continuar? (s/N)"
        if ($confirmar -ne "s" -and $confirmar -ne "S") {
            Write-Host "Operação cancelada." -ForegroundColor Yellow
            exit
        }
        
        # SQL para verificar conexões sem SSL
        $sqlVerificar = @"
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    CASE 
        WHEN ssl IS TRUE THEN 'SSL ✅'
        ELSE 'NO SSL ❌'
    END as ssl_status,
    backend_start
FROM pg_stat_activity
WHERE datname = '$DATABASE'
  AND usename = '$USER'
ORDER BY backend_start;
"@
        
        Write-Host "`n📋 Conexões ativas:" -ForegroundColor Cyan
        Write-Host "Para executar o SQL, use:" -ForegroundColor Yellow
        Write-Host "gcloud sql connect $INSTANCE --user=$USER --database=$DATABASE" -ForegroundColor White
        Write-Host ""
        Write-Host "SQL para verificar conexões:" -ForegroundColor Yellow
        Write-Host $sqlVerificar -ForegroundColor Gray
        
        # SQL para terminar conexões sem SSL
        $sqlTerminar = @"
-- Terminar conexões sem SSL
SELECT pg_terminate_backend(pid) as terminado, pid, usename, client_addr
FROM pg_stat_activity
WHERE datname = '$DATABASE'
  AND usename = '$USER'
  AND ssl IS FALSE
  AND pid <> pg_backend_pid();
"@
        
        Write-Host "`nSQL para terminar conexões sem SSL:" -ForegroundColor Yellow
        Write-Host $sqlTerminar -ForegroundColor Gray
    }
    
    "3" {
        Write-Host "`n🔒 Habilitando requireSsl no Cloud SQL..." -ForegroundColor Cyan
        Write-Host "⚠️  ATENÇÃO: Isso vai rejeitar TODAS as conexões sem SSL." -ForegroundColor Yellow
        Write-Host "Certifique-se de que todas as aplicações estão configuradas para SSL!" -ForegroundColor Yellow
        
        $confirmar = Read-Host "Deseja continuar? (s/N)"
        if ($confirmar -ne "s" -and $confirmar -ne "S") {
            Write-Host "Operação cancelada." -ForegroundColor Yellow
            exit
        }
        
        Write-Host "`nAplicando patch no Cloud SQL..." -ForegroundColor Cyan
        gcloud sql instances patch $INSTANCE --require-ssl
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ requireSsl habilitado com sucesso!" -ForegroundColor Green
            Write-Host "Agora todas as conexões sem SSL serão rejeitadas automaticamente." -ForegroundColor Green
        } else {
            Write-Host "`n❌ Erro ao habilitar requireSsl." -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "Opção inválida." -ForegroundColor Red
    }
}

Write-Host "`n📝 Para verificar logs após a operação:" -ForegroundColor Cyan
Write-Host "kubectl logs -n n8n -l service=n8n --tail=50 | Select-String -Pattern 'error|ssl|pg_hba'" -ForegroundColor Gray

