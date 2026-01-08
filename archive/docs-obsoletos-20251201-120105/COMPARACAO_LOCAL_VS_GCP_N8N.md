# 🔍 COMPARAÇÃO: CONFIGURAÇÃO LOCAL vs GCP - CLUSTER N8N

**Data:** 28/11/2025  
**Status:** Análise Completa  
**Objetivo:** Identificar diferenças entre arquivos YAML locais e configuração real no GCP

---

## 📋 RESUMO EXECUTIVO

Este documento compara a configuração dos arquivos YAML locais com a configuração real implantada no cluster GKE do n8n. Foram identificadas **várias diferenças significativas** que precisam ser sincronizadas.

### ⚠️ PRINCIPAIS DIFERENÇAS ENCONTRADAS:

1. **Versão da Imagem Docker**: Local usa `1.107.3`, GCP usa `1.120.0` (mais recente)
2. **Recursos (CPU/Memória)**: Valores diferentes entre local e GCP
3. **Variáveis de Ambiente**: GCP tem variáveis adicionais não presentes nos arquivos locais
4. **Número de Réplicas**: Local tem `n8n-optimized-deployment.yaml` com 2 réplicas, mas GCP tem apenas 1
5. **Node Selector**: GCP usa `pool-cpu4`, não presente nos arquivos locais
6. **Deployments Adicionais**: GCP tem deployments que não existem localmente (evolution-api, pgbouncer, letta)

---

## 🚀 DEPLOYMENT: N8N PRINCIPAL

### 📁 Arquivo Local: `n8n-optimized-deployment.yaml`
### ☁️ GCP: Deployment `n8n` (namespace: n8n)

| Aspecto | Local | GCP | Status |
|---------|-------|-----|--------|
| **Réplicas** | `2` | `1` | ❌ **DIFERENTE** |
| **Imagem** | `docker.n8n.io/n8nio/n8n:1.107.3` | `docker.n8n.io/n8nio/n8n:1.120.0` | ❌ **DIFERENTE** |
| **CPU Request** | `250m` | `600m` | ❌ **DIFERENTE** |
| **CPU Limit** | `250m` | `800m` | ❌ **DIFERENTE** |
| **Memory Request** | `512Mi` | `1200Mi` | ❌ **DIFERENTE** |
| **Memory Limit** | `512Mi` | `1500Mi` | ❌ **DIFERENTE** |
| **Node Selector** | Não configurado | `cloud.google.com/gke-nodepool: pool-cpu4` | ❌ **DIFERENTE** |

### 🔧 Variáveis de Ambiente - Diferenças:

#### ✅ Presentes no GCP, mas NÃO no Local:
- `NODE_FUNCTION_ALLOW_BUILTIN: '*'`
- `NODE_FUNCTION_ALLOW_EXTERNAL: '*'`
- `N8N_CUSTOM_EXTENSIONS: /home/node/.n8n/custom`
- `DB_POSTGRESDB_POOL_SIZE: "15"` (local tem `"2"`)
- `DB_POSTGRESDB_CONNECTION_TIMEOUT: "30000"` (local tem `"120000"`)
- `DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT: "300000"` (local tem `"60000"`)
- `N8N_METRICS_INCLUDE_DEFAULT_METRICS: "true"`
- `N8N_METRICS_INCLUDE_QUEUE_METRICS: "true"`
- `N8N_METRICS_INCLUDE_WORKFLOW_ID_LABEL: "true"`
- `N8N_METRICS_INCLUDE_WORKFLOW_NAME_LABEL: "true"`
- `N8N_METRICS_INCLUDE_NODE_TYPE_LABEL: "false"`
- `N8N_CACHE_TTL: "3600"`
- `N8N_CACHE_MAX_SIZE: "100"`

#### ❌ Presentes no Local, mas NÃO no GCP:
- Nenhuma variável exclusiva do local

### 📦 Volumes - Diferenças:

**Local:**
- `n8n-claim0` → `/home/node/.n8n`
- `n8n-secret` (volume montado, mas não usado)
- `postgres-secret` (volume montado, mas não usado)

