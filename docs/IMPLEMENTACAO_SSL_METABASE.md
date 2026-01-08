# 🔒 IMPLEMENTAÇÃO SSL: Metabase

**Data:** 01/12/2025  
**Objetivo:** Habilitar conexões SSL/TLS entre Metabase e PostgreSQL (Cloud SQL) - conexão principal e dashboards

---

## 📋 RESUMO

Implementação de SSL/TLS para o Metabase, incluindo:
1. **Conexão Principal**: Banco de dados do Metabase (configurado via variáveis de ambiente)
2. **Conexões de Dashboards**: Conexões PostgreSQL criadas na interface do Metabase

---

## ✅ O QUE FOI PREPARADO

### **1. ConfigMap SSL**

**Arquivo:** `clusters/metabase-cluster/production/postgres-ssl-cert-configmap.yaml`

- Contém o certificado CA do Google Cloud SQL (`server-ca.pem`)
- Namespace: `metabase`
- Será montado em `/etc/postgresql/certs/server-ca.pem`

### **2. Deployment Atualizado**

**Arquivo:** `clusters/metabase-cluster/production/metabase-deployment.yaml`

#### **Mudanças Aplicadas:**

1. **Variáveis de Ambiente SSL:**
   ```yaml
   - name: MB_DB_SSL
     value: "true"
   - name: MB_DB_SSL_MODE
     value: "require"
   - name: MB_DB_SSL_ROOT_CERT
     value: /etc/postgresql/certs/server-ca.pem
   ```

2. **Volume Mount do Certificado:**
   ```yaml
   volumeMounts:
   - name: postgres-ssl-cert
     mountPath: /etc/postgresql/certs
     readOnly: true
   ```

3. **Volume do ConfigMap:**
   ```yaml
   volumes:
   - name: postgres-ssl-cert
     configMap:
       name: postgres-ssl-cert
       defaultMode: 420
   ```

---

## 🚀 APLICAÇÃO (Quando o acesso ao cluster estiver disponível)

### **Passo 1: Criar ConfigMap do Certificado**

```powershell
# Aplicar ConfigMap
kubectl apply -f clusters/metabase-cluster/production/postgres-ssl-cert-configmap.yaml

# Verificar
kubectl get configmap postgres-ssl-cert -n metabase
```

### **Passo 2: Aplicar Deployment Atualizado**

```powershell
# Aplicar deployment com SSL
kubectl apply -f clusters/metabase-cluster/production/metabase-deployment.yaml

# Verificar rollout
kubectl rollout status deployment/metabase-app -n metabase

# Verificar pod
kubectl get pods -n metabase
```

### **Passo 3: Verificar SSL na Conexão Principal**

```powershell
# Verificar variáveis de ambiente
kubectl exec -n metabase deployment/metabase-app -- env | Select-String -Pattern "MB_DB_SSL"

# Verificar certificado montado
kubectl exec -n metabase deployment/metabase-app -- ls -la /etc/postgresql/certs/

# Verificar logs
kubectl logs -n metabase deployment/metabase-app --tail=50 | Select-String -Pattern "database|Database|SSL|error"
```

---

## 🔧 CONFIGURAÇÃO SSL NAS CONEXÕES DE DASHBOARDS

Após aplicar o deployment, você precisa configurar SSL nas conexões PostgreSQL criadas na interface do Metabase.

### **Passo 1: Acessar Configurações do Banco de Dados**

1. No Metabase, vá para: **Administração** → **Bancos de Dados**
2. Clique no banco de dados PostgreSQL que você quer configurar
3. Ou clique em **Adicionar um banco de dados** para criar uma nova conexão

### **Passo 2: Configurar SSL**

Na tela de configuração do banco de dados:

1. **Preencha os campos básicos:**
   - **Nome de exibição**: (ex: "Comercial DB")
   - **Host**: `172.23.64.3`
   - **Porta**: `5432`
   - **Nome do banco de dados**: (ex: `comercial-db`)
   - **Usuário**: (seu usuário)
   - **Senha**: (sua senha)

2. **Configure SSL:**
   - ✅ **Marque**: "Usar uma conexão segura (SSL)"
   - **Modo SSL**: Selecione `require` ou `verify-full`
     - `require`: Força SSL, não valida hostname (recomendado para IP privado)
     - `verify-full`: Força SSL e valida certificado + hostname
   - **Certificado raiz SSL (PEM)**: Deixe **VAZIO** ou use:
     ```
     /etc/postgresql/certs/server-ca.pem
     ```
     > **Nota**: O certificado já está montado no pod, mas o Metabase pode não conseguir acessá-lo diretamente. Se deixar vazio, o Metabase usará o certificado do sistema.

3. **Testar Conexão:**
   - Clique em **"Testar conexão"**
   - Deve funcionar! ✅

4. **Salvar:**
   - Clique em **"Salvar"**

