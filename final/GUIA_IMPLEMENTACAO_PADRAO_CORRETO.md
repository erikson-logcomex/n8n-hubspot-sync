# 🎯 Guia de Implementação - Sincronização HubSpot → PostgreSQL (Padrão Correto)

## ✅ **PADRÃO CORRETO SEGUIDO**

Seguindo o padrão das outras tabelas existentes no banco `hubspot-sync`:
- ✅ `companies` (16K registros)
- ✅ `deals` (14M registros)  
- ✅ `owners` (400K registros)
- ✅ `deal_stages_pipelines` (96K registros)
- ✅ **`contacts`** ← Nossa nova tabela!

---

## 📊 **Dados REAIS Confirmados (análise de 50 contatos):**
- **`company`**: 100% preenchido! 🏢
- **`phone`**: 98% preenchido! ☎️ 
- **`website`**: 92% preenchido! 🌐
- **`codigo_do_voucher`**: 80% preenchido! 🎫
- **`email`**: 80% preenchido! 📧
- **`jobtitle`**: 76% preenchido! 💼
- **`lifecyclestage`**: 100% preenchido! 📊
- **`mobilephone`**: 38% preenchido! 📱

---

## 📁 **Arquivos Finais (Padrão Correto)**

### 🗄️ **Estrutura de Banco de Dados**
- **`hubspot_contacts_table_PADRAO_CORRETO.sql`** - Tabela `contacts` seguindo padrão

### 🔄 **Workflows n8n**  
- **`n8n_workflow_hubspot_sync_PADRAO_CORRETO.json`** - Workflow para tabela `contacts`

### ⚙️ **Scripts de Deploy**
- **`deploy_hubspot_table.ps1`** - Script automatizado atualizado
- **`test_hubspot_sync_db.py`** - Teste de conexão atualizado

---

## 🚀 **Implementação**

### 1. **Testar Conexão com Banco Correto**
```powershell
python test_hubspot_sync_db.py
```

### 2. **Criar Tabela `contacts`**
```powershell
# Opção 1: Script automatizado (RECOMENDADO)
.\deploy_hubspot_table.ps1

# Opção 2: Manual  
psql -h 35.239.64.56 -p 5432 -d hubspot-sync -U meetrox_user -f hubspot_contacts_table_PADRAO_CORRETO.sql
```

### 3. **Importar Workflow n8n**
- Importe: `n8n_workflow_hubspot_sync_PADRAO_CORRETO.json`
- Configure credenciais HubSpot e PostgreSQL (banco `hubspot-sync`)
- Ative o workflow para execução automática a cada 2 horas

---

## 📊 **Estrutura da Tabela `contacts`**

### ✅ **Campos Principais**
```sql
-- Seguindo padrão: companies, deals, owners, contacts
CREATE TABLE contacts (
    id BIGINT PRIMARY KEY,
    hs_object_id INTEGER NOT NULL,
    
    -- Básicos (CONFIRMADOS)
    email VARCHAR(255),              -- 80%
    firstname VARCHAR(100) NOT NULL, -- 100%
    lastname VARCHAR(100),           -- 42%
    company VARCHAR(255) NOT NULL,   -- 100%
    jobtitle VARCHAR(255),           -- 76%
    website VARCHAR(255),            -- 92%
    
    -- Telefones (CONFIRMADOS)
    phone VARCHAR(50),               -- 98%
    mobilephone VARCHAR(50),         -- 38%
    hs_whatsapp_phone_number VARCHAR(50),
    govcs_i_phone_number VARCHAR(50),
    
    -- Status
    lifecyclestage VARCHAR(50) NOT NULL, -- 100%
    hs_lead_status VARCHAR(50),
    
    -- Específicos Logcomex  
    codigo_do_voucher VARCHAR(100),  -- 80%
    -- ... outros campos
);
```

---

## 📊 **Monitoramento**

### ✅ **Views Criadas Automaticamente**
```sql
-- Estatísticas gerais
SELECT * FROM v_contacts_stats;

-- Contatos por lifecycle
SELECT * FROM v_contacts_by_lifecycle;

-- Top empresas
SELECT * FROM v_contacts_by_company;
```

### ✅ **Queries Úteis**
```sql
-- Total de contatos
SELECT COUNT(*) FROM contacts;

-- Contatos com telefone
SELECT COUNT(*) FROM contacts WHERE phone IS NOT NULL;

-- Contatos por empresa (top 10)
SELECT company, COUNT(*) as total 
FROM contacts 
WHERE company IS NOT NULL 
GROUP BY company 
ORDER BY total DESC 
LIMIT 10;

-- Últimas sincronizações
SELECT MAX(last_sync_date) as ultima_sync,
       COUNT(CASE WHEN last_sync_date > NOW() - INTERVAL '24 hours' THEN 1 END) as sync_24h
FROM contacts;
```

---

## 🔄 **Sincronização Esperada**

### 📊 **Primeira Execução**
- **Total esperado**: ~312.492 contatos
- **Tempo estimado**: 2-4 horas
- **Dados por contato**:
  - 100% com empresa e lifecycle
  - 98% com telefone
  - 92% com website
  - 80% com email e voucher

### ⚡ **Execução Incremental (a cada 2h)**
- **Apenas contatos novos/modificados**
- **Tempo**: 2-10 minutos
- **Backup completo** em campo `hubspot_raw_data`

---

## 🎯 **Vantagens do Padrão Correto**

### ✅ **Consistência**
- Segue padrão das outras tabelas HubSpot
- Facilita queries entre `contacts`, `companies`, `deals`, `owners`
- Nomenclatura limpa e simples

### ✅ **Performance**
- Índices otimizados para campos realmente usados
- Views pré-criadas para análises comuns
- Triggers automáticos para timestamps

### ✅ **Integração**
- **Relacionamentos naturais**:
  ```sql
  -- Contatos e suas empresas
  SELECT c.firstname, c.lastname, c.email, comp.name
  FROM contacts c
  LEFT JOIN companies comp ON c.company = comp.name;
  
  -- Contatos por owner
  SELECT c.firstname, c.email, o.email as owner_email
  FROM contacts c  
  LEFT JOIN owners o ON c.hubspot_owner_id = o.id;
  ```

---

## 💡 **Próximos Passos**

1. **✅ Executar**: `.\deploy_hubspot_table.ps1`
2. **✅ Importar**: `n8n_workflow_hubspot_sync_PADRAO_CORRETO.json`
3. **✅ Configurar** credenciais no n8n
4. **✅ Executar** primeira sincronização
5. **✅ Monitorar** via views e queries

---

## 📞 **Comandos de Verificação**

### 🔍 **Status da Tabela**
```sql
-- Verificar se tabela existe e está populada
SELECT 
    'contacts' as tabela,
    COUNT(*) as total_registros,
    MAX(last_sync_date) as ultima_sync
FROM contacts;
```

### 📊 **Comparar com Outras Tabelas HubSpot**
```sql
-- Comparação de registros
SELECT 'companies' as tabela, COUNT(*) as registros FROM companies
UNION ALL
SELECT 'deals' as tabela, COUNT(*) as registros FROM deals  
UNION ALL
SELECT 'owners' as tabela, COUNT(*) as registros FROM owners
UNION ALL
SELECT 'contacts' as tabela, COUNT(*) as registros FROM contacts
ORDER BY registros DESC;
```

---

**🎉 Resultado Final**: Tabela `contacts` seguindo o padrão correto das outras tabelas do HubSpot, com **todas as propriedades reais** da Logcomex sincronizadas automaticamente!
