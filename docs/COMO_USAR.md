# 🚀 Como Usar - Sincronização HubSpot → PostgreSQL

## ✅ **ARQUIVOS DESTA PASTA (final/)**

Esta pasta contém **APENAS** os arquivos finais que devem ser usados:

### 📄 **Arquivos Principais**
- `hubspot_contacts_table_PADRAO_CORRETO.sql` - Tabela `contacts` (padrão correto)
- `n8n_workflow_hubspot_sync_PADRAO_CORRETO.json` - Workflow n8n final
- `deploy_hubspot_table.ps1` - Script automatizado de deploy

### 📖 **Documentação**
- `GUIA_IMPLEMENTACAO_PADRAO_CORRETO.md` - Guia completo
- `COMO_USAR.md` - Este arquivo (instruções rápidas)

### 🔧 **Monitoramento**
- `monitoring_table.sql` - Tabela para logs de sincronização

---

## 🎯 **Implementação em 3 Passos**

### **Passo 1: Criar Tabela PostgreSQL**
```powershell
# Na pasta final/
.\deploy_hubspot_table.ps1
```

**Resultado**: Tabela `contacts` criada no banco `hubspot-sync`

### **Passo 2: Importar Workflow n8n**
1. Abrir n8n: `https://n8n-logcomex.34-8-101-220.nip.io`
2. Importar arquivo: `n8n_workflow_hubspot_sync_PADRAO_CORRETO.json`
3. Configurar credenciais:
   - **HubSpot API**: Usar token do `.env`
   - **PostgreSQL**: Banco `hubspot-sync`

### **Passo 3: Ativar Sincronização**
1. Testar workflow manualmente
2. Ativar execução automática (a cada 2 horas)
3. Monitorar logs

---

## 🎉 **Resultado Esperado**

### 📊 **Dados Sincronizados**
- **~312.492 contatos** do HubSpot
- **TODAS as propriedades reais** da Logcomex:
  - ✅ 100% com empresa e lifecycle
  - ✅ 98% com telefone
  - ✅ 92% com website  
  - ✅ 80% com email e voucher
  - ✅ 76% com cargo

### 🗄️ **Estrutura Final**
```sql
-- Tabela seguindo padrão das outras (companies, deals, owners)
SELECT COUNT(*) FROM contacts; -- ~312.492 registros

-- Queries úteis incluídas:
SELECT * FROM v_contacts_stats;           -- Estatísticas gerais
SELECT * FROM v_contacts_by_lifecycle;    -- Por lifecycle
SELECT * FROM v_contacts_by_company;      -- Por empresa
```

---

## 🔍 **Verificação**

### ✅ **Comandos de Teste**
```sql
-- Verificar tabela criada
SELECT COUNT(*) FROM contacts;

-- Verificar dados importantes
SELECT 
  COUNT(*) as total,
  COUNT(email) as com_email,
  COUNT(phone) as com_telefone,
  COUNT(company) as com_empresa
FROM contacts;

-- Últimas sincronizações
SELECT MAX(last_sync_date) FROM contacts;
```

### 📈 **Monitoramento Contínuo**
- **Logs n8n**: Verificar execuções automáticas
- **Views SQL**: Usar views criadas automaticamente
- **Performance**: Índices otimizados incluídos

---

## ⚠️ **IMPORTANTE**

### ✅ **USAR SEMPRE:**
- Tabela: `contacts` (sem "logcomex")
- Banco: `hubspot-sync`
- Workflow: `n8n_workflow_hubspot_sync_PADRAO_CORRETO.json`

### ❌ **NÃO USAR:**
- Arquivos da pasta `archive/`
- Tabelas com nome antigo
- Workflows descontinuados

---

**🎯 Para dúvidas**: Consultar `GUIA_IMPLEMENTACAO_PADRAO_CORRETO.md` (guia completo)
