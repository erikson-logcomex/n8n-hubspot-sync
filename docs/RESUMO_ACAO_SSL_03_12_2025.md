# 🔧 RESUMO: Ação para Resolver Problemas SSL - 03/12/2025

**Data:** 03/12/2025  
**Problema:** Erros intermitentes "pg_hba.conf rejects connection... no encryption"

---

## 🔍 **PROBLEMA IDENTIFICADO**

### **Causa Raiz:**
- **Workers antigos** (4 dias de uptime) mantinham conexões sem SSL no pool
- **Pool size grande** (12 conexões) permitia acumular conexões antigas
- **Idle timeout longo** (60 segundos) mantinha conexões antigas vivas

### **Sintomas:**
- Erros intermitentes: `pg_hba.conf rejects connection for host "10.56.3.59", user "n8n_user", database "n8n-postgres-db", no encryption`
- Ocorria quando o n8n tentava buscar informações de execuções
- IPs dos erros correspondiam aos pods antigos (10.56.3.57, 10.56.3.58, 10.56.3.59)

---

## ✅ **AÇÕES REALIZADAS**

### **1. Redução do Pool de Conexões (n8n principal)**
- ✅ `DB_POSTGRESDB_POOL_SIZE`: `12` → `8`
- ✅ `DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT`: `60000` → `30000` (30 segundos)

**Arquivo modificado:**
- `clusters/n8n-cluster/production/n8n-optimized-deployment.yaml`

### **2. Reinício dos Deployments**
- ✅ `kubectl rollout restart deployment/n8n -n n8n`
- ✅ `kubectl rollout restart deployment/n8n-worker -n n8n`

### **3. Deleção de Pods Antigos**
- ✅ Deletados pods workers com 4 dias de uptime:
  - `n8n-worker-987cc99ff-7wnvs` (IP: 10.56.3.59)
  - `n8n-worker-987cc99ff-s5g8z` (IP: 10.56.3.57)
  - `n8n-worker-987cc99ff-xtxp4` (IP: 10.56.3.58)

**Comando usado:**
```powershell
kubectl delete pod n8n-worker-987cc99ff-7wnvs n8n-worker-987cc99ff-s5g8z n8n-worker-987cc99ff-xtxp4 -n n8n
```

---

## 📊 **STATUS ATUAL**

### **Configurações SSL (já estavam corretas):**
- ✅ `DB_POSTGRESDB_SSL_ENABLED: "true"`
- ✅ `DB_POSTGRESDB_SSL_MODE: "require"`
- ✅ `DB_POSTGRESDB_SSL_CA_FILE: /etc/postgresql/certs/server-ca.pem`
- ✅ `NODE_EXTRA_CA_CERTS: /etc/postgresql/certs/server-ca.pem`

### **Workers:**
- ✅ Configurações SSL corretas
- ✅ Pool size: 3 (já estava otimizado)
- ✅ Idle timeout: 30 segundos (já estava otimizado)

---

## 🎯 **PRÓXIMOS PASSOS**

### **1. Monitoramento (Próximas 24 horas)**
```powershell
# Verificar logs por erros SSL
kubectl logs -n n8n -l service=n8n --tail=100 | Select-String -Pattern "error|pg_hba|no encryption" -CaseSensitive:$false

# Verificar logs dos workers
kubectl logs -n n8n -l app=n8n-worker --tail=100 | Select-String -Pattern "error|pg_hba|no encryption" -CaseSensitive:$false
```

### **2. Se o Problema Persistir**

**Opção A: Habilitar `requireSsl` no Cloud SQL (Solução Definitiva)**
```bash
gcloud sql instances patch comercial-db --require-ssl
```

**⚠️ ATENÇÃO:** Isso força SSL em TODAS as conexões. Certifique-se de que todas as aplicações estão configuradas.

**Opção B: Terminar Conexões sem SSL no Banco**
```sql
-- Conectar ao Cloud SQL e executar:
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'n8n-postgres-db'
  AND usename = 'n8n_user'
  AND ssl IS FALSE
  AND pid <> pg_backend_pid();
```

---

## 📝 **LIÇÕES APRENDIDAS**

1. **Workers se conectam ao banco:** Workers do n8n processam workflows e precisam acessar o PostgreSQL
2. **Pool de conexões persiste:** Conexões antigas no pool podem não usar SSL mesmo após configurar
3. **Rolling update lento:** Com `maxSurge: 25%`, pode demorar para substituir todos os pods
4. **Solução rápida:** Deletar pods antigos diretamente força criação de novos com SSL

---

## ✅ **RESULTADO ESPERADO**

Após as ações:
- ✅ Novos pods criados com SSL configurado
- ✅ Pool reduzido força reconexões mais frequentes
- ✅ Conexões antigas sem SSL foram eliminadas
- ✅ Erros "no encryption" devem parar

**Monitorar por 24-48 horas para confirmar.**

---

**Última Atualização:** 03/12/2025 14:30  
**Status:** ✅ Ações Aplicadas - Aguardando Monitoramento


