# 🔒 IMPLEMENTAÇÃO SSL: Evolution API

**Data:** 01/12/2025  
**Objetivo:** Habilitar conexões SSL/TLS entre Evolution API e PostgreSQL (Cloud SQL)

---

## 📋 RESUMO

Implementação de SSL/TLS para o Evolution API, seguindo o mesmo padrão usado no n8n. O Evolution API usa uma connection string PostgreSQL que foi atualizada para incluir SSL.

---

## ✅ O QUE FOI IMPLEMENTADO

### **1. Deployment Atualizado**

**Arquivo:** `clusters/n8n-cluster/production/evolution-api-deployment.yaml`

#### **Mudanças Aplicadas:**

1. **Variável de Ambiente SSL:**
   ```yaml
   - name: NODE_EXTRA_CA_CERTS
     value: /etc/postgresql/certs/server-ca.pem
   ```

2. **Volume Mount do Certificado:**
   ```yaml
   volumeMounts:
   - name: postgres-ssl-cert
     mountPath: /etc/postgresql/certs
     readOnly: true
   ```

3. **Volume do ConfigMap:**
   ```yaml
   volumes:
   - name: postgres-ssl-cert
     configMap:
       name: postgres-ssl-cert
       defaultMode: 420
   ```

### **2. Secret Atualizado**

**Secret:** `evolution-api-secrets` (namespace: `n8n`)

#### **Connection String Atualizada:**

**Antes:**
```
postgresql://evolution_api:senha@172.23.64.3:5432/evolution_api
```

**Depois (com SSL):**
```
postgresql://evolution_api:senha@172.23.64.3:5432/evolution_api?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem
```

#### **Parâmetros SSL Adicionados:**

- **`sslmode=require`**: Força conexão SSL criptografada
- **`sslrootcert=/etc/postgresql/certs/server-ca.pem`**: Caminho para o certificado CA

---

## 🔧 COMO FUNCIONA

### **Fluxo de Conexão SSL:**

```
Evolution API Pod
  │
  ├─ Lê DATABASE_CONNECTION_URI do Secret
  │   └─ Connection string inclui: ?sslmode=require&sslrootcert=...
  │
  ├─ NODE_EXTRA_CA_CERTS adiciona certificado ao bundle de CAs
  │
  ├─ Conecta ao PostgreSQL via SSL
  │   └─ Usa certificado em /etc/postgresql/certs/server-ca.pem
  │
  └─ ✅ Conexão SSL estabelecida
```

### **Componentes:**

1. **ConfigMap `postgres-ssl-cert`**: 
   - Contém o certificado CA do Cloud SQL
   - Já existia (criado para n8n)
   - Reutilizado para Evolution API

2. **Secret `evolution-api-secrets`**:
   - Connection string atualizada com parâmetros SSL
   - Base64 encoded no Kubernetes

3. **Deployment `evolution-api`**:
   - Volume mount do certificado
   - Variável `NODE_EXTRA_CA_CERTS` configurada

---

## 📝 DETALHES TÉCNICOS

### **Connection String PostgreSQL com SSL:**

A Evolution API usa uma connection string PostgreSQL que suporta parâmetros de query string para SSL:

```
postgresql://user:password@host:port/database?sslmode=require&sslrootcert=/path/to/ca.pem
```

### **Modos SSL Disponíveis:**

| Modo | Descrição |
|------|-----------|
| `disable` | Não usa SSL |
| `allow` | Tenta SSL, mas permite não-SSL |
| `prefer` | Prefere SSL, mas permite não-SSL |
| `require` | ✅ **Usado** - Exige SSL, não valida hostname |
| `verify-ca` | Exige SSL e valida certificado CA |
| `verify-full` | Exige SSL, valida CA e hostname |

### **Por que `sslmode=require`?**

- ✅ Força conexão SSL criptografada
- ✅ Valida certificado CA (através de `sslrootcert`)
- ⚠️ Não valida hostname (OK porque estamos usando IP `172.23.64.3`)
- ✅ Seguro para rede privada do GCP

---

## 🔍 VALIDAÇÃO

### **Comandos para Verificar:**

```powershell
# Verificar Secret atualizado
kubectl get secret evolution-api-secrets -n n8n -o jsonpath='{.data.DATABASE_CONNECTION_URI}' | 
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Verificar certificado montado
kubectl exec -n n8n deployment/evolution-api -- ls -la /etc/postgresql/certs/

# Verificar variável de ambiente
kubectl exec -n n8n deployment/evolution-api -- env | Select-String -Pattern "NODE_EXTRA_CA_CERTS"

# Verificar logs
kubectl logs -n n8n deployment/evolution-api --tail=50 | Select-String -Pattern "database|Database|SSL|error"
```

### **O que Verificar:**

- ✅ Secret contém `sslmode=require&sslrootcert=...`
- ✅ Certificado está montado em `/etc/postgresql/certs/`
- ✅ Variável `NODE_EXTRA_CA_CERTS` está configurada
- ✅ Logs não mostram erros de conexão
- ✅ Pod está `Running` e `Ready`

---

## 📊 STATUS DA IMPLEMENTAÇÃO

### **✅ Concluído:**

- [x] Deployment atualizado com volume mount
- [x] Variável `NODE_EXTRA_CA_CERTS` adicionada
- [x] Secret atualizado com SSL na connection string
- [x] Deployment aplicado no cluster

### **⏳ Em Progresso:**

- [ ] Rollout do pod novo
- [ ] Validação de conexão SSL
- [ ] Monitoramento por 24-48 horas

---

## 🔄 ROLLBACK (Se Necessário)

### **Reverter Secret:**

```powershell
# Connection string sem SSL
$oldUri = "postgresql://evolution_api:h%29%60eubbq%3F%22TMH2%24F@172.23.64.3:5432/evolution_api"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($oldUri)
$base64 = [System.Convert]::ToBase64String($bytes)

kubectl patch secret evolution-api-secrets -n n8n --type='json' -p="[{\`"op\`":\`"replace\`",\`"path\`":\`"/data/DATABASE_CONNECTION_URI\`",\`"value\`":\`"$base64\`"}]"
```

### **Reverter Deployment:**

```powershell
# Rollback para versão anterior
kubectl rollout undo deployment/evolution-api -n n8n
```

---

## 📋 PRÓXIMOS PASSOS

### **1. Monitoramento Imediato (Próximas 2 horas)**

- [ ] Verificar status do pod
- [ ] Verificar logs por erros
- [ ] Confirmar conexão SSL estabelecida

### **2. Monitoramento Contínuo (Próximas 24-48 horas)**

- [ ] Verificar logs periodicamente
- [ ] Testar funcionalidades do Evolution API
- [ ] Verificar performance
- [ ] Confirmar estabilidade

### **3. Validação Final**

- [ ] Todos os pods `Running` e `Ready`
- [ ] Sem erros nos logs
- [ ] Funcionalidades funcionando normalmente
- [ ] SSL funcionando corretamente

---

## 🎯 RESUMO

**Status:** ✅ SSL Implementado

**Mudanças:**
- ✅ Deployment atualizado
- ✅ Secret atualizado com SSL
- ✅ Certificado montado
- ✅ Variável `NODE_EXTRA_CA_CERTS` configurada

**Próximo passo:** Aguardar rollout completar e monitorar

---

**Última Atualização:** 01/12/2025  
**Status:** ✅ Implementado - Em Monitoramento

