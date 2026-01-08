# ✅ CHECKLIST: Implementação SSL PostgreSQL

**Data:** 28/11/2025  
**Status:** Pronto para Implementação

---

## 📋 O QUE JÁ FOI FEITO

- [x] ConfigMap criado localmente (`postgres-ssl-cert-configmap.yaml`)
- [x] Deployments atualizados com variáveis SSL
- [x] Volume mounts configurados nos deployments
- [x] Documentação criada

---

## 🚀 O QUE FALTA FAZER

### **PASSO 1: Aplicar ConfigMap no Cluster GCP** ⚠️

```powershell
kubectl apply -f clusters/n8n-cluster/production/postgres-ssl-cert-configmap.yaml
```

**Verificar:**
```powershell
kubectl get configmap postgres-ssl-cert -n n8n
kubectl describe configmap postgres-ssl-cert -n n8n
```

---

### **PASSO 2: Aplicar Deployments Atualizados** ⚠️

**Opção A: Aplicar arquivos completos (RECOMENDADO)**
```powershell
# Deployment principal
kubectl apply -f clusters/n8n-cluster/production/n8n-optimized-deployment.yaml

# Deployment worker
kubectl apply -f clusters/n8n-cluster/production/n8n-worker-optimized-deployment.yaml
```

**Opção B: Apenas reiniciar (se já aplicou antes)**
```powershell
kubectl rollout restart deployment/n8n -n n8n
kubectl rollout restart deployment/n8n-worker -n n8n
```

---

### **PASSO 3: Verificar Status dos Pods** ⚠️

```powershell
# Ver pods
kubectl get pods -n n8n

# Aguardar pods ficarem Ready
kubectl wait --for=condition=ready pod -l service=n8n -n n8n --timeout=300s
kubectl wait --for=condition=ready pod -l app=n8n-worker -n n8n --timeout=300s
```

---

### **PASSO 4: Validar Certificado Montado** ⚠️

```powershell
# Verificar se certificado está montado no pod n8n
kubectl exec -n n8n deployment/n8n -- ls -la /etc/postgresql/certs/

# Verificar conteúdo do certificado
kubectl exec -n n8n deployment/n8n -- cat /etc/postgresql/certs/server-ca.pem

# Verificar no worker também
kubectl exec -n n8n deployment/n8n-worker -- ls -la /etc/postgresql/certs/
```

---

### **PASSO 5: Verificar Variáveis de Ambiente SSL** ⚠️

```powershell
# Verificar variáveis SSL no pod n8n
kubectl exec -n n8n deployment/n8n -- env | Select-String -Pattern "DB_POSTGRESDB_SSL"

# Verificar no worker
kubectl exec -n n8n deployment/n8n-worker -- env | Select-String -Pattern "DB_POSTGRESDB_SSL"
```

**Deve mostrar:**
- `DB_POSTGRESDB_SSL_ENABLED=true`
- `DB_POSTGRESDB_SSL_CA_FILE=/etc/postgresql/certs/server-ca.pem`
- `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=true`

---

### **PASSO 6: Verificar Logs para Confirmar SSL** ⚠️

```powershell
# Ver logs do n8n
kubectl logs -n n8n deployment/n8n --tail=50 | Select-String -Pattern "SSL\|TLS\|postgres\|database\|connection"

# Ver logs do worker
kubectl logs -n n8n deployment/n8n-worker --tail=50 | Select-String -Pattern "SSL\|TLS\|postgres\|database\|connection"

# Verificar se não há erros de conexão
kubectl logs -n n8n deployment/n8n --tail=100 | Select-String -Pattern "error\|Error\|ERROR\|failed\|Failed"
```

---

### **PASSO 7: Testar Conexão (Opcional)** ⚠️

Se tiver acesso ao Cloud SQL, verificar logs de conexão para confirmar que está usando SSL.

---

## 📝 ORDEM DE EXECUÇÃO RECOMENDADA

1. ✅ **Aplicar ConfigMap primeiro** (obrigatório antes dos deployments)
2. ✅ **Aplicar deployment n8n**
3. ✅ **Aplicar deployment n8n-worker**
4. ✅ **Aguardar pods ficarem Ready**
5. ✅ **Validar certificado montado**
6. ✅ **Verificar variáveis de ambiente**
7. ✅ **Verificar logs**

---

## ⚠️ PONTOS DE ATENÇÃO

### **Antes de Aplicar:**
- [ ] Fazer backup da configuração atual (opcional)
- [ ] Verificar se está conectado ao cluster correto: `kubectl config current-context`
- [ ] Confirmar namespace: `kubectl get namespace n8n`

### **Durante a Aplicação:**
- [ ] Aplicar ConfigMap **ANTES** dos deployments
- [ ] Monitorar rollout: `kubectl rollout status deployment/n8n -n n8n`
- [ ] Verificar se pods estão iniciando corretamente

### **Após Aplicação:**
- [ ] Verificar se não há erros nos logs
- [ ] Testar acesso ao n8n via web
- [ ] Verificar se workflows estão funcionando

---

## 🔧 COMANDOS ÚTEIS

### Ver status do rollout:
```powershell
kubectl rollout status deployment/n8n -n n8n
kubectl rollout status deployment/n8n-worker -n n8n
```

### Ver histórico de rollouts:
```powershell
kubectl rollout history deployment/n8n -n n8n
kubectl rollout history deployment/n8n-worker -n n8n
```

### Reverter se necessário:
```powershell
kubectl rollout undo deployment/n8n -n n8n
kubectl rollout undo deployment/n8n-worker -n n8n
```

### Ver eventos recentes:
```powershell
kubectl get events -n n8n --sort-by='.lastTimestamp' | Select-Object -Last 20
```

---

## ✅ CHECKLIST FINAL

- [ ] ConfigMap aplicado e verificado
- [ ] Deployment n8n aplicado e pods Ready
- [ ] Deployment n8n-worker aplicado e pods Ready
- [ ] Certificado montado corretamente
- [ ] Variáveis SSL configuradas
- [ ] Logs sem erros de conexão
- [ ] n8n acessível via web
- [ ] Workflows funcionando normalmente

---

## 🆘 TROUBLESHOOTING RÁPIDO

### Pod não inicia:
```powershell
kubectl describe pod <pod-name> -n n8n
kubectl logs <pod-name> -n n8n --previous
```

### Certificado não encontrado:
```powershell
# Verificar se ConfigMap existe
kubectl get configmap postgres-ssl-cert -n n8n

# Verificar volume mount
kubectl describe pod <pod-name> -n n8n | Select-String -Pattern "postgres-ssl-cert"
```

### Erro de conexão SSL:
```powershell
# Verificar logs detalhados
kubectl logs -n n8n deployment/n8n --tail=200

# Verificar variáveis de ambiente
kubectl exec -n n8n deployment/n8n -- env | Select-String -Pattern "DB_POSTGRESDB"
```

---

**Próximo Passo:** Executar PASSO 1 (Aplicar ConfigMap)




