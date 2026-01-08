# 🔒 CONFIGURAÇÃO SSL/TLS PARA CLOUD RUN

**Data:** 01/12/2025  
**Objetivo:** Configurar serviços Cloud Run para usar SSL/TLS ao conectar no PostgreSQL (Cloud SQL) após habilitar "Permitir somente conexões SSL"

---

## 📋 **RESUMO EXECUTIVO**

Após habilitar **"Permitir somente conexões SSL"** no Cloud SQL, todos os serviços Cloud Run que se conectam ao PostgreSQL precisam ser atualizados para usar SSL/TLS.

### **Status Atual:**
- ✅ **Certificado SSL**: Disponível no Secret Manager (`cloud-sql-ca-cert`)
- ⚠️ **Cloud Run Services**: 6 serviços precisam ser configurados
- ✅ **Cloud SQL**: Configurado para aceitar apenas conexões SSL

---

## 🏗️ **ARQUITETURA ATUAL**

### **Serviços Cloud Run Identificados:**

1. **black-november-funnel**
   - URL: `https://black-november-funnel-cysw7leowa-rj.a.run.app`

2. **fup-automatico**
   - URL: `https://fup-automatico-cysw7leowa-rj.a.run.app`

3. **logcortex-api**
   - URL: `https://logcortex-api-cysw7leowa-rj.a.run.app`

4. **meetrox-data-capture**
   - URL: `https://meetrox-data-capture-cysw7leowa-rj.a.run.app`

5. **portal-log-cortx-backend-v3**
   - URL: `https://portal-log-cortx-backend-v3-cysw7leowa-rj.a.run.app`

6. **portal-log-cortx-frontend-v3**
   - URL: `https://portal-log-cortx-frontend-v3-cysw7leowa-rj.a.run.app`

### **Infraestrutura:**

- **Cloud SQL Instance**: `comercial-db`
- **IP Privado**: `172.23.64.3:5432`
- **Certificado SSL**: `cloud-sql-ca-cert` (Secret Manager)
- **Região Cloud Run**: `southamerica-east1` (Rio de Janeiro - `-rj.a.run.app`)

---

## 🔐 **CERTIFICADO SSL NO SECRET MANAGER**

### **Secret Disponível:**

**Nome:** `cloud-sql-ca-cert`  
**Criado:** 2025-11-28T16:59:09  
**Replicação:** Automatic  
**Conteúdo:** Certificado CA do Google Cloud SQL (`server-ca.pem`)

### **Como Acessar:**

```bash
# Baixar certificado
gcloud secrets versions access latest --secret="cloud-sql-ca-cert" > server-ca.pem

# Verificar conteúdo
gcloud secrets versions access latest --secret="cloud-sql-ca-cert" | head -5
```

---

## 🔧 **CONFIGURAÇÃO NECESSÁRIA NO CLOUD RUN**

### **Opção 1: Usar Secret Manager (Recomendado)**

#### **1.1. Montar Certificado como Volume**

```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-secret=/etc/postgresql/certs/server-ca.pem=cloud-sql-ca-cert:latest \
  --update-env-vars="DB_SSL_MODE=require,DB_SSL_ROOT_CERT=/etc/postgresql/certs/server-ca.pem"
```

#### **1.2. Configurar Variáveis de Ambiente SSL**

Dependendo da linguagem/framework, as variáveis podem variar:

**Para Node.js/JavaScript:**
```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --update-env-vars="NODE_EXTRA_CA_CERTS=/etc/postgresql/certs/server-ca.pem"
```

**Para Python:**
```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --update-env-vars="PGSSLROOTCERT=/etc/postgresql/certs/server-ca.pem,PGSSLMODE=require"
```

**Para Connection String (PostgreSQL URI):**
```bash
# Atualizar connection string para incluir SSL
# Exemplo: postgresql://user:pass@172.23.64.3:5432/db?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem
```

---

### **Opção 2: Usar Cloud SQL Proxy (Alternativa)**

Se o serviço já usa Cloud SQL Proxy, o SSL é gerenciado automaticamente:

```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-cloudsql-instances=PROJECT_ID:REGION:INSTANCE_NAME \
  --update-env-vars="DB_HOST=/cloudsql/PROJECT_ID:REGION:INSTANCE_NAME"
```

