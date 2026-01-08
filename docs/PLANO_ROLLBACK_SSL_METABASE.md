# 🔄 PLANO DE ROLLBACK: SSL Metabase

**Data:** 01/12/2025  
**Objetivo:** Plano de rollback caso a implementação SSL cause problemas

---

## 📋 RESUMO

Este documento descreve o plano de rollback para reverter a implementação SSL no Metabase caso ocorram problemas.

---

## ⚠️ QUANDO FAZER ROLLBACK

Faça rollback se:
- ❌ Metabase não consegue conectar ao PostgreSQL após implementação SSL
- ❌ Dashboards param de funcionar
- ❌ Erros de conexão aparecem nos logs
- ❌ Performance degrada significativamente
- ❌ Usuários reportam problemas de acesso

---

## 🔄 ROLLBACK RÁPIDO (5 minutos)

### **Opção 1: Rollback do Deployment (Recomendado)**

```powershell
# 1. Rollback para versão anterior do deployment
kubectl rollout undo deployment/metabase-app -n metabase

# 2. Verificar status
kubectl rollout status deployment/metabase-app -n metabase

# 3. Verificar pod
kubectl get pods -n metabase
```

### **Opção 2: Remover Variáveis SSL**

```powershell
# 1. Editar deployment e remover variáveis SSL
kubectl edit deployment metabase-app -n metabase

# 2. Remover estas linhas:
#    - name: MB_DB_SSL
#      value: "true"
#    - name: MB_DB_SSL_MODE
#      value: "require"
#    - name: MB_DB_SSL_ROOT_CERT
#      value: /etc/postgresql/certs/server-ca.pem

# 3. Remover volumeMounts e volumes relacionados ao certificado
```

---

## 🔄 ROLLBACK COMPLETO (10-15 minutos)

### **1. Reverter Deployment**

```powershell
# Aplicar deployment antigo (sem SSL)
kubectl apply -f clusters/metabase-cluster/production/metabase-deployment.yaml.backup

# Ou fazer rollback
kubectl rollout undo deployment/metabase-app -n metabase
```

### **2. Remover ConfigMap SSL (Opcional)**

```powershell
# Remover ConfigMap do certificado (não é necessário, mas pode ser feito)
kubectl delete configmap postgres-ssl-cert -n metabase
```

### **3. Verificar Status**

```powershell
# Verificar pods
kubectl get pods -n metabase

# Verificar logs
kubectl logs -n metabase deployment/metabase-app --tail=50

# Verificar conexão
kubectl exec -n metabase deployment/metabase-app -- curl http://localhost:3000/api/health
```

---

## 📝 ROLLBACK MANUAL (Se necessário)

### **1. Exportar Configuração Atual**

```powershell
# Exportar deployment atual (com SSL)
kubectl get deployment metabase-app -n metabase -o yaml > metabase-deployment-with-ssl.yaml
```

### **2. Editar e Remover SSL**

Editar o arquivo e remover:
- Variáveis de ambiente SSL (`MB_DB_SSL`, `MB_DB_SSL_MODE`, `MB_DB_SSL_ROOT_CERT`)
- Volume mounts do certificado
- Volumes do ConfigMap

### **3. Aplicar Configuração Antiga**

```powershell
# Aplicar deployment sem SSL
kubectl apply -f metabase-deployment-without-ssl.yaml

# Verificar rollout
kubectl rollout status deployment/metabase-app -n metabase
```

---

## 🔍 VERIFICAÇÃO PÓS-ROLLBACK

### **Checklist:**

- [ ] Pod está `Running` e `Ready`
- [ ] Logs não mostram erros de conexão
- [ ] Health check responde: `kubectl exec -n metabase deployment/metabase-app -- curl http://localhost:3000/api/health`
- [ ] Dashboards funcionam normalmente
- [ ] Usuários conseguem acessar Metabase
- [ ] Conexões PostgreSQL funcionam

### **Comandos de Verificação:**

```powershell
# Status do pod
kubectl get pods -n metabase

# Logs
kubectl logs -n metabase deployment/metabase-app --tail=50 | Select-String -Pattern "database|Database|SSL|error|Error"

# Health check
kubectl exec -n metabase deployment/metabase-app -- curl -s http://localhost:3000/api/health

# Verificar variáveis de ambiente (não deve ter SSL)
kubectl exec -n metabase deployment/metabase-app -- env | Select-String -Pattern "MB_DB_SSL"
```

---

## 📋 ARQUIVOS DE BACKUP

Antes de aplicar SSL, os seguintes arquivos foram criados como backup:

- `exports/backup-metabase-before-ssl-YYYYMMDD-HHMMSS/metabase-deployment.yaml`
- `exports/backup-metabase-before-ssl-YYYYMMDD-HHMMSS/metabase-configmaps.yaml`
- `exports/backup-metabase-before-ssl-YYYYMMDD-HHMMSS/metabase-secrets.yaml`

### **Restaurar do Backup:**

```powershell
# Aplicar deployment do backup
kubectl apply -f exports/backup-metabase-before-ssl-YYYYMMDD-HHMMSS/metabase-deployment.yaml

# Verificar
kubectl rollout status deployment/metabase-app -n metabase
```

---

## ⚡ ROLLBACK DE EMERGÊNCIA (1 minuto)

Se o Metabase estiver completamente inacessível:

```powershell
# Rollback imediato
kubectl rollout undo deployment/metabase-app -n metabase

# Aguardar
kubectl rollout status deployment/metabase-app -n metabase --timeout=60s
```

---

## 📞 CONTATOS E SUPORTE

Se o rollback não resolver o problema:

1. **Verificar logs detalhados:**
   ```powershell
   kubectl logs -n metabase deployment/metabase-app --previous
   ```

2. **Verificar eventos:**
   ```powershell
   kubectl get events -n metabase --sort-by='.lastTimestamp' | Select-Object -Last 20
   ```

3. **Verificar configuração do PostgreSQL:**
   - Verificar se o banco está acessível
   - Verificar se as credenciais estão corretas
   - Verificar se há mudanças no Cloud SQL

---

## ✅ CHECKLIST PÓS-ROLLBACK

Após fazer rollback, verificar:

- [ ] ✅ Pod está `Running` e `Ready`
- [ ] ✅ Logs não mostram erros
- [ ] ✅ Health check funciona
- [ ] ✅ Dashboards funcionam
- [ ] ✅ Usuários conseguem acessar
- [ ] ✅ Conexões PostgreSQL funcionam
- [ ] ✅ Performance normal

---

**Última Atualização:** 01/12/2025  
**Status:** ✅ Plano Pronto




