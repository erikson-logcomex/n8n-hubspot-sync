# 🚀 ECOSSISTEMA LOGCOMEX - KUBERNETES

## 📋 **VISÃO GERAL**
Sistema completo de automação, análise e monitoramento baseado em Kubernetes no Google Cloud Platform.

## 🏗️ **ARQUITETURA DO ECOSSISTEMA**

```
🌐 ECOSSISTEMA LOGCOMEX
├── n8n-cluster (Automação)
│   ├── n8n (workflows)
│   ├── Redis (queue)
│   └── PostgreSQL (dados)
├── metabase-cluster (Análise)
│   └── Metabase (dashboards)
└── monitoring-cluster (Observabilidade)
    ├── Prometheus (métricas)
    ├── Grafana (visualização)
    └── AlertManager (alertas)
```

## 📁 **ESTRUTURA DO PROJETO**

```
📦 PROJETO
├── clusters/
│   ├── n8n-cluster/
│   │   ├── production/          # Configurações de produção
│   │   └── staging/             # Configurações de staging
│   ├── metabase-cluster/
│   │   └── production/          # Configurações do Metabase
│   └── monitoring-cluster/
│       ├── production/          # Monitoramento de produção
│       └── staging/            # Monitoramento de staging
├── docs/                        # Documentação técnica
├── scripts/                     # Scripts de automação
└── README.md                   # Este arquivo
```

## 🎯 **CLUSTERS**

### **1. N8N-CLUSTER** 🤖
**Função:** Automação de workflows e integrações
- **n8n**: Plataforma de automação
- **Redis**: Queue de processamento
- **PostgreSQL**: Banco de dados principal
- **URL**: `https://n8n-logcomex.34-8-101-220.nip.io`

### **2. METABASE-CLUSTER** 📊
**Função:** Análise de dados e dashboards
- **Metabase**: Plataforma de BI
- **PostgreSQL**: Banco de dados analítico
- **URL**: `https://metabase-logcomex.34-8-101-220.nip.io`

### **3. MONITORING-CLUSTER** 📈
**Função:** Observabilidade e monitoramento
- **Prometheus**: Coleta de métricas
- **Grafana**: Visualização e dashboards
- **AlertManager**: Gerenciamento de alertas
- **URLs**: 
  - Prometheus: `https://prometheus-logcomex.34-39-161-97.nip.io`
  - Grafana: `https://grafana-logcomex.34-39-178-152.nip.io`

## 🚀 **DEPLOYMENT**

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

### **Dashboards:**
- **n8n Overview**: Métricas de automação
- **Metabase Overview**: Métricas de análise
- **Infrastructure Overview**: Métricas de cluster

### **Alertas:**
- **Pod Down**: Notificação imediata
- **High CPU**: > 80% por 5 minutos
- **High Memory**: > 90% por 5 minutos
- **Disk Space**: < 10% disponível

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
- **n8n**: 2 CPU, 4GB RAM
- **Redis**: 1 CPU, 2GB RAM
- **PostgreSQL**: 2 CPU, 4GB RAM
- **Prometheus**: 1 CPU, 2GB RAM
- **Grafana**: 0.5 CPU, 1GB RAM

### **Otimizações:**
- **HPA**: Auto-scaling baseado em CPU/Memory
- **PDB**: Pod Disruption Budget
- **Resource Limits**: Prevenção de resource starvation

## 🔗 **ACESSOS**

### **Produção:**
- **n8n**: `https://n8n-logcomex.34-8-101-220.nip.io`
- **Metabase**: `https://metabase.34.13.117.77.nip.io`
- **Prometheus**: `https://prometheus-logcomex.34-39-161-97.nip.io`
- **Grafana**: `https://grafana-logcomex.34-39-178-152.nip.io`

### **Credenciais:**
- **n8n**: Configurado via setup inicial
- **Metabase**: Configurado via setup inicial
- **Grafana**: `admin` / `admin123` (alterar em produção)

## 📚 **DOCUMENTAÇÃO**

### **Técnica:**
- [Análise de Performance](docs/PERFORMANCE_ANALYSIS_22_09_2025.md)
- [Melhores Práticas](docs/N8N_KUBERNETES_BEST_PRACTICES_ANALYSIS.md)
- [Análise de Custos](docs/COST_ANALYSIS_IMPROVEMENTS.md)

### **Implementação:**
- [Guia de Deploy](clusters/n8n-cluster/production/README.md)
- [Configuração de Monitoramento](clusters/monitoring-cluster/production/README.md)

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

### **v1.0.0** - 24/09/2025
- ✅ Reorganização completa do projeto
- ✅ Separação de clusters
- ✅ Monitoramento unificado
- ✅ Segurança implementada
- ✅ Backup automatizado
- ✅ Documentação completa

---

**🎯 Objetivo:** Sistema robusto, escalável e seguro para automação e análise de dados da Logcomex.
