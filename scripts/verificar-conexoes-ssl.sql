-- Script SQL para verificar e terminar conexões sem SSL
-- Uso: gcloud sql connect comercial-db --user=n8n_user --database=n8n-postgres-db
--      Depois execute este arquivo ou copie os comandos

-- ============================================
-- 1. VERIFICAR TODAS AS CONEXÕES ATIVAS
-- ============================================
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    state_change,
    CASE 
        WHEN ssl IS TRUE THEN 'SSL ✅'
        ELSE 'NO SSL ❌'
    END as ssl_status,
    wait_event_type,
    wait_event
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND usename = 'n8n_user'
ORDER BY backend_start DESC;

-- ============================================
-- 2. CONTAR CONEXÕES COM/SEM SSL
-- ============================================
SELECT 
    CASE 
        WHEN ssl IS TRUE THEN 'Com SSL'
        ELSE 'Sem SSL'
    END as tipo,
    COUNT(*) as total,
    MIN(backend_start) as conexao_mais_antiga,
    MAX(backend_start) as conexao_mais_recente
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND usename = 'n8n_user'
GROUP BY ssl;

-- ============================================
-- 3. VER APENAS CONEXÕES SEM SSL
-- ============================================
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    query_start,
    state_change
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND usename = 'n8n_user'
  AND ssl IS FALSE
ORDER BY backend_start;

-- ============================================
-- 4. TERMINAR CONEXÕES SEM SSL
-- ⚠️ CUIDADO: Isso vai terminar conexões ativas!
-- ============================================
-- Descomente a linha abaixo para executar:
-- SELECT pg_terminate_backend(pid) as terminado, pid, usename, client_addr, application_name
-- FROM pg_stat_activity
-- WHERE datname = 'n8n-postgres-db'
--   AND usename = 'n8n_user'
--   AND ssl IS FALSE
--   AND pid <> pg_backend_pid();

-- ============================================
-- 5. TERMINAR TODAS AS CONEXÕES DO n8n_user
-- ⚠️ MUITO CUIDADO: Isso termina TODAS as conexões!
-- ============================================
-- Descomente apenas se necessário:
-- SELECT pg_terminate_backend(pid) as terminado, pid, usename, client_addr
-- FROM pg_stat_activity
-- WHERE datname = 'n8n-postgres-db'
--   AND usename = 'n8n_user'
--   AND pid <> pg_backend_pid();