**Vantagens:**
- ✅ SSL automático
- ✅ Não precisa gerenciar certificados
- ✅ Conexão via socket Unix (mais seguro)

---

## 📝 **EXEMPLOS POR LINGUAGEM**

### **Node.js/JavaScript (pg, sequelize, etc.)**

#### **Configuração via Variáveis de Ambiente:**

```javascript
// Connection config
const config = {
  host: process.env.DB_HOST || '172.23.64.3',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false, // Para conexão via IP
    ca: fs.readFileSync(process.env.DB_SSL_ROOT_CERT || '/etc/postgresql/certs/server-ca.pem').toString()
  }
};
```

#### **Cloud Run Update:**

```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-secret=/etc/postgresql/certs/server-ca.pem=cloud-sql-ca-cert:latest \
  --update-env-vars="DB_SSL_ROOT_CERT=/etc/postgresql/certs/server-ca.pem,NODE_EXTRA_CA_CERTS=/etc/postgresql/certs/server-ca.pem"
```

---

### **Python (psycopg2, SQLAlchemy, etc.)**

#### **Connection String:**

```python
import os
import ssl

# Connection string com SSL
conn_string = f"postgresql://{user}:{password}@{host}:{port}/{database}?sslmode=require&sslrootcert={os.getenv('DB_SSL_ROOT_CERT', '/etc/postgresql/certs/server-ca.pem')}"
```

#### **Cloud Run Update:**

```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-secret=/etc/postgresql/certs/server-ca.pem=cloud-sql-ca-cert:latest \
  --update-env-vars="PGSSLROOTCERT=/etc/postgresql/certs/server-ca.pem,PGSSLMODE=require"
```

---

### **Go (database/sql, pgx, etc.)**

#### **Connection Config:**

```go
import (
    "crypto/tls"
    "crypto/x509"
    "io/ioutil"
)

cert, _ := ioutil.ReadFile("/etc/postgresql/certs/server-ca.pem")
caCertPool := x509.NewCertPool()
caCertPool.AppendCertsFromPEM(cert)

config := &tls.Config{
    RootCAs: caCertPool,
    InsecureSkipVerify: false,
}

connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=require sslrootcert=%s",
    host, port, user, password, dbname, "/etc/postgresql/certs/server-ca.pem")
```

#### **Cloud Run Update:**

```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-secret=/etc/postgresql/certs/server-ca.pem=cloud-sql-ca-cert:latest
```

---

## 🚀 **PROCESSO DE ATUALIZAÇÃO**

### **Passo 1: Identificar Serviços que Usam PostgreSQL**

```bash
# Listar todos os serviços
gcloud run services list --region=southamerica-east1

# Verificar variáveis de ambiente de cada serviço
gcloud run services describe SERVICE_NAME --region=southamerica-east1 --format="value(spec.template.spec.containers[0].env)"
```

### **Passo 2: Verificar Connection Strings Atuais**

```bash
# Verificar se já tem SSL configurado
gcloud run services describe SERVICE_NAME --region=southamerica-east1 \
  --format="yaml(spec.template.spec.containers[0].env)" | grep -i ssl
```

### **Passo 3: Atualizar Cada Serviço**

#### **Para Serviços com Connection String:**

```bash
# 1. Obter connection string atual
CURRENT_URI=$(gcloud run services describe SERVICE_NAME --region=southamerica-east1 \
  --format="value(spec.template.spec.containers[0].env[?(@.name=='DATABASE_URL')].value)")

# 2. Adicionar parâmetros SSL
NEW_URI="${CURRENT_URI}?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem"

# 3. Atualizar serviço
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-secret=/etc/postgresql/certs/server-ca.pem=cloud-sql-ca-cert:latest \
  --update-env-vars="DATABASE_URL=${NEW_URI}"
```

#### **Para Serviços com Variáveis Individuais:**

```bash
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --add-secret=/etc/postgresql/certs/server-ca.pem=cloud-sql-ca-cert:latest \
  --update-env-vars="DB_SSL_MODE=require,DB_SSL_ROOT_CERT=/etc/postgresql/certs/server-ca.pem"
```

### **Passo 4: Testar Conexão**

