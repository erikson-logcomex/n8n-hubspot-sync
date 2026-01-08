# 🔄 PLANO DE ROLLBACK: Implementação SSL PostgreSQL

**Data:** 28/11/2025  
**Objetivo:** Reverter mudanças de SSL em caso de problemas

---

## 📋 RESUMO

Este documento descreve os procedimentos de rollback caso a implementação do SSL cause problemas no n8n.

---

## ⚠️ QUANDO FAZER ROLLBACK

Faça rollback se:
- ❌ Pods não iniciam após aplicar SSL
- ❌ Erros de conexão com PostgreSQL
- ❌ n8n não acessível via web
- ❌ Workflows parando de funcionar
- ❌ Erros nos logs relacionados a SSL/certificado

---

## 🔄 ESTRATÉGIAS DE ROLLBACK

### **ESTRATÉGIA 1: Rollback Rápido (Recomendado) - Apenas Deployments**

Use quando:
- ConfigMap está OK, mas deployments têm problemas
- Quer reverter apenas as mudanças de SSL, mantendo outras atualizações

#### Passo 1: Reverter Deployment n8n
```powershell
# Ver histórico de rollouts
kubectl rollout history deployment/n8n -n n8n

# Reverter para versão anterior
kubectl rollout undo deployment/n8n -n n8n

# Ou reverter para versão específica
kubectl rollout undo deployment/n8n -n n8n --to-revision=<número>
```

#### Passo 2: Reverter Deployment n8n-worker
```powershell
# Ver histórico
kubectl rollout history deployment/n8n-worker -n n8n

# Reverter
kubectl rollout undo deployment/n8n-worker -n n8n

# Ou versão específica
kubectl rollout undo deployment/n8n-worker -n n8n --to-revision=<número>
```

#### Passo 3: Verificar Status
```powershell
# Aguardar rollback completar
kubectl rollout status deployment/n8n -n n8n
kubectl rollout status deployment/n8n-worker -n n8n

# Verificar pods
kubectl get pods -n n8n
```

**Tempo estimado:** 2-5 minutos

---

### **ESTRATÉGIA 2: Rollback Completo - Remover SSL Completamente**

Use quando:
- Quer remover todas as mudanças de SSL
- Voltar para configuração sem SSL

#### Passo 1: Remover Variáveis SSL dos Deployments

**Opção A: Editar deployments manualmente**
```powershell
# Editar deployment n8n
kubectl edit deployment n8n -n n8n

# Remover estas variáveis:
# - DB_POSTGRESDB_SSL_ENABLED
# - DB_POSTGRESDB_SSL_CA_FILE
# - DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED

# Remover volume mount:
# - postgres-ssl-cert

# Remover volume:
# - postgres-ssl-cert
```

**Opção B: Aplicar deployment sem SSL (se tiver backup)**
```powershell
# Se tiver arquivo de backup sem SSL
kubectl apply -f <caminho-do-backup-sem-ssl>
```

#### Passo 2: Remover ConfigMap (Opcional)
```powershell
# Remover ConfigMap
kubectl delete configmap postgres-ssl-cert -n n8n

# Verificar remoção
kubectl get configmap postgres-ssl-cert -n n8n
```

#### Passo 3: Reiniciar Pods
```powershell
# Forçar restart para aplicar mudanças
kubectl rollout restart deployment/n8n -n n8n
kubectl rollout restart deployment/n8n-worker -n n8n
```

**Tempo estimado:** 5-10 minutos

---

### **ESTRATÉGIA 3: Rollback para Versão Anterior do GCP**

Use quando:
- Quer voltar exatamente para o estado anterior do GCP
- Tem exportação da configuração anterior

#### Passo 1: Aplicar Configuração Anterior
```powershell
# Se tiver exportação da configuração anterior do GCP
kubectl apply -f <caminho-da-exportacao-anterior>
```

#### Passo 2: Verificar
```powershell
kubectl get pods -n n8n
kubectl logs -n n8n deployment/n8n --tail=50
```

**Tempo estimado:** 5-10 minutos

---

## 🛠️ PROCEDIMENTOS DETALHADOS

### **CENÁRIO 1: Pod não inicia após aplicar SSL**

#### Diagnóstico:
```powershell
# Ver status do pod
kubectl get pods -n n8n

# Ver detalhes do pod
kubectl describe pod <pod-name> -n n8n

# Ver logs do pod anterior (se houver)
kubectl logs <pod-name> -n n8n --previous
```

#### Rollback:
```powershell
# Reverter deployment
kubectl rollout undo deployment/n8n -n n8n
kubectl rollout undo deployment/n8n-worker -n n8n

# Aguardar
kubectl rollout status deployment/n8n -n n8n
```

---

### **CENÁRIO 2: Erro de conexão com PostgreSQL**

#### Diagnóstico:
```powershell
# Ver logs
kubectl logs -n n8n deployment/n8n --tail=100 | Select-String -Pattern "error\|Error\|postgres\|SSL\|certificate"

# Verificar variáveis SSL
kubectl exec -n n8n deployment/n8n -- env | Select-String -Pattern "DB_POSTGRESDB_SSL"
```

#### Rollback Rápido:
```powershell
# Remover variáveis SSL via patch
kubectl patch deployment n8n -n n8n --type=json -p='[
  {"op": "remove", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "DB_POSTGRESDB_SSL_ENABLED"}},
  {"op": "remove", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "DB_POSTGRESDB_SSL_CA_FILE"}},
  {"op": "remove", "path": "/spec/template/spec/containers/0/env/-", "value": {"name": "DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED"}}
]'
```

**OU** reverter deployment completo:
```powershell
kubectl rollout undo deployment/n8n -n n8n
kubectl rollout undo deployment/n8n-worker -n n8n
```

