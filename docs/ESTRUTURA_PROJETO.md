# 📁 ESTRUTURA DO PROJETO N8N

**Última atualização:** 01/12/2025  
**Status:** ✅ Organizado e Sincronizado com GCP

---

## 🎯 **VISÃO GERAL**

Este projeto contém todas as configurações, scripts e documentação para gerenciar os clusters Kubernetes no Google Cloud Platform (GCP).

### **Princípios de Organização:**
- ✅ **Sincronização**: Arquivos locais refletem estado atual do GCP
- ✅ **Versionamento**: Backups organizados em `exports/` e `archive/`
- ✅ **Documentação**: Toda documentação em `docs/`
- ✅ **Scripts**: Scripts reutilizáveis em `scripts/`
- ✅ **Limpeza**: Arquivos temporários e duplicados removidos

---

## 📂 **ESTRUTURA DE DIRETÓRIOS**

```
n8n/
├── 📁 clusters/                    # Configurações Kubernetes por cluster
│   ├── n8n-cluster/
│   │   ├── production/            # ✅ Configurações de produção (sincronizado)
│   │   │   ├── n8n-optimized-deployment.yaml
│   │   │   ├── n8n-worker-optimized-deployment.yaml
│   │   │   ├── evolution-api-deployment.yaml
│   │   │   ├── evolution-api-secret.yaml
│   │   │   ├── postgres-ssl-cert-configmap.yaml
│   │   │   ├── postgres-secret.yaml
│   │   │   ├── n8n-service.yaml
│   │   │   ├── n8n-ingress.yaml
│   │   │   └── README.md
│   │   └── staging/               # Configurações de staging
│   ├── metabase-cluster/
│   │   ├── production/            # ✅ Configurações de produção (sincronizado)
│   │   │   ├── metabase-deployment.yaml
│   │   │   ├── postgres-ssl-cert-configmap.yaml
│   │   │   ├── metabase-service.yaml
│   │   │   ├── metabase-ingress.yaml
│   │   │   └── README.md
│   │   └── staging/
│   └── monitoring-cluster/
│       ├── production/            # Configurações de monitoramento
│       │   ├── prometheus/
│       │   ├── grafana/
│       │   └── README.md
│       └── staging/
│
├── 📁 docs/                        # Documentação técnica
│   ├── ARQUITETURA_EXECUTIVA_ECOSSISTEMA.md
│   ├── IMPLEMENTACAO_SSL_*.md
│   ├── PLANO_ROLLBACK_*.md
│   ├── GUIA_IMPLEMENTACAO_*.md
│   └── ... (outros documentos)
│
├── 📁 scripts/                     # Scripts de automação
│   ├── organize-project.ps1        # ✅ Organização e limpeza
│   ├── sync-with-gcp.ps1           # ✅ Sincronização com GCP
│   ├── export-gcp-config.ps1
│   ├── backup-*.ps1
│   └── ... (outros scripts)
│
├── 📁 workflows/                   # Workflows do n8n (espelho)
│   └── *.json                      # 25 workflows sincronizados
│
├── 📁 exports/                     # Backups e exports do GCP
│   ├── gcp-current-YYYYMMDD-HHMMSS/
│   └── backup-*-YYYYMMDD-HHMMSS/
│
├── 📁 archive/                     # Arquivos arquivados
│   └── YYYYMMDD-HHMMSS/           # Arquivos antigos/duplicados
│
├── 📁 config/                      # Configurações gerais
│   └── authorized-networks.json
│
├── 📁 certs/                       # Certificados SSL
│   └── server-ca.pem
│
├── 📁 analysis/                    # Análises e relatórios
│   └── *.json, *.md
│
├── 📁 database/                    # Scripts SQL
│   └── *.sql
│
├── 📁 logs/                        # Logs de execução
│   └── *.log
│
├── README.md                       # ✅ Documentação principal
├── SETUP.md                        # Guia de setup
└── .gitignore                      # Arquivos ignorados pelo Git
```

---

## 🔄 **SINCRONIZAÇÃO COM GCP**

### **Arquivos Sincronizados:**

#### **n8n-cluster:**
- ✅ `n8n-optimized-deployment.yaml` - Deployment principal do n8n
- ✅ `n8n-worker-optimized-deployment.yaml` - Workers do n8n
- ✅ `evolution-api-deployment.yaml` - Evolution API
- ✅ `evolution-api-secret.yaml` - Secret do Evolution API
- ✅ `postgres-ssl-cert-configmap.yaml` - Certificado SSL PostgreSQL
- ✅ `postgres-secret.yaml` - Credenciais PostgreSQL
- ✅ `n8n-service.yaml` - Service do n8n
- ✅ `n8n-ingress.yaml` - Ingress do n8n

