# 🧹 GUIA DE ORGANIZAÇÃO DO PROJETO

**Última atualização:** 01/12/2025  
**Objetivo:** Manter projeto local 100% sincronizado com GCP e organizado

---

## 🎯 **OBJETIVO**

Este guia descreve como manter o projeto local organizado e sincronizado com o ambiente Kubernetes do GCP.

### **Princípios:**
1. ✅ **Sincronização**: Arquivos locais devem refletir estado atual do GCP
2. ✅ **Organização**: Estrutura clara e lógica
3. ✅ **Limpeza**: Remover arquivos temporários e duplicados
4. ✅ **Documentação**: Tudo documentado e atualizado

---

## 🔄 **SINCRONIZAÇÃO COM GCP**

### **Quando Sincronizar:**
- ✅ Antes de fazer mudanças nos YAMLs
- ✅ Após mudanças no GCP (via console ou kubectl)
- ✅ Semanalmente (manutenção preventiva)
- ✅ Antes de commits importantes

### **Como Sincronizar:**

```powershell
# Sincronizar todos os clusters
.\scripts\sync-with-gcp.ps1 -Cluster all

# Sincronizar apenas n8n-cluster
.\scripts\sync-with-gcp.ps1 -Cluster n8n

# Sincronizar apenas metabase-cluster
.\scripts\sync-with-gcp.ps1 -Cluster metabase

# Dry run (ver o que será feito)
.\scripts\sync-with-gcp.ps1 -Cluster all -DryRun
```

### **O que é Sincronizado:**

#### **n8n-cluster:**
- `n8n-optimized-deployment.yaml`
- `n8n-worker-optimized-deployment.yaml`
- `evolution-api-deployment.yaml`
- `evolution-api-secret.yaml`
- `postgres-ssl-cert-configmap.yaml`
- `postgres-secret.yaml`
- `n8n-service.yaml`
- `n8n-ingress.yaml`

#### **metabase-cluster:**
- `metabase-deployment.yaml`
- `postgres-ssl-cert-configmap.yaml`
- `metabase-service.yaml`
- `metabase-ingress.yaml`

---

## 🧹 **ORGANIZAÇÃO E LIMPEZA**

### **Quando Organizar:**
- ✅ Após adicionar muitos arquivos
- ✅ Antes de commits importantes
- ✅ Quando projeto está "bagunçado"
- ✅ Mensalmente (manutenção preventiva)

### **Como Organizar:**

```powershell
# Organizar projeto (com exportação do GCP)
.\scripts\organize-project.ps1

# Organizar sem exportar GCP
.\scripts\organize-project.ps1 -ExportGCP:$false

# Dry run (ver o que será feito)
.\scripts\organize-project.ps1 -DryRun
```

### **O que é Feito:**

1. **Exportação do GCP:**
   - Exporta configurações atuais de todos os clusters
   - Salva em `exports/gcp-current-YYYYMMDD-HHMMSS/`

2. **Limpeza de Arquivos:**
   - Remove arquivos temporários (`temp*.yaml`, `*temp*.yaml`)
   - Remove arquivos duplicados (`*-gcp.yaml`, `*-current.yaml`)
   - Remove backups antigos (mantém apenas 3 mais recentes)
   - Move arquivos da raiz para pastas apropriadas

3. **Organização de Estrutura:**
   - Garante que todas as pastas necessárias existem
   - Move arquivos para locais corretos
   - Arquivar arquivos antigos em `archive/`

---

## 📋 **CONVENÇÕES DE NOMENCLATURA**

### **Arquivos YAML:**

#### **Deployments:**
- `*-deployment.yaml` - Deployment principal
- `*-optimized-deployment.yaml` - Deployment otimizado (produção)

#### **Serviços:**
- `*-service.yaml` - Service do Kubernetes

#### **Ingress:**
- `*-ingress.yaml` - Ingress do Kubernetes