### **Passo 3: Repetir para Outros Bancos**

Repita o processo para cada conexão PostgreSQL que você tem nos dashboards do Metabase.

---

## 🔍 COMO FUNCIONA

### **Conexão Principal (Banco do Metabase):**

```
Metabase Pod
  │
  ├─ Lê variáveis de ambiente:
  │   - MB_DB_SSL=true
  │   - MB_DB_SSL_MODE=require
  │   - MB_DB_SSL_ROOT_CERT=/etc/postgresql/certs/server-ca.pem
  │
  ├─ Conecta ao PostgreSQL via SSL
  │   └─ Usa certificado em /etc/postgresql/certs/server-ca.pem
  │
  └─ ✅ Conexão SSL estabelecida
```

### **Conexões de Dashboards:**

```
Metabase Interface → Configura conexão PostgreSQL
  │
  ├─ Usuário habilita SSL na interface
  │
  ├─ Metabase usa certificado do sistema (se disponível)
  │   └─ Ou certificado especificado no campo "Certificado raiz SSL"
  │
  ├─ Conecta ao PostgreSQL via SSL
  │
  └─ ✅ Conexão SSL estabelecida
```

---

## 📝 VARIÁVEIS DE AMBIENTE SSL DO METABASE

O Metabase suporta as seguintes variáveis de ambiente para SSL:

| Variável | Valor | Descrição |
|----------|-------|-----------|
| `MB_DB_SSL` | `true` | Habilita SSL na conexão principal |
| `MB_DB_SSL_MODE` | `require` | Modo SSL (require, verify-ca, verify-full) |
| `MB_DB_SSL_ROOT_CERT` | `/etc/postgresql/certs/server-ca.pem` | Caminho para certificado CA |

### **Modos SSL Disponíveis:**

- **`require`**: ✅ **Usado** - Força SSL, não valida hostname (OK para IP privado)
- **`verify-ca`**: Força SSL e valida certificado CA
- **`verify-full`**: Força SSL, valida CA e hostname (pode falhar com IP)

---

## ✅ VALIDAÇÃO

### **1. Verificar Conexão Principal**

```powershell
# Verificar variáveis
kubectl exec -n metabase deployment/metabase-app -- env | Select-String -Pattern "MB_DB_SSL"

# Verificar logs (não deve ter erros de SSL)
kubectl logs -n metabase deployment/metabase-app --tail=100 | Select-String -Pattern "SSL|ssl|error|Error|database"
```

### **2. Verificar Conexões de Dashboards**

1. Acesse o Metabase: `https://metabase.34.13.117.77.nip.io`
2. Vá para: **Administração** → **Bancos de Dados**
3. Para cada banco PostgreSQL:
   - Clique no banco
   - Verifique se "Usar uma conexão segura (SSL)" está marcado
   - Teste a conexão
   - Verifique se os dashboards funcionam

### **3. Testar Dashboards**

- Acesse alguns dashboards que usam PostgreSQL
- Verifique se os dados carregam corretamente
- Verifique se não há erros de conexão

---

## 🔄 ROLLBACK

Se houver problemas, consulte: `docs/PLANO_ROLLBACK_SSL_METABASE.md`

**Rollback Rápido:**
```powershell
kubectl rollout undo deployment/metabase-app -n metabase
```

---

## 📊 STATUS DA IMPLEMENTAÇÃO

### **✅ Preparado:**

- [x] ConfigMap do certificado criado
- [x] Deployment atualizado com SSL
- [x] Plano de rollback criado
- [x] Documentação criada

### **⏳ Pendente (Aguardando acesso ao cluster):**

- [ ] Aplicar ConfigMap
- [ ] Aplicar Deployment
- [ ] Verificar conexão principal
- [ ] Configurar SSL nas conexões de dashboards
- [ ] Testar dashboards

---

## 🎯 PRÓXIMOS PASSOS

1. **Quando o acesso ao cluster estiver disponível:**
   - Aplicar ConfigMap e Deployment
   - Verificar conexão principal

2. **No Metabase (Interface):**
   - Configurar SSL em cada conexão PostgreSQL
   - Testar conexões
   - Verificar dashboards

3. **Monitoramento:**
   - Monitorar logs por 24-48 horas
   - Verificar se não há erros
   - Confirmar que tudo funciona normalmente

---

## 📄 ARQUIVOS CRIADOS

- `clusters/metabase-cluster/production/postgres-ssl-cert-configmap.yaml`
- `clusters/metabase-cluster/production/metabase-deployment.yaml` (atualizado)
- `docs/IMPLEMENTACAO_SSL_METABASE.md` (este arquivo)
- `docs/PLANO_ROLLBACK_SSL_METABASE.md`

---

**Última Atualização:** 01/12/2025  
**Status:** ✅ Preparado - Aguardando Aplicação




