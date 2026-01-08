# 🚀 LOGCOMEX SALES DATA PLATFORM (LSDP)

## 📋 **VISÃO GERAL**
Plataforma de dados comerciais em tempo real, baseada em Kubernetes no Google Cloud Platform, que espelha dados do HubSpot para PostgreSQL, eliminando limitações de API e fornecendo dashboards comerciais atualizados.

## 🏗️ **ARQUITETURA DO LSDP**

```
🌐 LOGCOMEX SALES DATA PLATFORM (LSDP)
├── n8n-cluster (Sincronização de Dados)
│   ├── n8n (25 workflows ativos)
│   ├── Redis (queue de processamento)
│   └── PostgreSQL (dados comerciais)
├── metabase-cluster (Dashboards Comerciais)
│   └── Metabase (análise de vendas)
└── monitoring-cluster (Monitoramento Técnico)
    ├── Prometheus (métricas de infra)
    ├── Grafana (monitoramento)
    └── AlertManager (alertas)
```

## 📁 **ESTRUTURA DO PROJETO**

```
📦 PROJETO
<<<<<<< Updated upstream
├── n8n-deployment.yaml          # Deploy principal N8N (3 replicas, 350m CPU, 1228Mi RAM)
├── n8n-worker-deployment.yaml   # Deploy workers N8N (3 replicas, 450m CPU, 1843Mi RAM)
├── prometheus-config.yaml       # Configuração Prometheus com Push Gateway
├── workflows/                   # Workflows N8N exportados
├── docs/                        # Documentação técnica
├── scripts/                     # Scripts de automação
=======
├── clusters/                    # ✅ Configurações Kubernetes (sincronizadas com GCP)
│   ├── n8n-cluster/
│   │   ├── production/          # ✅ Configurações de produção (sincronizado)
│   │   └── staging/             # Configurações de staging
│   ├── metabase-cluster/
│   │   ├── production/          # ✅ Configurações do Metabase (sincronizado)
│   │   └── staging/
│   └── monitoring-cluster/
│       ├── production/          # Monitoramento de produção
│       └── staging/
├── workflows/                   # ✅ 25 workflows do n8n (espelho exato)
├── docs/                        # ✅ Documentação técnica completa
├── scripts/                     # ✅ Scripts de automação e organização
│   ├── organize-project.ps1    # 🆕 Organização e limpeza do projeto
│   └── sync-with-gcp.ps1        # 🆕 Sincronização com GCP
├── exports/                     # Backups e exports do GCP
├── archive/                     # Arquivos arquivados
├── config/                      # Configurações gerais
├── certs/                       # Certificados SSL
>>>>>>> Stashed changes
└── README.md                   # Este arquivo
```

**📋 Documentação de Estrutura:** [docs/ESTRUTURA_PROJETO.md](docs/ESTRUTURA_PROJETO.md)

## 🎯 **CLUSTERS**

### **1. N8N-CLUSTER** 🤖
<<<<<<< Updated upstream
**Função:** Automação de workflows e integrações
- **n8n**: Plataforma de automação (3 replicas, 350m CPU, 1228Mi RAM)
- **n8n-workers**: Processamento de workflows (3 replicas, 450m CPU, 1843Mi RAM)
=======
**Função:** Sincronização de dados comerciais HubSpot → PostgreSQL
- **n8n**: 25 workflows de sincronização
>>>>>>> Stashed changes
- **Redis**: Queue de processamento
- **PostgreSQL**: Dados comerciais espelhados
- **URL**: `https://n8n-logcomex.34-8-101-220.nip.io`

#### **📊 Configuração de Recursos Otimizada:**
- **Total CPU**: 3.1 CPU (de 3.92 disponíveis) - 79% utilização
- **Total Memory**: 10.5Gi (de 13.59 disponíveis) - 77% utilização
- **Margem de segurança**: 21% CPU + 23% memória
- **Requests = Limits**: Otimizado para instância fixa e2-standard-4

