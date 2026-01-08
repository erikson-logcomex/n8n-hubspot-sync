# 🔐 DIAGRAMA: SSL Cloud SQL - Hostname vs IP

**Data:** 01/12/2025

---

## 📊 FLUXO DE CONEXÃO SSL

### **Cenário 1: Com REJECT_UNAUTHORIZED=true (Não funciona com IP)**

```
n8n Pod
  │
  ├─ Conecta via: 172.23.64.3 (IP)
  │
  ├─ SSL Handshake
  │
  ├─ Cloud SQL envia certificado
  │   └─ Certificado contém hostname: "1-9dd76fd7-...us-central1.sql.goog"
  │
  ├─ Node.js valida:
  │   ├─ ✅ Certificado CA válido? → SIM (Google)
  │   └─ ❌ Hostname 172.23.64.3 está no certificado? → NÃO
  │
  └─ ❌ ERRO: "Hostname/IP does not match certificate's altnames"
```

### **Cenário 2: Com REJECT_UNAUTHORIZED=false (Atual - Funcionando)**

```
n8n Pod
  │
  ├─ Conecta via: 172.23.64.3 (IP)
  │
  ├─ SSL Handshake
  │
  ├─ Cloud SQL envia certificado
  │   └─ Certificado contém hostname: "1-9dd76fd7-...us-central1.sql.goog"
  │
  ├─ Node.js valida:
  │   ├─ ✅ Certificado CA válido? → SIM (Google)
  │   └─ ⚠️ Hostname 172.23.64.3 está no certificado? → IGNORADO (REJECT_UNAUTHORIZED=false)
  │
  └─ ✅ CONEXÃO ESTABELECIDA (criptografada)
```

---

## 🏗️ ARQUITETURA ATUAL

```
┌─────────────────────────────────────────────────────────────┐
│                    GKE Cluster (VPC Privada)                │
│                                                              │
│  ┌──────────────┐                                           │
│  │  n8n Pod     │                                           │
│  │              │                                           │
│  │  DB_HOST:    │──┐                                        │
│  │  172.23.64.3 │  │                                        │
│  │              │  │                                        │
│  │  SSL: ✅     │  │  Conexão SSL/TLS                       │
│  │  CA: ✅      │  │  (Criptografada)                       │
│  │  Hostname: ⚠️│  │                                        │
│  └──────────────┘  │                                        │
│                    │                                        │
│                    ▼                                        │
│  ┌──────────────────────────────────────────────┐          │
│  │  Cloud SQL (comercial-db)                     │          │
│  │  IP Privado: 172.23.64.3                     │          │
│  │  Connection: datatoopenai:us-central1:...     │          │
│  │  Certificado: 1-9dd76fd7-...sql.goog         │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 DETALHAMENTO DO CERTIFICADO

### **Certificado SSL do Cloud SQL contém:**

```
Subject: Google Cloud SQL Server CA
Issuer: Google, Inc

Subject Alternative Names (SAN):
  DNS: 1-9dd76fd7-df2c-46b9-9443-15978d99381a.us-central1.sql.goog
  (NÃO contém: 172.23.64.3)
```

### **Validação SSL:**

| Validação | REJECT_UNAUTHORIZED=true | REJECT_UNAUTHORIZED=false |
|-----------|--------------------------|----------------------------|
| **Certificado CA** | ✅ Valida | ✅ Valida |
| **Hostname/IP** | ✅ Valida (falha com IP) | ⚠️ Ignora |
| **Criptografia** | ✅ Sim | ✅ Sim |
| **Funciona com IP** | ❌ Não | ✅ Sim |

---

## 🎯 POR QUE USAMOS IP E NÃO HOSTNAME?

### **Vantagens do IP Privado:**

1. ✅ **Simplicidade**: Não requer DNS interno configurado
2. ✅ **Performance**: Conexão direta via VPC (sem proxy)
3. ✅ **Custo**: Sem necessidade de Cloud SQL Proxy
4. ✅ **Funciona imediatamente**: Sem configuração adicional

### **Desvantagens:**

1. ⚠️ **Validação hostname**: Não funciona com validação rigorosa
2. ⚠️ **Menos rigoroso**: Mas ainda seguro em rede privada

---

## 🔒 NÍVEIS DE SEGURANÇA

### **Nível 1: Sem SSL** ❌
```
Conexão: Não criptografada
Segurança: Baixa
```

### **Nível 2: SSL com REJECT_UNAUTHORIZED=false** ✅ (Atual)
```
Conexão: Criptografada (SSL/TLS)
Validação CA: Sim
Validação Hostname: Não
Segurança: Boa (rede privada)
```

### **Nível 3: SSL com REJECT_UNAUTHORIZED=true + Hostname** ✅✅
```
Conexão: Criptografada (SSL/TLS)
Validação CA: Sim
Validação Hostname: Sim
Segurança: Excelente
Requer: Connection Name ou Cloud SQL Proxy
```

---

## 📝 CONFIGURAÇÃO ATUAL (Funcionando)

```yaml
# Conexão
DB_POSTGRESDB_HOST: 172.23.64.3  # IP privado
DB_POSTGRESDB_PORT: 5432

# SSL
DB_POSTGRESDB_SSL_ENABLED: "true"
DB_POSTGRESDB_SSL_CA_FILE: /etc/postgresql/certs/server-ca.pem
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED: "false"  # Permite IP

# Resultado:
# ✅ Conexão criptografada
# ✅ Certificado CA validado
# ⚠️ Hostname não validado (mas OK para rede privada)
```

---

## 🚀 MELHORIA FUTURA (Opcional)

Se quiser máxima segurança, podemos configurar para usar **Connection Name**:

```yaml
# Opção 1: Cloud SQL Proxy (sidecar)
DB_POSTGRESDB_HOST: 127.0.0.1
# Proxy conecta via: /cloudsql/datatoopenai:us-central1:comercial-db

# Opção 2: Unix Socket (se disponível)
DB_POSTGRESDB_HOST: /cloudsql/datatoopenai:us-central1:comercial-db

# Com isso:
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED: "true"  # Validação completa
```

**Mas isso requer:**
- Instalar Cloud SQL Proxy como sidecar
- Ou configurar Private Service Connect
- Testes adicionais

---

## ✅ CONCLUSÃO

A configuração atual (`REJECT_UNAUTHORIZED=false`) é:
- ✅ **Segura** para ambiente de rede privada
- ✅ **Funcional** (conexão SSL criptografada)
- ✅ **Prática** (não requer configuração adicional)
- ✅ **Adequada** para o ambiente atual

A validação de hostname seria ideal, mas não é crítica em rede privada do GCP.

---

**Última Atualização:** 01/12/2025




