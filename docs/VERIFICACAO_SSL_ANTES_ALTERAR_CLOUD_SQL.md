# ⚠️ VERIFICAÇÃO ANTES DE ALTERAR CLOUD SQL PARA "PERMITIR SOMENTE CONEXÕES SSL"

**Data:** 01/12/2025  
**Objetivo:** Verificar se todas as aplicações estão configuradas para EXIGIR SSL antes de alterar o Cloud SQL

---

## 🔍 **STATUS ATUAL**

### **✅ Configurado para EXIGIR SSL:**

1. **✅ Metabase**
   - `MB_DB_SSL_MODE=require` ✅
   - **Status:** Pronto para "Permitir somente conexões SSL"

2. **✅ Evolution API**
   - Connection string precisa ter `sslmode=require`
   - **Status:** ⚠️ **PRECISA VERIFICAR/ATUALIZAR**

3. **✅ n8n**
   - `DB_POSTGRESDB_SSL_ENABLED=true` ✅
   - **Status:** ✅ Pronto (n8n sempre usa SSL quando habilitado)

4. **✅ n8n-worker**
   - `DB_POSTGRESDB_SSL_ENABLED=true` ✅
   - **Status:** ✅ Pronto

---

## ⚠️ **AÇÃO NECESSÁRIA**

### **Evolution API - Verificar/Atualizar Secret**

O secret do Evolution API precisa ter a connection string com SSL:

**Connection String Correta:**
```
postgresql://evolution_api:senha@172.23.64.3:5432/evolution_api?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem
```

**Como Verificar:**
```powershell
# Verificar connection string atual
kubectl get secret evolution-api-secrets -n n8n -o jsonpath='{.data.DATABASE_CONNECTION_URI}' | 
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Se NÃO tiver `sslmode=require`, atualizar:**
```powershell
# Connection string com SSL
$uri = "postgresql://evolution_api:h%29%60eubbq%3F%22TMH2%24F@172.23.64.3:5432/evolution_api?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($uri)
$base64 = [System.Convert]::ToBase64String($bytes)

kubectl patch secret evolution-api-secrets -n n8n --type='json' -p="[{\`"op\`":\`"replace\`",\`"path\`":\`"/data/DATABASE_CONNECTION_URI\`",\`"value\`":\`"$base64\`"}]"

# Reiniciar pod para aplicar
kubectl rollout restart deployment/evolution-api -n n8n
```

---

## ✅ **CHECKLIST ANTES DE ALTERAR CLOUD SQL**

- [ ] **Metabase**: `MB_DB_SSL_MODE=require` ✅
- [ ] **n8n**: `DB_POSTGRESDB_SSL_ENABLED=true` ✅
- [ ] **n8n-worker**: `DB_POSTGRESDB_SSL_ENABLED=true` ✅
- [ ] **Evolution API**: Connection string com `sslmode=require` ⚠️ **VERIFICAR**
- [ ] **Certificados**: ConfigMaps criados em todos os namespaces ✅
- [ ] **Volume Mounts**: Certificados montados em todos os pods ✅

---

## 🚀 **PASSOS PARA ALTERAR CLOUD SQL**

### **1. Verificar Evolution API (CRÍTICO)**
```powershell
# Verificar connection string
kubectl get secret evolution-api-secrets -n n8n -o jsonpath='{.data.DATABASE_CONNECTION_URI}' | 
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } | 
  Select-String "sslmode"
```

**Se não aparecer `sslmode=require`, atualizar antes de continuar!**

### **2. Testar Conexões SSL (Opcional mas Recomendado)**
```powershell
# Testar n8n
kubectl exec -n n8n deployment/n8n -- env | Select-String "SSL"

# Testar Metabase
kubectl exec -n metabase deployment/metabase-app -- env | Select-String "MB_DB_SSL"

# Testar Evolution API
kubectl exec -n n8n deployment/evolution-api -- env | Select-String "NODE_EXTRA_CA_CERTS"
```

### **3. Alterar Cloud SQL**
1. Acessar Google Cloud Console
2. Cloud SQL → comercial-db → Conexões → Segurança
3. Alterar de "Permitir tráfego de rede não criptografado" para **"Permitir somente conexões SSL"**
4. Salvar

### **4. Monitorar (Primeiros 5 minutos)**
```powershell
# Verificar pods
kubectl get pods -n n8n
kubectl get pods -n metabase

# Verificar logs
kubectl logs -n n8n deployment/n8n --tail=20
kubectl logs -n n8n deployment/evolution-api --tail=20
kubectl logs -n metabase deployment/metabase-app --tail=20
```

---

## 🔄 **ROLLBACK (Se Algo Der Errado)**

### **Reverter Cloud SQL:**
1. Voltar para "Permitir tráfego de rede não criptografado"
2. Aguardar 1-2 minutos
3. Verificar se pods voltaram a funcionar

### **Reverter Evolution API (se necessário):**
```powershell
# Connection string sem SSL (temporário)
$uri = "postgresql://evolution_api:h%29%60eubbq%3F%22TMH2%24F@172.23.64.3:5432/evolution_api"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($uri)
$base64 = [System.Convert]::ToBase64String($bytes)

kubectl patch secret evolution-api-secrets -n n8n --type='json' -p="[{\`"op\`":\`"replace\`",\`"path\`":\`"/data/DATABASE_CONNECTION_URI\`",\`"value\`":\`"$base64\`"}]"

kubectl rollout restart deployment/evolution-api -n n8n
```

---

## ✅ **RESULTADO ESPERADO**

Após alterar para "Permitir somente conexões SSL":
- ✅ **n8n**: Continua funcionando (já usa SSL)
- ✅ **n8n-worker**: Continua funcionando (já usa SSL)
- ✅ **Metabase**: Continua funcionando (já exige SSL)
- ✅ **Evolution API**: Continua funcionando (se connection string tiver `sslmode=require`)

---

## ⚠️ **ATENÇÃO**

**NÃO altere o Cloud SQL para "Permitir somente conexões SSL" até:**
1. ✅ Verificar que Evolution API tem `sslmode=require` na connection string
2. ✅ Testar todas as conexões
3. ✅ Ter plano de rollback pronto

---

**Última atualização:** 01/12/2025




