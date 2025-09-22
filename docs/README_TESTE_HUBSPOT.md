# 🧪 Scripts de Teste - HubSpot Properties Analysis

## 📋 Visão Geral
Scripts para analisar as propriedades dos contatos no HubSpot da Logcomex e gerar estrutura de tabela PostgreSQL otimizada.

## 🎯 Objetivo
Descobrir quais propriedades (campos) existem nos contatos do HubSpot da Logcomex para criar uma tabela PostgreSQL que contenha exatamente os campos que vocês usam.

---

## 📁 Arquivos Criados

### 🐍 Scripts Python
- **`quick_test_hubspot.py`** - Teste rápido de conexão (2 minutos)
- **`test_hubspot_properties.py`** - Análise completa (5-10 minutos)

### ⚙️ Configuração
- **`requirements.txt`** - Dependências Python
- **`run_hubspot_analysis.ps1`** - Script automatizado para Windows

### 📄 Saída (Gerados automaticamente)
- **`hubspot_analysis_report_YYYYMMDD_HHMMSS.json`** - Relatório completo
- **`hubspot_contacts_table_logcomex_YYYYMMDD_HHMMSS.sql`** - Estrutura da tabela

---

## 🚀 Como Executar

### ✅ Opção 1: Script Automatizado (Recomendado)
```powershell
# Executar no PowerShell (como Administrador)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\run_hubspot_analysis.ps1
```

### ✅ Opção 2: Teste Rápido (2 minutos)
```powershell
# Instalar dependências
pip install -r requirements.txt

# Executar teste rápido
python quick_test_hubspot.py
```

### ✅ Opção 3: Análise Completa (Manual)
```powershell
# Instalar dependências
pip install -r requirements.txt

# Executar análise completa
python test_hubspot_properties.py
```

---

## 📊 O que cada script faz

### 🔍 `quick_test_hubspot.py`
- ✅ Testa conexão com HubSpot
- ✅ Busca 3 contatos de exemplo
- ✅ Lista propriedades do primeiro contato
- ✅ Mostra propriedades comuns que vocês têm/não têm
- ⏱️ **Tempo**: 1-2 minutos

### 🔬 `test_hubspot_properties.py`
- ✅ Testa conexão HubSpot + PostgreSQL
- ✅ Busca TODAS as propriedades disponíveis
- ✅ Analisa 10 contatos de exemplo
- ✅ Determina tipos de dados PostgreSQL ideais
- ✅ Gera estrutura de tabela SQL customizada
- ✅ Cria relatório JSON completo
- ⏱️ **Tempo**: 5-10 minutos

---

## 📋 Pré-requisitos

### ✅ Software
- Python 3.7+ instalado
- PowerShell (já disponível no Windows)

### ✅ Credenciais (já configuradas no .env)
- `HUBSPOT_PRIVATE_APP_TOKEN` ✅
- Credenciais PostgreSQL ✅

### ✅ Permissões HubSpot
- Token deve ter permissão `contacts.read`

---

## 📄 Resultados Esperados

### 📊 Relatório JSON
```json
{
  "timestamp": "2025-01-27T12:00:00",
  "hubspot_properties_count": 150,
  "properties_with_data_count": 45,
  "contacts_analyzed": 10,
  "properties_analysis": {...},
  "type_suggestions": {...}
}
```

### 🗄️ SQL Gerado
```sql
CREATE TABLE IF NOT EXISTS hubspot_contacts_logcomex (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255),
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    -- ... todas as propriedades encontradas
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    hubspot_raw_data JSONB
);
```

---

## 🔍 Troubleshooting

### ❌ Erro: "ModuleNotFoundError"
```powershell
# Instalar dependências
pip install -r requirements.txt
```

### ❌ Erro: "Unauthorized" (401)
- Verificar se token HubSpot está correto no `.env`
- Verificar se token tem permissão `contacts.read`

### ❌ Erro: "Cannot find Python"
- Instalar Python: https://www.python.org/downloads/
- Adicionar Python ao PATH do Windows

### ❌ Erro: PowerShell Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 💡 Próximos Passos

1. **Executar análise** → `.\run_hubspot_analysis.ps1`
2. **Revisar SQL gerado** → Ajustar tipos se necessário
3. **Executar SQL no PostgreSQL** → Criar tabela
4. **Atualizar workflows n8n** → Usar propriedades descobertas

---

## 📞 Suporte

Se encontrar problemas:
1. Verificar arquivo `.env` está correto
2. Verificar conexão com internet
3. Verificar permissões do token HubSpot
4. Executar teste rápido primeiro: `python quick_test_hubspot.py`

---

**🎯 Meta**: Descobrir exatamente quais campos existem no HubSpot da Logcomex para criar uma sincronização perfeita com PostgreSQL!
