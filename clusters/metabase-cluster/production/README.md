# 📊 METABASE-CLUSTER - PRODUÇÃO

## 📋 **VISÃO GERAL**
Cluster de análise de dados Metabase em produção no Google Cloud Platform.

## 🏗️ **COMPONENTES**
- **Metabase**: Plataforma de Business Intelligence
- **PostgreSQL**: Banco de dados analítico (externo)
- **Ingress**: Acesso via HTTPS

## 🚀 **DEPLOYMENT**

### **Aplicar Configurações:**
```bash
# Aplicar todas as configurações
kubectl apply -f clusters/metabase-cluster/production/

# Verificar status
kubectl get pods -n metabase
kubectl get ingress -n metabase
```

### **Arquivos de Configuração:**
- `metabase-deployment.yaml` - Deployment principal
- `metabase-service.yaml` - Service (NodePort)
- `metabase-ingress.yaml` - Ingress com SSL

## 🔗 **ACESSO**
- **URL**: `https://metabase.34.13.117.77.nip.io`
- **Credenciais**: Configurado via setup inicial

## 📊 **STATUS ATUAL**
- **Pod**: `metabase-app-744c995c7f-57zlr` (Running)
- **Service**: `metabase-svc` (NodePort 31920)
- **Ingress**: `metabase-ing` (IP: 34.13.117.77)
- **Namespace**: `metabase`

## 🛠️ **MANUTENÇÃO**

### **Comandos Úteis:**
```bash
# Status
kubectl get pods -n metabase

# Logs
kubectl logs -f deployment/metabase-app -n metabase

# Verificar ingress
kubectl describe ingress metabase-ing -n metabase

# Port-forward para debug
kubectl port-forward service/metabase-svc 3000:80 -n metabase
```

### **Troubleshooting:**
```bash
# Verificar conectividade
kubectl exec -it metabase-pod -- curl http://localhost:3000

# Verificar métricas
kubectl exec -it metabase-pod -- curl http://localhost:3000/api/health

# Verificar configuração
kubectl describe deployment metabase-app -n metabase
```

## 📈 **MONITORAMENTO**
- **Health Check**: `http://localhost:3000/api/health`
- **Métricas**: Expostas em `/api/health`
- **Logs**: `kubectl logs -f deployment/metabase-app -n metabase`

## 🔐 **SEGURANÇA**
- **Network**: Isolamento por namespace
- **Ingress**: HTTPS via nip.io
- **Service**: NodePort para acesso interno

## 📚 **DOCUMENTAÇÃO**
- **Metabase Docs**: https://www.metabase.com/docs/
- **Kubernetes**: https://kubernetes.io/docs/
- **GCP**: https://cloud.google.com/kubernetes-engine
