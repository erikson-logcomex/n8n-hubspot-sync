# 🔒 GUIA DE IMPLEMENTAÇÃO: SSL/TLS para PostgreSQL no n8n

**Data:** 28/11/2025  
**Objetivo:** Habilitar conexões SSL/TLS seguras entre n8n e PostgreSQL (Cloud SQL)

---

## 📋 RESUMO

Este guia documenta a implementação de SSL/TLS nas conexões do n8n com o PostgreSQL. O certificado SSL do Google Cloud SQL será montado nos pods do n8n através de um ConfigMap.

---

## 🎯 O QUE FOI IMPLEMENTADO

### 1. **ConfigMap com Certificado SSL**
- **Arquivo:** `clusters/n8n-cluster/production/postgres-ssl-cert-configmap.yaml`
- **Conteúdo:** Certificado CA do Google Cloud SQL (`server-ca.pem`)
- **Namespace:** `n8n`

### 2. **Atualização dos Deployments**

#### **n8n (Principal)**
- **Arquivo:** `clusters/n8n-cluster/production/n8n-optimized-deployment.yaml`
- **Mudanças:**
  - Adicionadas variáveis de ambiente SSL
  - Volume mount do certificado em `/etc/postgresql/certs`
  - ConfigMap `postgres-ssl-cert` adicionado aos volumes

#### **n8n-worker**
- **Arquivo:** `clusters/n8n-cluster/production/n8n-worker-optimized-deployment.yaml`
- **Mudanças:**
  - Adicionadas variáveis de ambiente SSL
  - Volume mount do certificado em `/etc/postgresql/certs`
  - ConfigMap `postgres-ssl-cert` adicionado aos volumes

---

## 🔧 VARIÁVEIS DE AMBIENTE ADICIONADAS

As seguintes variáveis de ambiente foram adicionadas aos deployments:

```yaml
- name: DB_POSTGRESDB_SSL_ENABLED
  value: "true"
- name: DB_POSTGRESDB_SSL_CA_FILE
  value: /etc/postgresql/certs/server-ca.pem
- name: DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED
  value: "true"
```

### Descrição das Variáveis:

- **`DB_POSTGRESDB_SSL_ENABLED`**: Habilita SSL nas conexões PostgreSQL
- **`DB_POSTGRESDB_SSL_CA_FILE`**: Caminho para o arquivo do certificado CA
- **`DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED`**: Rejeita conexões com certificados não autorizados (segurança)

---

## 📦 ESTRUTURA DE VOLUMES

### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-ssl-cert
  namespace: n8n
data:
  server-ca.pem: |-
    [conteúdo do certificado]
```

### Volume Mount
```yaml
volumeMounts:
- name: postgres-ssl-cert
  mountPath: /etc/postgresql/certs
  readOnly: true
```

### Volume Definition
```yaml
volumes:
- name: postgres-ssl-cert
  configMap:
    name: postgres-ssl-cert
    defaultMode: 420
```

---

## 🚀 COMO APLICAR

### Passo 1: Criar o ConfigMap
```powershell
kubectl apply -f clusters/n8n-cluster/production/postgres-ssl-cert-configmap.yaml
```

### Passo 2: Verificar o ConfigMap
```powershell
kubectl get configmap postgres-ssl-cert -n n8n
kubectl describe configmap postgres-ssl-cert -n n8n
```

### Passo 3: Aplicar Deployments Atualizados

#### Opção A: Aplicar arquivos atualizados
```powershell
# Deployment principal
kubectl apply -f clusters/n8n-cluster/production/n8n-optimized-deployment.yaml

# Deployment worker
kubectl apply -f clusters/n8n-cluster/production/n8n-worker-optimized-deployment.yaml
```

#### Opção B: Aplicar apenas as mudanças (patch)
```powershell
# Aplicar ConfigMap primeiro
kubectl apply -f clusters/n8n-cluster/production/postgres-ssl-cert-configmap.yaml

# Fazer rolling update dos deployments
kubectl rollout restart deployment/n8n -n n8n
kubectl rollout restart deployment/n8n-worker -n n8n
```

### Passo 4: Verificar o Status
```powershell
# Verificar pods
kubectl get pods -n n8n

# Verificar logs para confirmar SSL
kubectl logs -n n8n deployment/n8n | Select-String -Pattern "SSL\|postgres\|database"
kubectl logs -n n8n deployment/n8n-worker | Select-String -Pattern "SSL\|postgres\|database"