#### **Secrets:**
- `*-secret.yaml` - Secret (⚠️ não commitar dados sensíveis)

#### **ConfigMaps:**
- `*-configmap.yaml` - ConfigMap

### **Documentação:**

- `GUIA_*.md` - Guias de implementação
- `PLANO_*.md` - Planos de ação
- `IMPLEMENTACAO_*.md` - Documentação de implementações
- `ANALISE_*.md` - Análises técnicas
- `STATUS_*.md` - Status atual

### **Scripts:**

- `organize-*.ps1` - Scripts de organização
- `sync-*.ps1` - Scripts de sincronização
- `backup-*.ps1` - Scripts de backup
- `export-*.ps1` - Scripts de exportação

---

## 🗂️ **ESTRUTURA DE PASTAS**

### **Pastas Principais:**

```
n8n/
├── clusters/          # Configurações Kubernetes (sincronizadas)
├── docs/              # Documentação técnica
├── scripts/            # Scripts de automação
├── workflows/          # Workflows do n8n
├── exports/            # Backups e exports do GCP
├── archive/            # Arquivos arquivados
├── config/             # Configurações gerais
└── certs/              # Certificados SSL
```

### **Onde Colocar Arquivos:**

- **YAMLs de Kubernetes**: `clusters/{cluster}/production/`
- **Documentação**: `docs/`
- **Scripts**: `scripts/`
- **Workflows**: `workflows/`
- **Backups**: `exports/`
- **Arquivos antigos**: `archive/`
- **Configurações**: `config/`
- **Certificados**: `certs/`

---

## 🔐 **SEGURANÇA**

### **Arquivos Sensíveis:**

#### **Secrets:**
- ⚠️ **NÃO commitar** secrets com dados reais
- ✅ Usar variáveis de ambiente ou Secret Manager
- ✅ Manter apenas estrutura em YAMLs locais

#### **Certificados:**
- ⚠️ **NÃO commitar** certificados privados
- ✅ Manter em `certs/` (não versionado)
- ✅ Usar ConfigMaps para certificados públicos

### **Backups:**
- ✅ Backups automáticos em `exports/`
- ✅ Retenção: 3 backups mais recentes
- ✅ Arquivos antigos movidos para `archive/`

---

## 📊 **CHECKLIST DE MANUTENÇÃO**

### **Diária:**
- [ ] Verificar se há mudanças no GCP que precisam ser sincronizadas

### **Semanal:**
- [ ] Sincronizar com GCP (`sync-with-gcp.ps1`)
- [ ] Verificar se há arquivos temporários para limpar

### **Mensal:**
- [ ] Organizar projeto (`organize-project.ps1`)
- [ ] Revisar documentação
- [ ] Limpar backups antigos

### **Antes de Commits Importantes:**
- [ ] Sincronizar com GCP
- [ ] Organizar projeto
- [ ] Verificar se tudo está documentado
- [ ] Atualizar README se necessário

---

## 🚨 **TROUBLESHOOTING**

### **Erro ao Sincronizar:**
```powershell
# Verificar contexto do kubectl
kubectl config get-contexts

# Mudar para contexto correto
kubectl config use-context gke_datatoopenai_southamerica-east1-a_n8n-cluster
```

### **Arquivos Duplicados:**
```powershell
# Executar organização
.\scripts\organize-project.ps1

# Verificar o que será feito (dry run)
.\scripts\organize-project.ps1 -DryRun
```

### **Projeto Desorganizado:**
```powershell
# Executar organização completa
.\scripts\organize-project.ps1

# Verificar estrutura
tree /F clusters\
```

---

## 📚 **REFERÊNCIAS**

- [Estrutura do Projeto](ESTRUTURA_PROJETO.md)
- [README Principal](../README.md)
- [Arquitetura Executiva](ARQUITETURA_EXECUTIVA_ECOSSISTEMA.md)

---

**🎯 Objetivo:** Manter projeto sempre organizado e sincronizado com GCP!




