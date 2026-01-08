# 🗄️ AÇÕES DO LADO DO BANCO (Cloud SQL) - SSL

**Data:** 02/12/2025  
**Objetivo:** Configurar Cloud SQL para forçar SSL e limpar conexões sem SSL

---

## 🔍 **STATUS ATUAL DO CLOUD SQL**

### **Configuração Atual:**
```yaml
requireSsl: false  # ⚠️ Não está forçando SSL
sslMode: ENCRYPTED_ONLY  # ✅ Aceita apenas conexões SSL
```

**Problema:** Mesmo com `sslMode: ENCRYPTED_ONLY`, o Cloud SQL não está **rejeitando ativamente** conexões sem SSL. Ele apenas aceita conexões SSL, mas não termina conexões antigas sem SSL.

---

## ✅ **AÇÕES DO LADO DO BANCO**

### **1. Habilitar `requireSsl: true` (Recomendado)**

Força o Cloud SQL a rejeitar conexões sem SSL:

```bash
gcloud sql instances patch comercial-db \
  --require-ssl
```

**O que isso faz:**
- ✅ Rejeita **imediatamente** qualquer tentativa de conexão sem SSL
- ✅ Força todas as aplicações a usar SSL
- ✅ Termina conexões existentes sem SSL

**⚠️ ATENÇÃO:** Certifique-se de que TODAS as aplicações estão configuradas para SSL antes de habilitar!

---

### **2. Verificar Conexões Ativas sem SSL**

Conectar ao Cloud SQL e verificar conexões:

```sql
-- Ver todas as conexões ativas
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    state_change,
    CASE 
        WHEN ssl IS TRUE THEN 'SSL'
        ELSE 'NO SSL'
    END as ssl_status
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
ORDER BY backend_start;
```

---

### **3. Terminar Conexões sem SSL (Limpeza Manual)**

Se houver conexões sem SSL, terminá-las:

```sql
-- Terminar conexões sem SSL do usuário n8n_user
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND usename = 'n8n_user'
  AND ssl IS FALSE
  AND pid <> pg_backend_pid();
```

**⚠️ CUIDADO:** Isso termina conexões ativas. Pode causar interrupção temporária.

---

### **4. Configurar Timeout de Conexões Idle**

Reduzir tempo de conexões idle para forçar reconexões:

```sql
-- Ver configuração atual
SHOW idle_in_transaction_session_timeout;

-- Configurar timeout (30 segundos)
ALTER DATABASE "n8n-postgres-db" SET idle_in_transaction_session_timeout = '30s';
```

**O que isso faz:**
- ✅ Termina conexões idle após 30 segundos
- ✅ Força reconexões (que usarão SSL)
- ✅ Limpa pool de conexões antigas

---

### **5. Configurar `pg_hba.conf` (Se Acessível)**

Se tiver acesso ao `pg_hba.conf` do Cloud SQL (geralmente não tem), adicionar:

```
# Rejeitar conexões sem SSL
hostnossl all all 0.0.0.0/0 reject

# Permitir apenas conexões SSL
hostssl all all 0.0.0.0/0 md5
```

**⚠️ NOTA:** Cloud SQL gerencia `pg_hba.conf` automaticamente. Não é possível editar diretamente.

---

## 🎯 **PLANO DE IMPLEMENTAÇÃO**

### **Fase 1: Verificação (Agora)**

1. ✅ Verificar conexões ativas sem SSL
2. ✅ Verificar configuração atual do Cloud SQL
3. ✅ Confirmar que todas as aplicações estão prontas

### **Fase 2: Limpeza (Imediato)**

1. ✅ Terminar conexões sem SSL (se houver)
2. ✅ Reduzir timeout de conexões idle
3. ✅ Monitorar reconexões

### **Fase 3: Forçar SSL (Após Confirmar Aplicações)**

1. ⏳ Habilitar `requireSsl: true`
2. ⏳ Monitorar logs por 24 horas
3. ⏳ Verificar se erros pararam

---

## 📋 **SCRIPTS SQL ÚTEIS**

### **Script 1: Monitorar Conexões SSL**

```sql
-- Ver resumo de conexões por status SSL
SELECT 
    CASE WHEN ssl IS TRUE THEN 'Com SSL' ELSE 'Sem SSL' END as status,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE state = 'active') as ativas,
    COUNT(*) FILTER (WHERE state = 'idle') as idle,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
GROUP BY ssl;
```

### **Script 2: Listar Conexões sem SSL**

```sql
-- Listar todas as conexões sem SSL
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    now() - backend_start as tempo_conectado
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND ssl IS FALSE
  AND pid <> pg_backend_pid()
ORDER BY backend_start;
```

### **Script 3: Terminar Conexões Idle sem SSL**

```sql
-- Terminar apenas conexões idle sem SSL (mais seguro)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND usename = 'n8n_user'
  AND ssl IS FALSE
  AND state IN ('idle', 'idle in transaction')
  AND pid <> pg_backend_pid();
```

---

## ⚠️ **CUIDADOS E CONSIDERAÇÕES**

### **Antes de Habilitar `requireSsl: true`:**

1. ✅ **Verificar todas as aplicações:**
   - n8n: ✅ Configurado
   - n8n-worker: ✅ Configurado
   - Evolution API: ✅ Configurado
   - Metabase: ✅ Configurado
   - Cloud Run services: ⚠️ Verificar

2. ✅ **Ter plano de rollback:**
   ```bash
   # Desabilitar requireSsl se necessário
   gcloud sql instances patch comercial-db --no-require-ssl
   ```

3. ✅ **Monitorar após habilitar:**
   - Verificar logs do Cloud SQL
   - Monitorar aplicações por 1-2 horas
   - Verificar se não há erros de conexão

---

## 🔄 **ORDEM RECOMENDADA DE EXECUÇÃO**

1. **Agora:**
   - ✅ Reduzir pool size e timeout no n8n (já feito)
   - ✅ Verificar conexões ativas no banco

2. **Próximo:**
   - ⏳ Terminar conexões idle sem SSL (se houver)
   - ⏳ Configurar timeout de conexões idle

3. **Depois (após confirmar que tudo funciona):**
   - ⏳ Habilitar `requireSsl: true`
   - ⏳ Monitorar por 24-48 horas

---

## ✅ **STATUS**

- ✅ **Pool reduzido** no n8n (8 conexões, 30s timeout)
- ⏳ **Aguardando** verificação de conexões no banco
- ⏳ **Pronto para** habilitar `requireSsl: true` após confirmação

---

**Última Atualização:** 02/12/2025  
**Status:** 📋 Pronto para Execução


