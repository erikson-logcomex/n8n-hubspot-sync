# 🔧 SOLUÇÃO: Pool de Conexões SSL no n8n

**Data:** 02/12/2025  
**Problema:** Erro "pg_hba.conf rejects connection... no encryption" mesmo com SSL habilitado

---

## 🔍 **PROBLEMA IDENTIFICADO**

### **Sintoma:**
- Erro intermitente: `pg_hba.conf rejects connection for host "10.56.3.59", user "n8n_user", database "n8n-postgres-db", no encryption`
- Ocorre na **conexão principal do n8n** (não nas conexões dos workflows)
- Acontece quando o n8n tenta buscar informações de execuções (`ExecutionRepository.findSingleExecution`)

### **Causa Raiz:**
O **pool de conexões do TypeORM** está reutilizando conexões antigas que foram criadas **antes** de habilitar SSL. Mesmo com `DB_POSTGRESDB_SSL_MODE=require`, conexões antigas no pool ainda não usam SSL.

---

## ✅ **SOLUÇÕES ENCONTRADAS (Pesquisa)**

### **1. Reduzir Pool Size e Timeout (Recomendado)**

Forçar reconexões mais frequentes para limpar conexões antigas:

```yaml
- name: DB_POSTGRESDB_POOL_SIZE
  value: "5"  # Reduzir de 15 para 5
- name: DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT
  value: "30000"  # Reduzir de 300000 para 30000 (30 segundos)
```

**Por que funciona:**
- Conexões idle são fechadas mais rapidamente
- Novas conexões são criadas com SSL
- Pool menor = menos conexões antigas acumuladas

---

### **2. Usar Connection String Completa com SSL**

Em vez de variáveis individuais, usar uma connection string que força SSL:

```yaml
- name: DB_POSTGRESDB_CONNECTION_STRING
  value: "postgresql://n8n_user:senha@172.23.64.3:5432/n8n-postgres-db?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem"
```

**⚠️ ATENÇÃO:** Isso requer remover as variáveis individuais (`DB_POSTGRESDB_HOST`, etc.)

---

### **3. Adicionar Variável Extra para TypeORM**

Algumas versões do TypeORM precisam de configuração explícita:

```yaml
- name: DB_POSTGRESDB_EXTRA
  value: '{"ssl":{"require":true,"rejectUnauthorized":false,"ca":"/etc/postgresql/certs/server-ca.pem"}}'
```

---

### **4. Limpar Pool ao Reiniciar**

Forçar limpeza completa do pool ao reiniciar:

```yaml
- name: DB_POSTGRESDB_CONNECTION_TIMEOUT
  value: "10000"  # Reduzir timeout de conexão
```

---

## 🎯 **SOLUÇÃO RECOMENDADA**

### **Implementação: Reduzir Pool e Timeout**

Esta é a solução mais segura e menos invasiva:

1. **Reduzir Pool Size** de 15 para 5-8
2. **Reduzir Idle Timeout** de 300000 (5 min) para 30000 (30 seg)
3. **Manter todas as variáveis SSL** já configuradas

**Vantagens:**
- ✅ Não requer mudanças estruturais
- ✅ Força reconexões mais frequentes
- ✅ Limpa conexões antigas automaticamente
- ✅ Mantém performance aceitável

---

## 📋 **IMPLEMENTAÇÃO**

### **Passo 1: Atualizar Deployment n8n**

```yaml
- name: DB_POSTGRESDB_POOL_SIZE
  value: "8"  # Reduzido de 15
- name: DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT
  value: "30000"  # Reduzido de 300000 (30 segundos)
```

### **Passo 2: Atualizar Deployment n8n-worker**

```yaml
- name: DB_POSTGRESDB_POOL_SIZE
  value: "3"  # Manter menor para workers
- name: DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT
  value: "30000"  # Reduzido de 300000
```

### **Passo 3: Aplicar e Reiniciar**

```powershell
kubectl apply -f clusters/n8n-cluster/production/n8n-optimized-deployment.yaml
kubectl apply -f clusters/n8n-cluster/production/n8n-worker-optimized-deployment.yaml
kubectl rollout restart deployment/n8n -n n8n
kubectl rollout restart deployment/n8n-worker -n n8n
```

---

## 🔍 **VERIFICAÇÃO**

Após aplicar, monitorar logs por 10-15 minutos:

```powershell
kubectl logs -n n8n -l service=n8n --tail=100 | Select-String -Pattern "error|pg_hba|no encryption"
```

**Resultado esperado:**
- ✅ Nenhum erro "no encryption" nos logs
- ✅ Execuções completando com sucesso
- ✅ Interface do n8n sem "Connection lost"

---

## 📊 **MONITORAMENTO**

### **Métricas a Observar:**

1. **Taxa de Erros SSL:**
   - Deve ser 0% após implementação
   - Monitorar por 24-48 horas

2. **Performance:**
   - Pool menor pode causar pequeno aumento em latência
   - Se notar degradação, aumentar pool para 10

3. **Conexões Ativas:**
   - Verificar se não excede limites do Cloud SQL
   - Pool de 8 + 3 workers = ~11 conexões máximas

---

## 🔄 **SE O PROBLEMA PERSISTIR**

### **Opção Alternativa: Connection String Completa**

Se reduzir pool não resolver, usar connection string:

```yaml
# Remover variáveis individuais:
# - DB_POSTGRESDB_HOST
# - DB_POSTGRESDB_PORT
# - DB_POSTGRESDB_DATABASE
# - DB_POSTGRESDB_USER
# - DB_POSTGRESDB_PASSWORD

# Adicionar connection string:
- name: DB_POSTGRESDB_CONNECTION_STRING
  valueFrom:
    secretKeyRef:
      name: postgres-connection-string
      key: connection_string
```

**Secret com connection string:**
```
postgresql://n8n_user:senha@172.23.64.3:5432/n8n-postgres-db?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem
```

---

## ✅ **STATUS**

- ⏳ **Aguardando implementação**
- 📋 **Solução recomendada:** Reduzir pool size e timeout
- 🎯 **Objetivo:** Eliminar erros "no encryption" completamente

---

**Última Atualização:** 02/12/2025  
**Status:** 📋 Pronto para Implementação