# Verificar se o certificado está montado
kubectl exec -n n8n deployment/n8n -- ls -la /etc/postgresql/certs/
kubectl exec -n n8n deployment/n8n -- cat /etc/postgresql/certs/server-ca.pem
```

---

## ✅ VALIDAÇÃO

### 1. Verificar ConfigMap
```powershell
kubectl get configmap postgres-ssl-cert -n n8n -o yaml
```

### 2. Verificar Volume Mount nos Pods
```powershell
kubectl describe pod <pod-name> -n n8n | Select-String -Pattern "postgres-ssl-cert"
```

### 3. Verificar Variáveis de Ambiente
```powershell
kubectl exec -n n8n deployment/n8n -- env | Select-String -Pattern "DB_POSTGRESDB_SSL"
```

### 4. Testar Conexão SSL
```powershell
# Verificar logs do n8n para mensagens de conexão SSL
kubectl logs -n n8n deployment/n8n --tail=50 | Select-String -Pattern "SSL\|TLS\|certificate"
```

### 5. Verificar no Banco de Dados
Se tiver acesso ao Cloud SQL, verificar logs de conexão para confirmar que as conexões estão usando SSL.

---

## 🔍 TROUBLESHOOTING

### Problema: Pod não inicia após aplicar mudanças

**Solução:**
1. Verificar se o ConfigMap existe:
   ```powershell
   kubectl get configmap postgres-ssl-cert -n n8n
   ```

2. Verificar logs do pod:
   ```powershell
   kubectl logs -n n8n <pod-name> --previous
   ```

3. Verificar eventos:
   ```powershell
   kubectl get events -n n8n --sort-by='.lastTimestamp'
   ```

### Problema: Erro de certificado não encontrado

**Solução:**
1. Verificar se o volume está montado:
   ```powershell
   kubectl exec -n n8n <pod-name> -- ls -la /etc/postgresql/certs/
   ```

2. Verificar permissões do certificado:
   ```powershell
   kubectl exec -n n8n <pod-name> -- cat /etc/postgresql/certs/server-ca.pem
   ```

### Problema: Conexão SSL falha

**Solução:**
1. Verificar se as variáveis de ambiente estão corretas:
   ```powershell
   kubectl exec -n n8n <pod-name> -- env | Select-String -Pattern "DB_POSTGRESDB"
   ```

2. Verificar se o certificado está válido:
   ```powershell
   kubectl exec -n n8n <pod-name> -- openssl x509 -in /etc/postgresql/certs/server-ca.pem -text -noout
   ```

3. Verificar logs detalhados do n8n:
   ```powershell
   kubectl logs -n n8n <pod-name> --tail=100
   ```

### Problema: Certificado expirado

**Solução:**
1. Baixar novo certificado do Google Cloud SQL
2. Atualizar o ConfigMap:
   ```powershell
   kubectl create configmap postgres-ssl-cert --from-file=server-ca.pem=certs/server-ca.pem -n n8n --dry-run=client -o yaml | kubectl apply -f -
   ```

3. Reiniciar os pods:
   ```powershell
   kubectl rollout restart deployment/n8n -n n8n
   kubectl rollout restart deployment/n8n-worker -n n8n
   ```

---

## 📝 NOTAS IMPORTANTES

### Segurança
- ✅ O certificado é montado como **read-only** para segurança
- ✅ `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=true` garante validação rigorosa
- ✅ O certificado está em um ConfigMap (não em Secret) pois é público (CA)

### Performance
- ⚠️ SSL adiciona uma pequena sobrecarga nas conexões
- ✅ A sobrecarga é mínima e compensada pela segurança

### Manutenção
- 🔄 O certificado do Google Cloud SQL tem validade de 10 anos
- 📅 Verificar expiração periodicamente
- 🔄 Atualizar ConfigMap quando necessário

---

## 🔗 REFERÊNCIAS

- **Documentação n8n:** [Database Configuration](https://docs.n8n.io/hosting/configuration/database/)
- **Google Cloud SQL SSL:** [Connecting with SSL](https://cloud.google.com/sql/docs/postgres/connect-ssl)
- **Certificado:** `certs/server-ca.pem`

---

## 📊 CHECKLIST DE IMPLEMENTAÇÃO

- [ ] ConfigMap criado com certificado
- [ ] Deployment n8n atualizado
- [ ] Deployment n8n-worker atualizado
- [ ] ConfigMap aplicado no cluster
- [ ] Deployments aplicados no cluster
- [ ] Pods reiniciados e rodando
- [ ] Certificado montado corretamente
- [ ] Variáveis de ambiente configuradas
- [ ] Conexão SSL validada
- [ ] Logs verificados sem erros
- [ ] Testes funcionais realizados

---

**Última Atualização:** 28/11/2025  
**Status:** ✅ Implementado e Pronto para Aplicação