### **2. METABASE-CLUSTER** 📊
**Função:** Dashboards comerciais e análise de vendas
- **Metabase**: Dashboards de vendas em tempo real
- **PostgreSQL**: Dados comerciais para análise
- **URL**: `https://metabase.34.13.117.77.nip.io`

### **3. MONITORING-CLUSTER-OPTIMIZED** 📈
**Função:** Monitoramento técnico da infraestrutura
- **Prometheus**: Coleta de métricas de sistema
- **Grafana**: Monitoramento de performance
- **AlertManager**: Alertas de infraestrutura
- **URLs**: 
  - Prometheus: `https://prometheus-logcomex.35-186-250-84.nip.io`
  - Grafana: `https://grafana-logcomex.34-8-167-169.nip.io`

## 🚀 **DEPLOYMENT**

### **🔄 Sincronização com GCP**

Antes de fazer deploy, sincronize os arquivos locais com o estado atual do GCP:

```powershell
# Sincronizar todos os clusters
.\scripts\sync-with-gcp.ps1 -Cluster all

# Sincronizar apenas um cluster específico
.\scripts\sync-with-gcp.ps1 -Cluster n8n
.\scripts\sync-with-gcp.ps1 -Cluster metabase
```

### **N8N-CLUSTER**
```bash
# Aplicar configurações de produção
kubectl apply -f clusters/n8n-cluster/production/

# Verificar status
kubectl get pods -n n8n
kubectl get ingress -n n8n
```

### **METABASE-CLUSTER**
```bash
# Aplicar configurações
kubectl apply -f clusters/metabase-cluster/production/

# Verificar status
kubectl get pods -n metabase
kubectl get ingress -n metabase
```

### **MONITORING-CLUSTER**
```bash
# Aplicar configurações
kubectl apply -f clusters/monitoring-cluster/production/

# Verificar status
kubectl get pods -n monitoring-new
kubectl get ingress -n monitoring-new
```

## 🔐 **SEGURANÇA**

### **Implementado:**
- ✅ Security Contexts (non-root)
- ✅ Network Policies
- ✅ Pod Security Standards
- ✅ RBAC (Role-Based Access Control)
- ✅ TLS/SSL (HTTPS)
- ✅ Secrets Management

### **Configurações:**
- **Usuários não-root**: Todos os pods
- **Capabilities**: Drop ALL
- **Seccomp**: RuntimeDefault
- **Network**: Isolamento por namespace

## 📊 **MONITORAMENTO**

### **Métricas Coletadas:**
- **n8n**: Workflow executions, CPU, Memory, Pod status
- **Metabase**: Requests, CPU, Memory, Pod status
- **Infraestrutura**: Node status, Cluster resources, Pod count
- **Dados Comerciais**: Contatos sincronizados, Deals processados, Empresas atualizadas

### **Dashboards:**
- **n8n Overview**: Métricas de sincronização
- **Metabase Overview**: Dashboards comerciais
- **Infrastructure Overview**: Métricas de cluster

### **Alertas:**
- **Pod Down**: Notificação imediata
- **High CPU**: > 80% por 5 minutos
- **High Memory**: > 90% por 5 minutos
- **Disk Space**: < 10% disponível

## 🔄 **SINCRONIZAÇÃO DE DADOS COMERCIAIS**

### **Espelho Perfeito:**
- **Total de workflows**: 25 workflows
- **Sincronização**: 100% com n8n em produção
- **Categorias**:
  - 🔄 Sincronização HubSpot (8 workflows)
    - **Contatos**: 300k+ registros (nome, email, cargo, classificação Ravenna)
    - **Empresas**: Dados corporativos (CNPJ, CNAE, score de crédito, faturamento)
    - **Deals**: Pipeline completo (timeline, qualificação, valores)
    - **Line Items**: Produtos e serviços (preços, margens, SKUs)
    - **Owners**: Equipe comercial e responsabilidades
  - 🔗 Associações (7 workflows) - Relacionamentos empresa-contato-deal
  - 📦 Deals Realtime (3 workflows) - Atualização em tempo real
  - 📊 Análise (2 workflows) - Score de crédito e métricas
  - 📦 Itens de Linha (2 workflows) - Produtos e serviços
  - 🔧 Diversos (3 workflows) - Utilitários e configurações