**GCP:**
- `n8n-claim0` → `/home/node/.n8n`
- `postgres-secret` → `/home/node/.n8n/postgres` (readOnly: true)

---

## 👷 DEPLOYMENT: N8N WORKER

### 📁 Arquivo Local: `n8n-worker-optimized-deployment.yaml`
### ☁️ GCP: Deployment `n8n-worker` (namespace: n8n)

| Aspecto | Local | GCP | Status |
|---------|-------|-----|--------|
| **Réplicas** | `3` | `3` | ✅ **IGUAL** |
| **Imagem** | `docker.n8n.io/n8nio/n8n:1.107.3` | `docker.n8n.io/n8nio/n8n:1.120.0` | ❌ **DIFERENTE** |
| **CPU Request** | `800m` | `150m` | ❌ **DIFERENTE** |
| **CPU Limit** | `800m` | `300m` | ❌ **DIFERENTE** |
| **Memory Request** | `3Gi` | `1200Mi` | ❌ **DIFERENTE** |
| **Memory Limit** | `3Gi` | `1600Mi` | ❌ **DIFERENTE** |
| **Node Selector** | Não configurado | `cloud.google.com/gke-nodepool: pool-cpu4` | ❌ **DIFERENTE** |

### 🔧 Variáveis de Ambiente - Diferenças:

#### ✅ Presentes no GCP, mas NÃO no Local:
- `N8N_METRICS_INCLUDE_DEFAULT_METRICS: "true"`
- `N8N_METRICS_INCLUDE_QUEUE_METRICS: "true"`
- `N8N_METRICS_INCLUDE_WORKFLOW_ID_LABEL: "true"`
- `N8N_METRICS_INCLUDE_WORKFLOW_NAME_LABEL: "true"`
- `N8N_METRICS_INCLUDE_NODE_TYPE_LABEL: "false"`
- `REDIS_PASSWORD` (variável explícita)
- `NODE_OPTIONS: --max-old-space-size=3072 --expose-gc`
- `NODE_ENV: production`
- `V8_FORCE_GC: "1"`
- `N8N_EXECUTION_TIMEOUT: "7200"`
- `N8N_EXECUTE_IN_PROCESS: "false"`
- `EXECUTIONS_DATA_PRUNE: "true"`
- `EXECUTIONS_DATA_MAX_AGE: "1"`
- `DB_POSTGRESDB_POOL_SIZE: "3"` (local tem `"2"`)
- `DB_POSTGRESDB_CONNECTION_TIMEOUT: "30000"` (local tem `"120000"`)
- `DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT: "300000"` (local tem `"60000"`)
- `N8N_CONCURRENCY: "3"`
- `N8N_CUSTOM_EXTENSIONS: /home/node/.n8n/custom`

#### ⚠️ Observação Importante:
- **Local**: Workers não têm volume persistente (comentário no código)
- **GCP**: Workers TÊM volume `n8n-claim0` montado em `/home/node/.n8n`

---

## 🌐 INGRESS

### 📁 Arquivo Local: `n8n-ingress.yaml`
### ☁️ GCP: Ingress `n8n-ingress` (namespace: n8n)

| Aspecto | Local | GCP | Status |
|---------|-------|-----|--------|
| **Host** | `n8n-logcomex.34-8-101-220.nip.io` | `n8n-logcomex.34-8-101-220.nip.io` | ✅ **IGUAL** |
| **HTTP Bloqueado** | `kubernetes.io/ingress.allow-http: "false"` | `kubernetes.io/ingress.allow-http: "false"` | ✅ **IGUAL** |
| **Certificado** | `networking.gke.io/managed-certificates: "n8n-ssl-cert"` | `networking.gke.io/managed-certificates: "n8n-ssl-cert"` | ✅ **IGUAL** |
| **IP Estático** | `n8n-ip` | `n8n-ip` | ✅ **IGUAL** |
| **Service** | `n8n` (porta 80) | `n8n` (porta 80) | ✅ **IGUAL** |

### ✅ Status: **CONFIGURAÇÃO IDÊNTICA**

---

## 🔌 SERVICE

### 📁 Arquivo Local: `n8n-service.yaml`
### ☁️ GCP: Service `n8n` (namespace: n8n)

