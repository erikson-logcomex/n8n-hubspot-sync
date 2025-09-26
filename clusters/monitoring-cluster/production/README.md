# 🎯 MONITORING CLUSTER - PRODUÇÃO

## 📋 **VISÃO GERAL**
Cluster dedicado para observabilidade e monitoramento de todos os clusters do ecossistema.

## 🏗️ **ARQUITETURA**
```
monitoring-cluster
├── Prometheus (métricas)
├── Grafana (visualização)
├── AlertManager (alertas)
└── Node Exporter (métricas de nós)
```

## 🎯 **OBJETIVOS**
- ✅ Monitorar n8n-cluster
- ✅ Monitorar metabase-cluster  
- ✅ Dashboards unificados
- ✅ Alertas centralizados
- ✅ Métricas de infraestrutura

## 📁 **ESTRUTURA**
```
production/
├── prometheus/
│   ├── prometheus-deployment.yaml
│   ├── prometheus-config.yaml
│   └── prometheus-service.yaml
├── grafana/
│   ├── grafana-deployment.yaml
│   ├── grafana-dashboards/
│   └── grafana-datasources/
├── alertmanager/
│   ├── alertmanager-deployment.yaml
│   └── alertmanager-config.yaml
└── node-exporter/
    └── node-exporter-daemonset.yaml
```

## 🔗 **CONECTIVIDADE**
- **n8n-cluster**: Métricas via ServiceMonitor
- **metabase-cluster**: Métricas via ServiceMonitor
- **Grafana**: Dashboards unificados
- **AlertManager**: Notificações Slack/Email

## 🚀 **DEPLOYMENT**
```bash
# Aplicar configurações
kubectl apply -f prometheus/
kubectl apply -f grafana/
kubectl apply -f monitoring-ssl-certificate.yaml
kubectl apply -f monitoring-ingress.yaml

# Verificar status
kubectl get pods -n monitoring-new
kubectl get ingress -n monitoring-new
kubectl get managedcertificate -n monitoring-new
```

## 🌐 **ACESSOS**
- **Prometheus**: `https://prometheus-logcomex.34-39-161-97.nip.io`
- **Grafana**: `https://grafana-logcomex.34-39-178-152.nip.io`
- **Credenciais Grafana**: `admin` / `admin123`

## 🔐 **SEGURANÇA**
- Network Policies
- RBAC
- TLS/SSL
- Secrets management