#### **metabase-cluster:**
- ✅ `metabase-deployment.yaml` - Deployment do Metabase
- ✅ `postgres-ssl-cert-configmap.yaml` - Certificado SSL PostgreSQL
- ✅ `metabase-service.yaml` - Service do Metabase
- ✅ `metabase-ingress.yaml` - Ingress do Metabase

### **Como Sincronizar:**

```powershell
# Sincronizar todos os clusters
.\scripts\sync-with-gcp.ps1 -Cluster all

# Sincronizar apenas n8n-cluster
.\scripts\sync-with-gcp.ps1 -Cluster n8n

# Dry run (sem alterações)
.\scripts\sync-with-gcp.ps1 -Cluster all -DryRun
```

---

## 🧹 **LIMPEZA E ORGANIZAÇÃO**

### **Arquivos Removidos/Arquivados:**
- ❌ Arquivos temporários (`temp*.yaml`, `*temp*.yaml`)
- ❌ Arquivos duplicados (`*-gcp.yaml`, `*-current.yaml`)
- ❌ Backups antigos (mantidos apenas 3 mais recentes)
- ❌ Arquivos na raiz que devem estar em pastas

### **Como Organizar:**

```powershell
# Organizar projeto (com exportação do GCP)
.\scripts\organize-project.ps1

# Organizar sem exportar GCP
.\scripts\organize-project.ps1 -ExportGCP:$false

# Dry run (ver o que será feito)
.\scripts\organize-project.ps1 -DryRun
```

---

## 📋 **CONVENÇÕES DE NOMENCLATURA**

### **Arquivos YAML:**
- `*-deployment.yaml` - Deployments principais
- `*-service.yaml` - Services
- `*-ingress.yaml` - Ingresses
- `*-secret.yaml` - Secrets (⚠️ não commitar dados sensíveis)
- `*-configmap.yaml` - ConfigMaps
- `*-optimized-deployment.yaml` - Deployments otimizados

### **Documentação:**
- `GUIA_IMPLEMENTACAO_*.md` - Guias de implementação
- `PLANO_ROLLBACK_*.md` - Planos de rollback
- `IMPLEMENTACAO_*.md` - Documentação de implementações
- `ANALISE_*.md` - Análises técnicas
- `STATUS_*.md` - Status atual

### **Scripts:**
- `organize-*.ps1` - Scripts de organização
- `sync-*.ps1` - Scripts de sincronização
- `backup-*.ps1` - Scripts de backup
- `export-*.ps1` - Scripts de exportação

---

## 🔐 **SEGURANÇA**

### **Arquivos Sensíveis:**
- ⚠️ **Secrets**: Não devem ser commitados com dados reais
- ⚠️ **Certificados**: Mantidos em `certs/` (não commitados)
- ⚠️ **Credenciais**: Usar variáveis de ambiente ou Secret Manager

### **Backups:**
- ✅ Backups automáticos em `exports/`
- ✅ Retenção: 3 backups mais recentes
- ✅ Arquivos antigos movidos para `archive/`

---

## 📊 **ESTATÍSTICAS DO PROJETO**

### **Clusters:**
- **n8n-cluster**: 3 deployments (n8n, n8n-worker, evolution-api)
- **metabase-cluster**: 1 deployment (metabase-app)
- **monitoring-cluster**: 2 deployments (prometheus, grafana)

### **Workflows:**
- **25 workflows** sincronizados em `workflows/`

### **Documentação:**
- **49 documentos** em `docs/`

### **Scripts:**
- **38 scripts** em `scripts/`

---

## 🚀 **PRÓXIMOS PASSOS**

1. ✅ **Sincronizar regularmente** com GCP (semanalmente)
2. ✅ **Organizar projeto** antes de commits importantes
3. ✅ **Documentar mudanças** em `docs/CHANGELOG.md`
4. ✅ **Manter backups** atualizados em `exports/`

---

## 📚 **REFERÊNCIAS**

- [README Principal](../README.md)
- [Arquitetura Executiva](ARQUITETURA_EXECUTIVA_ECOSSISTEMA.md)
- [Guia de Implementação SSL](GUIA_IMPLEMENTACAO_SSL_POSTGRES.md)

---

**🎯 Objetivo:** Manter projeto local 100% sincronizado com ambiente Kubernetes do GCP, organizado e documentado.