| Aspecto | Local | GCP | Status |
|---------|-------|-----|--------|
| **Tipo** | `NodePort` | `NodePort` | ✅ **IGUAL** |
| **Porta** | `80` → `5678` | `80` → `5678` | ✅ **IGUAL** |
| **NodePort** | Não especificado | `30990` | ⚠️ **AUTO-ATRIBUÍDO** |
| **Annotations Prometheus** | Presente | Presente | ✅ **IGUAL** |
| **Backend Config** | Não presente | `cloud.google.com/backend-config: '{default: n8n-backendconfig}'` | ❌ **DIFERENTE** |

---

## 💾 STORAGE (PVC)

### 📁 Arquivo Local: `storage.yaml` (StorageClass)
### ☁️ GCP: PVCs no namespace n8n

| Recurso | Local | GCP | Status |
|---------|-------|-----|--------|
| **StorageClass** | `regionalpd-storageclass` (pd-standard, regional-pd) | `standard-rwo` | ❌ **DIFERENTE** |
| **PVC n8n-claim0** | Não especificado no local | `2Gi`, `standard-rwo`, `ReadWriteOnce` | ⚠️ **NÃO ENCONTRADO NO LOCAL** |
| **PVC n8n-backup-claim** | Não presente | `10Gi`, `standard-rwo`, `ReadWriteOnce` | ⚠️ **NÃO ENCONTRADO NO LOCAL** |

### 📝 Observações:
- O arquivo `storage.yaml` local define uma StorageClass que **não está sendo usada** no GCP
- O GCP usa `standard-rwo` (standard read-write-once) que é diferente da configuração regional do local

---

## 🆕 RECURSOS NO GCP QUE NÃO EXISTEM LOCALMENTE

### 1. **Evolution API**
- **Deployment**: `evolution-api`
- **Service**: `evolution-api`
- **Ingress**: `evolution-api-ingress`
- **PVC**: `evolution-api-data` (10Gi)
- **ConfigMap**: `evolution-api-config`
- **Secret**: `evolution-api-secrets`

### 2. **PGBouncer**
- **Deployment**: `pgbouncer` (status: Unavailable - com problemas)
- **Service**: `pgbouncer-service`
- **Função**: Connection pooler para PostgreSQL

### 3. **Letta**
- **Deployment**: Não visível nos deployments listados
- **Service**: `letta` (porta 80 → 8723)
- **Ingress**: `letta-ingress` (HTTP permitido - diferente do n8n)
- **Função**: Monitoramento de métricas

### 4. **Redis**
- **Service**: `redis-master`, `redis-headless`
- **PVC**: `redis-data-redis-master-0` (8Gi)
- **ConfigMaps**: `redis-configuration`, `redis-health`, `redis-scripts`
- **Gerenciado via Helm** (não presente nos YAMLs locais)

---

## 📊 ARQUIVOS LOCAIS QUE NÃO ESTÃO NO GCP

### 1. `n8n-deployment.yaml`
- Versão antiga do deployment (1 réplica, imagem 1.107.3)
- **Status**: Provavelmente substituído pelo deployment atual

### 2. `n8n-worker-deployment.yaml`
- Versão antiga do worker (recursos menores)
- **Status**: Provavelmente substituído pelo deployment atual

### 3. `n8n-worker-security-fix.yaml`
- Arquivo de correção de segurança
- **Status**: Mudanças provavelmente já aplicadas no GCP

### 4. `backup-cronjob.yaml`
- CronJob para backup
- **Status**: Não verificado se existe no GCP

### 5. `backup-pvc.yaml`
- PVC para backups
- **Status**: Existe no GCP como `n8n-backup-claim`

### 6. `n8n-ssl-certificate.yaml`
- ManagedCertificate
- **Status**: Provavelmente existe no GCP (referenciado no Ingress)

---

## 🔍 ANÁLISE DETALHADA DE DIFERENÇAS CRÍTICAS

