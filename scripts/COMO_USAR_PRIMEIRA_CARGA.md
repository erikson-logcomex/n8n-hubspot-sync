# 🚀 Como Usar - Primeira Carga HubSpot

## 📋 **PRÉ-REQUISITOS:**

1. **✅ Python 3.8+** instalado
2. **✅ Arquivo `.env`** configurado (já está)
3. **✅ Tabela `contacts`** criada no PostgreSQL (já está)
4. **✅ Dependências Python** instaladas

---

## 🔧 **PASSO 1 - Instalar Dependências:**

```powershell
# Na pasta raiz do projeto
pip install requests psycopg2-binary python-dotenv
```

---

## 🚀 **PASSO 2 - Executar Primeira Carga:**

```powershell
# Executar o script
python scripts/primeira_carga_hubspot.py
```

### **🎯 O que o script faz:**
- ✅ Busca **TODOS** os contatos do HubSpot (~400k)
- ✅ **Rate limiting** de 2 segundos entre requests
- ✅ **Retry automático** em caso de erro/rate limit
- ✅ **UPSERT** no PostgreSQL (insert ou update)
- ✅ **Logs detalhados** em `logs/primeira_carga_hubspot_YYYYMMDD_HHMMSS.log`
- ✅ **Progress tracking** em tempo real

### **⏱️ Tempo estimado:**
- **~400k contatos** ÷ **50 contatos/request** = **8.000 requests**
- **8.000 requests** × **2s delay** = **~4,5 horas**
- **Mais processamento e salvamento** = **~5-6 horas total**

---

## 📊 **PASSO 3 - Monitorar Progresso:**

### **Terminal mostrará:**
```
🚀 Iniciando primeira carga HubSpot → PostgreSQL
📄 Página 1 - Buscando até 100 contatos...
✅ Página 1: 100 contatos. Total: 100
📄 Página 2 - Buscando até 100 contatos...
✅ Página 2: 100 contatos. Total: 200
...
💾 Salvos 1000/8000 contatos...
💾 Salvos 2000/8000 contatos...
...
🎉 PRIMEIRA CARGA COMPLETA!
📊 Contatos processados: 394.582
💾 Contatos salvos: 394.582
⏱️ Tempo total: 18.347,23s (305,8 min)
```

### **Log detalhado em:**
`logs/primeira_carga_hubspot_20250826_153045.log`

---

## 🔄 **PASSO 4 - Ativar Sincronização Incremental:**

Depois que a primeira carga completar:

1. **Importar workflow** no n8n: `final/workflows/contacts_sync_incremental_with_delay.json`
2. **Configurar credenciais** (HubSpot + PostgreSQL)  
3. **Ativar** execução automática a cada 2h
4. **Testar** execução manual primeiro

---

## ⚙️ **CONFIGURAÇÕES AVANÇADAS:**

### **🐌 Se rate limit muito conservador:**
Editar `scripts/primeira_carga_hubspot.py`:
```python
DELAY_BETWEEN_REQUESTS = 1.0  # Reduzir para 1 segundo
CONTACTS_PER_REQUEST = 100    # Aumentar para 100
```

### **🚀 Se quiser mais rápido (CUIDADO):**
```python
DELAY_BETWEEN_REQUESTS = 0.5  # Mais agressivo
```

### **🛡️ Se muitos erros de rate limit:**
```python
DELAY_BETWEEN_REQUESTS = 3.0  # Mais conservador
MAX_RETRIES = 5              # Mais tentativas
```

---

## 🚨 **SE ALGO DER ERRADO:**

### **❌ Rate Limit Atingido:**
- Script faz **retry automático**
- Aguarda tempo sugerido pelo HubSpot
- **Não interromper** o script

### **❌ Conexão PostgreSQL:**
- Verificar variáveis no `.env`
- Testar conexão no DBeaver
- Verificar se tabela `contacts` existe

### **❌ Script parou no meio:**
- **Pode rodar novamente** sem problemas
- Script usa **UPSERT** (não duplica dados)
- Vai processar apenas contatos novos/modificados

### **❌ Verificar se completou:**
```sql
-- No DBeaver
SELECT COUNT(*) FROM contacts;
-- Deve ser próximo de 400.000
```

---

## 🎯 **RESULTADO ESPERADO:**

```sql
-- Verificação final no DBeaver
SELECT 
    COUNT(*) as total_contatos,
    COUNT(email) as com_email,
    COUNT(phone) as com_telefone,
    COUNT(company) as com_empresa,
    MIN(createdate) as contato_mais_antigo,
    MAX(lastmodifieddate) as ultima_modificacao,
    MAX(last_sync_date) as ultima_sincronizacao
FROM contacts;

-- Resultado esperado:
-- total_contatos: ~394.000-400.000
-- com_email: ~80% 
-- com_telefone: ~95%
-- com_empresa: ~98%
-- contato_mais_antigo: 2019-xx-xx
-- ultima_modificacao: 2025-08-26
-- ultima_sincronizacao: 2025-08-26
```

---

## 🎉 **DEPOIS DA PRIMEIRA CARGA:**

1. ✅ **Primeira carga completa** (~400k contatos)
2. ✅ **Workflow incremental ativo** (a cada 2h)  
3. ✅ **Rate limiting configurado** (não impacta outras ferramentas)
4. ✅ **Sincronização automática** funcionando
5. ✅ **Dados sempre atualizados** (máx 2h delay)

**🚀 Sistema de espelhamento completo e funcionando!**

