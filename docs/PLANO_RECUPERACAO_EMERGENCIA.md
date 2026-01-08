# 🚨 PLANO DE RECUPERAÇÃO DE EMERGÊNCIA - MONITORING CLUSTER

**Data:** 25 de Setembro de 2025  
**Status:** CRÍTICO - Cluster sem nós  
**Prioridade:** MÁXIMA  

## 🔥 SITUAÇÃO ATUAL

- ❌ **Cluster sem nós** - pods em status Pending
- ❌ **Grafana e Prometheus offline**
- ❌ **Domínios e certificados podem estar afetados**
- ✅ **Backup completo disponível** em `backup_monitoring_20250925_134946`

## 🎯 PLANO DE RECUPERAÇÃO IMEDIATO

### **FASE 1: RESTAURAR INFRAESTRUTURA (URGENTE)**

1. **Criar node pool de emergência**
   ```bash
   gcloud container node-pools create emergency-pool \
     --cluster=monitoring-cluster \
     --region=southamerica-east1 \
     --num-nodes=2 \
     --machine-type=e2-small \
     --disk-size=100 \
     --disk-type=pd-balanced
   ```

2. **Verificar se os pods voltam a funcionar**
   ```bash
   kubectl get pods -n monitoring-new
   kubectl get nodes
   ```

### **FASE 2: RESTAURAR DADOS (SE NECESSÁRIO)**

3. **Se os PVCs foram perdidos, restaurar do backup:**
   ```bash
   # Restaurar dados do Grafana
   kubectl cp backup_monitoring_20250925_134946/grafana-backup.tar.gz \
     monitoring-new/grafana-pod:/tmp/grafana-backup.tar.gz
   
   kubectl exec -n monitoring-new grafana-pod -- \
     tar -xzf /tmp/grafana-backup.tar.gz -C /var/lib/grafana
   
   # Restaurar dados do Prometheus
   kubectl cp backup_monitoring_20250925_134946/prometheus-backup.tar.gz \
     monitoring-new/prometheus-pod:/tmp/prometheus-backup.tar.gz
   
   kubectl exec -n monitoring-new prometheus-pod -- \
     tar -xzf /tmp/prometheus-backup.tar.gz -C /prometheus
   ```

### **FASE 3: VERIFICAR DOMÍNIOS E CERTIFICADOS**

4. **Verificar ingress e certificados:**
   ```bash
   kubectl get ingress -n monitoring-new
   kubectl get managedcertificate -n monitoring-new
   kubectl get service -n monitoring-new
   ```

5. **Se necessário, recriar ingress:**
   ```bash
   kubectl apply -f clusters/monitoring-cluster/production/monitoring-https-fixed.yaml
   ```

### **FASE 4: TESTAR FUNCIONALIDADES**

6. **Verificar acesso aos serviços:**
   - Grafana: `https://grafana-logcomex.35-186-250-84.nip.io`
   - Prometheus: `https://prometheus-logcomex.35-186-250-84.nip.io`

7. **Verificar dashboards e dados:**
   - Login no Grafana (admin/admin123)
   - Verificar dashboards existentes
   - Verificar datasources
   - Verificar dados históricos do Prometheus

## 🔧 COMANDOS DE EMERGÊNCIA

### **Criar node pool de emergência:**
```bash
gcloud container node-pools create emergency-pool \
  --cluster=monitoring-cluster \
  --region=southamerica-east1 \
  --num-nodes=2 \
  --machine-type=e2-small \
  --disk-size=100 \
  --disk-type=pd-balanced
```

### **Verificar status:**
```bash
kubectl get nodes
kubectl get pods -n monitoring-new
kubectl get pvc -n monitoring-new
kubectl get ingress -n monitoring-new
```

### **Restaurar configurações se necessário:**
```bash
kubectl apply -f backup_monitoring_20250925_134946/deployments.yaml
kubectl apply -f backup_monitoring_20250925_134946/services.yaml
kubectl apply -f backup_monitoring_20250925_134946/pvcs.yaml
```

## 📋 CHECKLIST DE RECUPERAÇÃO

- [ ] Node pool criado e funcionando
- [ ] Pods do Grafana e Prometheus rodando
- [ ] PVCs funcionando (dados preservados)
- [ ] Ingress funcionando
- [ ] Certificados SSL funcionando
- [ ] Domínios acessíveis
- [ ] Login no Grafana funcionando
- [ ] Dashboards carregando
- [ ] Dados históricos do Prometheus preservados
- [ ] HPA funcionando
- [ ] Resource limits aplicados

## ⚠️ LIÇÕES APRENDIDAS

1. **NUNCA** fazer alterações em cluster de produção sem autorização explícita
2. **SEMPRE** testar em ambiente de desenvolvimento primeiro
3. **SEMPRE** fazer backup completo antes de qualquer alteração
4. **SEMPRE** planejar rollback antes de fazer mudanças
5. **SEMPRE** comunicar claramente o que será alterado

## 🆘 CONTATOS DE EMERGÊNCIA

- **Backup disponível:** `backup_monitoring_20250925_134946/`
- **Configurações originais:** `clusters/monitoring-cluster/production/`
- **Documentação:** `docs/ANALISE_MONITORING_CLUSTER_OTIMIZACAO.md`

---

**Status:** Aguardando execução do plano de recuperação  
**Próximo passo:** Criar node pool de emergência