### 🚨 **CRÍTICO - Versão da Imagem**
- **Local**: `1.107.3` (outubro 2024)
- **GCP**: `1.120.0` (novembro 2025)
- **Impacto**: Versão no GCP é **13 versões à frente** do local
- **Ação**: Atualizar arquivos locais para refletir a versão atual

### 🚨 **CRÍTICO - Recursos de CPU/Memória**
- **Local**: Recursos muito menores (250m CPU, 512Mi RAM)
- **GCP**: Recursos maiores (600m-800m CPU, 1200Mi-1500Mi RAM)
- **Impacto**: Configuração local não reflete a capacidade real
- **Ação**: Sincronizar recursos locais com GCP

### ⚠️ **IMPORTANTE - Variáveis de Ambiente**
- **GCP**: Tem muitas variáveis de otimização e métricas não presentes no local
- **Impacto**: Configurações de performance e monitoramento não documentadas localmente
- **Ação**: Adicionar todas as variáveis do GCP aos arquivos locais

### ⚠️ **IMPORTANTE - Node Selector**
- **GCP**: Usa `pool-cpu4` para garantir execução em nodepool específico
- **Local**: Não tem node selector configurado
- **Impacto**: Deployments locais podem não funcionar corretamente se aplicados
- **Ação**: Adicionar node selector aos arquivos locais

### ⚠️ **IMPORTANTE - StorageClass**
- **Local**: Define `regionalpd-storageclass` (não usado)
- **GCP**: Usa `standard-rwo` (padrão do GKE)
- **Impacto**: PVCs locais podem falhar ao criar volumes
- **Ação**: Atualizar storage.yaml ou criar PVCs com storageClassName correto

---

## 📋 RECOMENDAÇÕES

### 🔴 **URGENTE - Sincronizar Arquivos Locais**

1. **Atualizar versão da imagem**:
   - Mudar de `1.107.3` para `1.120.0` em todos os deployments

2. **Sincronizar recursos**:
   - Atualizar CPU/Memória para valores do GCP
   - Adicionar node selector `pool-cpu4`

3. **Adicionar variáveis de ambiente faltantes**:
   - Todas as variáveis de métricas
   - Variáveis de otimização (NODE_OPTIONS, V8_FORCE_GC, etc.)
   - Variáveis de cache (N8N_CACHE_TTL, N8N_CACHE_MAX_SIZE)

4. **Corrigir configurações de banco**:
   - Atualizar pool size, timeouts para valores do GCP

### 🟡 **IMPORTANTE - Documentar Recursos Adicionais**

1. **Criar YAMLs para recursos não documentados**:
   - Evolution API (deployment, service, ingress, configmap, secret)
   - PGBouncer (deployment, service)
   - Letta (service, ingress)
   - Redis (se necessário documentar)

2. **Atualizar storage.yaml**:
   - Remover ou atualizar StorageClass regional
   - Documentar uso de `standard-rwo`

### 🟢 **RECOMENDADO - Melhorias**

1. **Criar script de sincronização**:
   - Exportar configuração atual do GCP
   - Comparar com arquivos locais
   - Gerar relatório de diferenças

2. **Versionamento**:
   - Adicionar tags/versões aos arquivos YAML
   - Documentar quando cada mudança foi aplicada

3. **Validação**:
   - Criar testes para validar YAMLs antes de aplicar
   - Verificar compatibilidade com cluster GKE

---

## 📝 PRÓXIMOS PASSOS

1. ✅ **Análise Completa** (Este documento)
2. ⏳ **Exportar configuração atual do GCP** para backup
3. ⏳ **Atualizar arquivos locais** com configuração do GCP
4. ⏳ **Criar YAMLs para recursos faltantes** (Evolution API, PGBouncer, Letta)
5. ⏳ **Validar YAMLs atualizados** antes de aplicar
6. ⏳ **Documentar processo de sincronização** para futuro

---

## 🔗 REFERÊNCIAS

- **Arquivos Locais**: `clusters/n8n-cluster/production/`
- **Cluster GCP**: Namespace `n8n`
- **Documentação**: `docs/ARQUITETURA_EXECUTIVA_ECOSSISTEMA.md`

---

**Última Atualização:** 28/11/2025  
**Próxima Revisão:** Após sincronização dos arquivos