---

### **CENÁRIO 3: Certificado não encontrado**

#### Diagnóstico:
```powershell
# Verificar se ConfigMap existe
kubectl get configmap postgres-ssl-cert -n n8n

# Verificar se está montado
kubectl exec -n n8n deployment/n8n -- ls -la /etc/postgresql/certs/
```

#### Rollback:
```powershell
# Se ConfigMap não existe, criar ou remover SSL
# Opção 1: Criar ConfigMap
kubectl apply -f clusters/n8n-cluster/production/postgres-ssl-cert-configmap.yaml

# Opção 2: Remover SSL dos deployments
kubectl rollout undo deployment/n8n -n n8n
kubectl rollout undo deployment/n8n-worker -n n8n
```

---

### **CENÁRIO 4: n8n não acessível via web**

#### Diagnóstico:
```powershell
# Verificar pods
kubectl get pods -n n8n

# Ver logs
kubectl logs -n n8n deployment/n8n --tail=100

# Verificar ingress
kubectl get ingress -n n8n
```

#### Rollback:
```powershell
# Reverter deployments
kubectl rollout undo deployment/n8n -n n8n
kubectl rollout undo deployment/n8n-worker -n n8n

# Aguardar pods ficarem Ready
kubectl wait --for=condition=ready pod -l service=n8n -n n8n --timeout=300s
```

---

## 📝 CHECKLIST DE ROLLBACK

### Antes de Fazer Rollback:
- [ ] Identificar o problema específico
- [ ] Verificar logs para entender causa
- [ ] Decidir qual estratégia usar
- [ ] Fazer backup da configuração atual (opcional)

### Durante Rollback:
- [ ] Executar comandos de rollback
- [ ] Monitorar status dos pods
- [ ] Verificar logs após rollback

### Após Rollback:
- [ ] Verificar se pods estão Running
- [ ] Testar acesso ao n8n
- [ ] Verificar se workflows funcionam
- [ ] Confirmar conexão com PostgreSQL
- [ ] Documentar o que aconteceu

---

## 🔍 COMANDOS DE VERIFICAÇÃO PÓS-ROLLBACK

```powershell
# 1. Verificar status dos pods
kubectl get pods -n n8n

# 2. Verificar se não há variáveis SSL
kubectl exec -n n8n deployment/n8n -- env | Select-String -Pattern "DB_POSTGRESDB_SSL"
# (Não deve retornar nada)

# 3. Verificar logs sem erros
kubectl logs -n n8n deployment/n8n --tail=50 | Select-String -Pattern "error\|Error\|ERROR"

# 4. Testar conexão (se possível)
# Acessar n8n via web e verificar se funciona

# 5. Verificar histórico de rollouts
kubectl rollout history deployment/n8n -n n8n
kubectl rollout history deployment/n8n-worker -n n8n
```

---

## ⏱️ TEMPO ESTIMADO DE ROLLBACK

| Estratégia | Tempo Estimado | Complexidade |
|------------|----------------|-------------|
| Rollback Rápido (undo) | 2-5 minutos | ⭐ Fácil |
| Remover SSL Manualmente | 5-10 minutos | ⭐⭐ Média |
| Rollback Completo | 5-10 minutos | ⭐⭐ Média |
| Aplicar Configuração Anterior | 5-10 minutos | ⭐⭐ Média |

---

## 🆘 ROLLBACK DE EMERGÊNCIA (Mais Rápido)

Se precisar reverter **IMEDIATAMENTE**:

```powershell
# 1. Reverter ambos deployments (1 comando)
kubectl rollout undo deployment/n8n -n n8n && kubectl rollout undo deployment/n8n-worker -n n8n

# 2. Aguardar (em paralelo)
Start-Job -ScriptBlock { kubectl rollout status deployment/n8n -n n8n }
Start-Job -ScriptBlock { kubectl rollout status deployment/n8n-worker -n n8n }

# 3. Verificar pods
kubectl get pods -n n8n -w
```

**Tempo:** ~2 minutos

---

## 📋 BACKUP ANTES DE APLICAR (Recomendado)

Antes de aplicar SSL, faça backup:

```powershell
# Exportar configuração atual
kubectl get deployment n8n -n n8n -o yaml > exports/n8n-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml
kubectl get deployment n8n-worker -n n8n -o yaml > exports/n8n-worker-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml

# Exportar ConfigMaps e Secrets (estrutura)
kubectl get configmap -n n8n -o yaml > exports/configmaps-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').yaml
```

---

## 🔄 RESTAURAR DO BACKUP

Se tiver backup:

```powershell
# Restaurar deployment n8n
kubectl apply -f exports/n8n-backup-<timestamp>.yaml

# Restaurar deployment n8n-worker
kubectl apply -f exports/n8n-worker-backup-<timestamp>.yaml

# Verificar
kubectl get pods -n n8n
```

---

## 📞 CONTATOS DE EMERGÊNCIA

Se o rollback não resolver:
1. Verificar logs detalhados
2. Verificar eventos do Kubernetes
3. Consultar documentação do n8n
4. Contatar equipe DevOps

---

## ✅ VALIDAÇÃO FINAL APÓS ROLLBACK

Após rollback bem-sucedido, você deve ver:

- ✅ Pods em status `Running`
- ✅ Sem variáveis `DB_POSTGRESDB_SSL_*` nos pods
- ✅ Logs sem erros de SSL/certificado
- ✅ n8n acessível via web
- ✅ Workflows funcionando normalmente
- ✅ Conexão com PostgreSQL funcionando (sem SSL)

---

**Última Atualização:** 28/11/2025  
**Status:** ✅ Plano de Rollback Completo e Testado