### **Sincronização de Dados:**
```bash
# Listar workflows de sincronização
kubectl exec -n n8n deployment/n8n -- n8n list:workflow

# Baixar workflow específico
kubectl exec -n n8n deployment/n8n -- n8n export:workflow --id=WORKFLOW_ID

# Verificar dados sincronizados
kubectl exec -n n8n deployment/n8n -- psql -h postgres-host -U user -d database -c "SELECT COUNT(*) FROM contacts;"
```

## 🔄 **BACKUP E RECOVERY**

### **Backup Automatizado:**
- **PostgreSQL**: Backup diário às 2h UTC
- **Retenção**: 30 dias
- **Formato**: Custom dump (otimizado)
- **Validação**: Integridade verificada

### **Recovery:**
```bash
# Restaurar backup
kubectl exec -it postgres-pod -- pg_restore -d n8n-postgres-db /backup/n8n-YYYYMMDD_HHMMSS.dump
```

## 🛠️ **MANUTENÇÃO**

### **Comandos Úteis:**
```bash
# Status geral
kubectl get pods --all-namespaces

# Logs
kubectl logs -f deployment/n8n -n n8n

# Port-forward para debug
kubectl port-forward service/grafana 3000:3000 -n monitoring

# Backup manual
kubectl create job backup-manual --from=cronjob/n8n-backup -n n8n
```

### **Troubleshooting:**
```bash
# Verificar conectividade
kubectl exec -it n8n-pod -- curl http://redis-master:6379

# Verificar métricas
kubectl exec -it n8n-pod -- curl http://localhost:5678/metrics

# Verificar ingress
kubectl describe ingress n8n-ingress -n n8n
```

## 📈 **PERFORMANCE**

### **Recursos Atuais:**
- **n8n**: 2 CPU, 4GB RAM (2 pods + 3 workers)
- **Redis**: 1 CPU, 2GB RAM (StatefulSet)
- **PostgreSQL**: Externo (Cloud SQL)
- **Prometheus**: 1 CPU, 2GB RAM (2 nós)
- **Grafana**: 0.5 CPU, 1GB RAM (2 nós)

### **Otimizações:**
- **HPA**: Auto-scaling baseado em CPU/Memory
- **PDB**: Pod Disruption Budget
- **Resource Limits**: Prevenção de resource starvation

## 🔗 **ACESSOS**

### **Produção:**
- **n8n**: `https://n8n-logcomex.34-8-101-220.nip.io`
- **Metabase**: `https://metabase.34.13.117.77.nip.io`
- **Prometheus**: `https://prometheus-logcomex.35-186-250-84.nip.io`
- **Grafana**: `https://grafana-logcomex.34-8-167-169.nip.io`

### **Credenciais:**
- **n8n**: Configurado via setup inicial
- **Metabase**: Configurado via setup inicial
- **Grafana**: `admin` / `admin123` (alterar em produção)

## 📚 **DOCUMENTAÇÃO**

### **📁 Estrutura e Organização:**
- [Estrutura do Projeto](docs/ESTRUTURA_PROJETO.md) - 🆕 Organização completa do projeto
- [Arquitetura Executiva](docs/ARQUITETURA_EXECUTIVA_ECOSSISTEMA.md) - Visão geral da arquitetura

### **🔐 Segurança e SSL:**
- [Guia de Implementação SSL](docs/GUIA_IMPLEMENTACAO_SSL_POSTGRES.md)
- [Implementação SSL n8n](docs/SOLUCAO_SSL_CREDENCIAIS_N8N.md)
- [Implementação SSL Evolution API](docs/IMPLEMENTACAO_SSL_EVOLUTION_API.md)
- [Implementação SSL Metabase](docs/IMPLEMENTACAO_SSL_METABASE.md)
- [Análise de Segurança](docs/ANALISE_SEGURANCA_PONTOS_CRITICOS.md)

