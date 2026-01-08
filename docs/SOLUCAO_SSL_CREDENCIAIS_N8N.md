# 🔧 SOLUÇÃO: SSL em Credenciais PostgreSQL do n8n

**Data:** 01/12/2025  
**Problema:** "unable to verify the first certificate" ao habilitar SSL em credenciais PostgreSQL

---

## 🔍 PROBLEMA IDENTIFICADO

### **Erro:**
```
Couldn't connect with these settings
unable to verify the first certificate
```

### **Causa:**

Quando você cria uma **credencial PostgreSQL** na interface web do n8n (não a conexão principal do banco), o n8n **não usa automaticamente** as variáveis de ambiente `DB_POSTGRESDB_SSL_*`.

O n8n precisa que o certificado SSL esteja disponível no **bundle de CAs do Node.js** para que conexões SSL funcionem automaticamente.

---

## ✅ SOLUÇÃO APLICADA

### **Variável de Ambiente Adicionada:**

```yaml
- name: NODE_EXTRA_CA_CERTS
  value: /etc/postgresql/certs/server-ca.pem
```

### **O que isso faz:**

- ✅ Adiciona o certificado CA do Cloud SQL ao bundle de CAs do Node.js
- ✅ Permite que **todas** as conexões SSL (incluindo credenciais criadas na interface) usem o certificado
- ✅ Funciona automaticamente para conexões PostgreSQL criadas no n8n

---

## 🔧 CONFIGURAÇÃO APLICADA

### **Deployments Atualizados:**

1. **n8n (Principal)**
   - ✅ `NODE_EXTRA_CA_CERTS` adicionado
   - ✅ Certificado montado em `/etc/postgresql/certs/server-ca.pem`

2. **n8n-worker**
   - ✅ `NODE_EXTRA_CA_CERTS` adicionado
   - ✅ Certificado montado em `/etc/postgresql/certs/server-ca.pem`

---

## 📋 COMO USAR NA INTERFACE DO N8N

### **Configuração da Credencial PostgreSQL:**

1. **Acesse:** Credentials → New → Postgres
2. **Configure:**
   - **Host:** `172.23.64.3`
   - **Database:** `hubspot-sync` (ou outro banco)
   - **User:** `n8n-user-integrations`
   - **Password:** (sua senha)
   - **SSL Mode:** `Require` (força conexão SSL)
   - **Ignore SSL Issues (Insecure):** ✅ **HABILITAR** (permite conexão via IP)

3. **Testar Conexão:**
   - Clique em "Test Connection"
   - Deve funcionar agora! ✅

---

## 🔍 POR QUE FUNCIONA AGORA?

### **Antes (Não funcionava):**
```
n8n Interface → Cria credencial PostgreSQL
  │
  ├─ Habilita SSL
  │
  ├─ Node.js tenta validar certificado
  │
  ├─ ❌ Certificado CA não encontrado no bundle padrão
  │
  └─ ❌ ERRO: "unable to verify the first certificate"
```

### **Agora (Funciona):**
```
n8n Interface → Cria credencial PostgreSQL
  │
  ├─ Habilita SSL
  │
  ├─ Node.js tenta validar certificado
  │
  ├─ ✅ NODE_EXTRA_CA_CERTS adiciona certificado ao bundle
  │
  ├─ ✅ Certificado CA encontrado e validado
  │
  └─ ✅ CONEXÃO ESTABELECIDA
```

---

## ⚙️ CONFIGURAÇÃO RECOMENDADA NA CREDENCIAL

### **Opções SSL na Interface do n8n:**

| Opção | Valor Recomendado | Motivo |
|-------|------------------|--------|
| **SSL Mode** | `Require` | Força conexão SSL criptografada |
| **Ignore SSL Issues (Insecure)** | ✅ **HABILITAR** | Permite conexão via IP (172.23.64.3) |

### **Opções de SSL Mode disponíveis:**

- **`Disable`**: ❌ Não usa SSL (não recomendado)
- **`Allow`**: ⚠️ Tenta SSL, mas não falha se não disponível
- **`Require`**: ✅ **RECOMENDADO** - Força SSL, falha se não disponível

### **Por que "Ignore SSL Issues" deve estar habilitado?**

- Estamos conectando via **IP privado** (`172.23.64.3`)
- O certificado SSL é válido para o **hostname** do Cloud SQL (não para o IP)
- Com `Ignore SSL Issues` habilitado:
  - ✅ Ainda validamos o certificado CA (através do `NODE_EXTRA_CA_CERTS`)
  - ✅ A conexão é criptografada
  - ⚠️ Mas ignoramos a validação de hostname (OK para rede privada)
- **Seguro** porque estamos em rede privada do GCP (VPC)

---

## ✅ VALIDAÇÃO

### **Após aplicar a atualização:**

1. **Aguardar pods reiniciarem** (2-3 minutos)
2. **Testar credencial no n8n:**
   - Acessar: Credentials → Sua credencial PostgreSQL
   - Clicar em "Test Connection"
   - Deve funcionar! ✅

### **Verificar se está funcionando:**

```powershell
# Verificar variável no pod
kubectl exec -n n8n deployment/n8n -- env | Select-String -Pattern "NODE_EXTRA_CA_CERTS"

# Deve mostrar:
# NODE_EXTRA_CA_CERTS=/etc/postgresql/certs/server-ca.pem
```

---

## 🔄 SE AINDA NÃO FUNCIONAR

### **Opção 1: Verificar se certificado está montado**

```powershell
kubectl exec -n n8n deployment/n8n -- ls -la /etc/postgresql/certs/
kubectl exec -n n8n deployment/n8n -- cat /etc/postgresql/certs/server-ca.pem
```

### **Opção 2: Usar Connection String com SSL**

Na credencial do n8n, você pode usar uma **connection string** completa:

```
postgresql://n8n-user-integrations:senha@172.23.64.3:5432/hubspot-sync?ssl=true&sslmode=require&sslcert=/etc/postgresql/certs/server-ca.pem&sslkey=&sslrootcert=/etc/postgresql/certs/server-ca.pem
```

### **Opção 3: Desabilitar SSL temporariamente**

Se precisar urgentemente, pode desabilitar SSL na credencial (não recomendado para produção).

---

## 📝 NOTAS IMPORTANTES

### **Diferença entre conexões:**

1. **Conexão Principal do n8n** (banco de dados do n8n):
   - Usa variáveis `DB_POSTGRESDB_SSL_*`
   - Já estava funcionando ✅

2. **Credenciais PostgreSQL criadas na interface**:
   - **NÃO** usam variáveis `DB_POSTGRESDB_SSL_*`
   - Precisam de `NODE_EXTRA_CA_CERTS` ✅ (agora configurado)

### **Segurança:**

- ✅ SSL habilitado (criptografia)
- ✅ Certificado CA validado
- ⚠️ Hostname não validado (mas OK para rede privada)
- ✅ Rede privada do GCP (VPC)

---

## 🎯 RESUMO

**Problema:** Credenciais PostgreSQL na interface do n8n não funcionavam com SSL

**Solução:** Adicionar `NODE_EXTRA_CA_CERTS=/etc/postgresql/certs/server-ca.pem`

**Status:** ✅ Configurado e aplicado

**Próximo passo:** Aguardar pods reiniciarem e testar credencial no n8n

---

**Última Atualização:** 01/12/2025  
**Status:** ✅ Solução Aplicada