```bash
# Verificar logs após atualização
gcloud run services logs read SERVICE_NAME --region=southamerica-east1 --limit=50

# Verificar se há erros de conexão
gcloud run services logs read SERVICE_NAME --region=southamerica-east1 --limit=50 | grep -i "ssl\|error\|connection"
```

---

## 📋 **CHECKLIST POR SERVIÇO**

Para cada serviço Cloud Run, verificar:

- [ ] **Identificar tipo de conexão** (Connection String ou Variáveis Individuais)
- [ ] **Verificar linguagem/framework** (Node.js, Python, Go, etc.)
- [ ] **Adicionar secret do certificado** (`cloud-sql-ca-cert`)
- [ ] **Configurar variáveis SSL** apropriadas para a linguagem
- [ ] **Atualizar connection string** (se aplicável) com `sslmode=require`
- [ ] **Testar conexão** após atualização
- [ ] **Monitorar logs** por 5-10 minutos

---

## 🔍 **VERIFICAÇÃO E TROUBLESHOOTING**

### **Verificar se Certificado está Montado:**

```bash
# Verificar volumes do serviço
gcloud run services describe SERVICE_NAME --region=southamerica-east1 \
  --format="yaml(spec.template.spec.containers[0].volumeMounts)"
```

### **Verificar Variáveis de Ambiente:**

```bash
gcloud run services describe SERVICE_NAME --region=southamerica-east1 \
  --format="value(spec.template.spec.containers[0].env)" | grep -i ssl
```

### **Erros Comuns:**

#### **1. "SSL connection required"**
**Causa:** Connection string não tem `sslmode=require`  
**Solução:** Adicionar `?sslmode=require&sslrootcert=/etc/postgresql/certs/server-ca.pem`

#### **2. "certificate verify failed"**
**Causa:** Certificado não está montado ou caminho incorreto  
**Solução:** Verificar se secret está montado em `/etc/postgresql/certs/server-ca.pem`

#### **3. "no such file or directory"**
**Causa:** Caminho do certificado incorreto  
**Solução:** Verificar `volumeMounts` e caminho nas variáveis de ambiente

---

## 🔄 **ROLLBACK (Se Necessário)**

### **Reverter para Connection String sem SSL (Temporário):**

```bash
# Remover parâmetros SSL da connection string
gcloud run services update SERVICE_NAME \
  --region=southamerica-east1 \
  --update-env-vars="DATABASE_URL=postgresql://user:pass@172.23.64.3:5432/db"
```

**⚠️ ATENÇÃO:** Isso só funcionará se o Cloud SQL ainda permitir conexões não-criptografadas. Após habilitar "Permitir somente conexões SSL", o rollback não funcionará.

---

## ✅ **RESULTADO ESPERADO**

Após configurar todos os serviços:

- ✅ **Todos os serviços Cloud Run** conectam ao PostgreSQL via SSL/TLS
- ✅ **Certificado montado** de forma segura via Secret Manager
- ✅ **Conexões criptografadas** em trânsito
- ✅ **Cloud SQL aceita apenas conexões SSL**

---

## 📊 **SERVIÇOS A ATUALIZAR**

| Serviço | Status | Ação Necessária |
|---------|--------|-----------------|
| black-november-funnel | ⏳ Pendente | Verificar e atualizar |
| fup-automatico | ⏳ Pendente | Verificar e atualizar |
| logcortex-api | ⏳ Pendente | Verificar e atualizar |
| meetrox-data-capture | ⏳ Pendente | Verificar e atualizar |
| portal-log-cortx-backend-v3 | ⏳ Pendente | Verificar e atualizar |
| portal-log-cortx-frontend-v3 | ⏳ Pendente | Verificar e atualizar |

---

## 🎯 **PRÓXIMOS PASSOS**

1. ✅ **Identificar** como cada serviço se conecta ao PostgreSQL
2. ✅ **Atualizar** cada serviço com certificado e variáveis SSL
3. ✅ **Testar** conexões após atualização
4. ✅ **Habilitar** "Permitir somente conexões SSL" no Cloud SQL
5. ✅ **Monitorar** logs por 24-48 horas

---

**Última atualização:** 01/12/2025  
**Próxima revisão:** Após atualização de todos os serviços

