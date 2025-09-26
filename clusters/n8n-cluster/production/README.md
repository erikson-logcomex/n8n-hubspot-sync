# 🤖 N8N-CLUSTER - PRODUÇÃO

## 📋 **VISÃO GERAL**
Cluster de automação n8n em produção no Google Cloud Platform.

## 🏗️ **COMPONENTES**
- **n8n**: Plataforma de automação
- **Redis**: Queue de processamento
- **PostgreSQL**: Banco de dados principal
- **Backup**: Automatizado diário

## 🚀 **DEPLOYMENT**

### **Aplicar Configurações:**
```bash
# Aplicar todas as configurações
kubectl apply -f clusters/n8n-cluster/production/

# Verificar status
kubectl get pods -n n8n
kubectl get ingress -n n8n
```

### **Arquivos de Configuração:**
- `n8n-deployment.yaml` - Deployment principal
- `n8n-service.yaml` - Service
- `n8n-ingress.yaml` - Ingress com SSL
- `n8n-ssl-certificate.yaml` - Certificado SSL
- `n8n-worker-deployment.yaml` - Workers
- `backup-cronjob.yaml` - Backup automatizado
- `backup-pvc.yaml` - Storage para backup
- `storage.yaml` - Storage principal
- `postgres-secret.yaml` - Secrets do PostgreSQL

## 🔐 **SEGURANÇA**
- ✅ Security Contexts (non-root)
- ✅ Network Policies
- ✅ Pod Security Standards
- ✅ TLS/SSL (HTTPS)

## 📊 **MONITORAMENTO**
- **Métricas**: Expostas em `/metrics`
- **Health Check**: `http://localhost:5678/healthz`
- **Logs**: `kubectl logs -f deployment/n8n -n n8n`

## 🔄 **BACKUP**
- **Frequência**: Diário às 2h UTC
- **Retenção**: 30 dias
- **Formato**: Custom dump otimizado
- **Validação**: Integridade verificada

## 🔗 **ACESSO**
- **URL**: `https://n8n-logcomex.34-8-101-220.nip.io`
- **Credenciais**: Configurado via setup inicial

## 🛠️ **MANUTENÇÃO**

### **Comandos Úteis:**
```bash
# Status
kubectl get pods -n n8n

# Logs
kubectl logs -f deployment/n8n -n n8n

# Backup manual
kubectl create job backup-manual --from=cronjob/n8n-backup -n n8n

# Verificar ingress
kubectl describe ingress n8n-ingress -n n8n
```

### **Troubleshooting:**
```bash
# Verificar conectividade Redis
kubectl exec -it n8n-pod -- curl http://redis-master:6379

# Verificar métricas
kubectl exec -it n8n-pod -- curl http://localhost:5678/metrics

# Verificar health
kubectl exec -it n8n-pod -- curl http://localhost:5678/healthz
```