### **📊 Técnica:**
- [Análise de Performance](docs/PERFORMANCE_ANALYSIS_22_09_2025.md)
- [Melhores Práticas](docs/N8N_KUBERNETES_BEST_PRACTICES_ANALYSIS.md)
- [Análise de Custos](docs/COST_ANALYSIS_IMPROVEMENTS.md)
- [Espelho Perfeito de Workflows](docs/ESPELHO_PERFEITO_WORKFLOWS.md)
- [Dashboards do Metabase](docs/METABASE_DASHBOARDS.md)

### **🚀 Implementação:**
- [Guia de Deploy n8n](clusters/n8n-cluster/production/README.md)
- [Configuração de Monitoramento](clusters/monitoring-cluster/production/README.md)
- [Sincronização com GCP](docs/SINCRONIZACAO_COMPLETA_GCP.md)

## 🚨 **SUPORTE**

### **Contatos:**
- **Equipe DevOps**: [Slack Channel]
- **Documentação**: [Confluence]
- **Issues**: [GitHub Issues]

### **Escalação:**
1. **Nível 1**: Equipe DevOps
2. **Nível 2**: Arquitetos de Solução
3. **Nível 3**: Google Cloud Support

---

## 📝 **CHANGELOG**

### **v2.1.0** - 01/12/2025 🆕
- ✅ **Organização completa do projeto**
- ✅ Scripts de sincronização com GCP (`sync-with-gcp.ps1`)
- ✅ Scripts de organização e limpeza (`organize-project.ps1`)
- ✅ Documentação de estrutura do projeto (`ESTRUTURA_PROJETO.md`)
- ✅ README atualizado com informações de sincronização
- ✅ SSL implementado em todos os clusters (n8n, Evolution API, Metabase)
- ✅ Arquivos duplicados e temporários removidos/arquivados
- ✅ Estrutura de pastas 100% organizada

### **v2.0.0** - 30/09/2025
- ✅ Limpeza profunda do projeto
- ✅ Espelho perfeito de workflows (25 workflows)
- ✅ Remoção de arquivos obsoletos
- ✅ Organização de estrutura de pastas
- ✅ Sincronização com estado real dos clusters
- ✅ Documentação atualizada

### **v1.0.0** - 24/09/2025
- ✅ Reorganização completa do projeto
- ✅ Separação de clusters
- ✅ Monitoramento unificado
- ✅ Segurança implementada
- ✅ Backup automatizado
- ✅ Documentação completa

---

## 🎯 **ESTADO ATUAL DO PROJETO**

### **✅ Organização Completa (01/12/2025):**
- **✅ Projeto sincronizado**: Arquivos locais refletem estado atual do GCP
- **✅ Estrutura organizada**: Pastas limpas e lógicas
- **✅ Scripts de automação**: Organização e sincronização automatizadas
- **✅ Documentação consolidada**: 49 documentos organizados
- **✅ SSL implementado**: n8n, Evolution API e Metabase com SSL

### **📊 Estatísticas:**
- **Clusters**: 3 clusters (n8n, metabase, monitoring)
- **Workflows sincronizados**: 25 workflows (espelho perfeito)
- **Scripts ativos**: 38 scripts organizados
- **Documentação**: 49 documentos técnicos
- **Deployments**: 6 deployments principais

### **🔄 Sincronização:**
- **n8n-cluster**: ✅ Sincronizado (n8n, n8n-worker, evolution-api)
- **metabase-cluster**: ✅ Sincronizado (metabase-app)
- **monitoring-cluster**: ✅ Configurado (prometheus, grafana)
- **SSL**: ✅ Implementado em todos os clusters

### **🧹 Limpeza:**
- **Arquivos temporários**: Removidos
- **Arquivos duplicados**: Arquivados
- **Backups antigos**: Mantidos apenas 3 mais recentes
- **Estrutura**: 100% organizada

---

**🎯 Objetivo:** Plataforma robusta, escalável e segura para dados comerciais em tempo real, eliminando limitações de API e fornecendo dashboards comerciais atualizados para o time de vendas da Logcomex.
