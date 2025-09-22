# 🚀 Guia de Implementação - Sincronização HubSpot → PostgreSQL

## 📋 Resumo
Este guia contém todas as instruções para implementar a sincronização automática de contatos do HubSpot para PostgreSQL usando n8n.

## 🎯 Objetivos
- ✅ Sincronizar todos os contatos do HubSpot para PostgreSQL
- ✅ Manter dados atualizados automaticamente (sincronização incremental)
- ✅ Tratamento de erros e logs completos
- ✅ Performance otimizada

---

## 📋 Pré-requisitos

### 1. Credenciais do HubSpot
- [ ] Token de API Privada do HubSpot
- [ ] Permissões: `contacts.read`

### 2. Acesso ao PostgreSQL
- [ ] Host: `172.23.64.3:5432`
- [ ] Database: `n8n-postgres-db` (ou sua database)
- [ ] Usuário com permissões de `INSERT`, `UPDATE`, `SELECT`

### 3. n8n Configurado
- [ ] Acesso ao n8n: `https://n8n-logcomex.34-8-101-220.nip.io`
- [ ] Credenciais configuradas para HubSpot e PostgreSQL

---

## 🗄️ Etapa 1: Criar Tabela no PostgreSQL

Execute o seguinte script no seu PostgreSQL:

```sql
-- Ver arquivo: hubspot_contacts_table.sql
```

**⚠️ IMPORTANTE**: Ajuste os tipos de dados conforme seus campos personalizados no HubSpot.

---

## 🔧 Etapa 2: Configurar Credenciais no n8n

### 2.1 Credencial HubSpot
1. Acesse: `Settings > Credentials`
2. Clique em `+ Add Credential`
3. Selecione `HubSpot API`
4. Configure:
   - **Name**: `HubSpot API Logcomex`
   - **API Key**: Seu token de API privada
   - **App ID**: (deixe vazio se usando API Key)

### 2.2 Credencial PostgreSQL
1. Clique em `+ Add Credential`
2. Selecione `Postgres`
3. Configure:
   - **Name**: `PostgreSQL Logcomex`
   - **Host**: `172.23.64.3`
   - **Port**: `5432`
   - **Database**: `n8n-postgres-db`
   - **Username**: Seu usuário
   - **Password**: Sua senha
   - **SSL**: `disable` (ou conforme sua configuração)

---

## 📥 Etapa 3: Importar Workflows

### 3.1 Workflow de Sincronização Inicial
1. No n8n, vá em `Workflows`
2. Clique em `+ Add workflow`
3. No menu superior, clique nos `...` e selecione `Import from file`
4. Importe o arquivo: `n8n_workflow_hubspot_sync_inicial.json`
5. **Atualize os IDs das credenciais**:
   - Substitua `seu_hubspot_credential_id` pelo ID real
   - Substitua `seu_postgres_credential_id` pelo ID real

### 3.2 Workflow de Sincronização Incremental
1. Repita o processo para o arquivo: `n8n_workflow_hubspot_sync_incremental.json`
2. Atualize os IDs das credenciais

---

## ⚙️ Etapa 4: Configurações Avançadas

### 4.1 Ajustar Campos do HubSpot
Se você tem campos personalizados, edite o nó "HubSpot - Buscar Contatos" e adicione na lista `properties`:

```javascript
// Exemplos de campos personalizados
"custom_field_1",
"data_source",
"lead_score",
"preferred_language"
```

### 4.2 Ajustar Mapeamento no PostgreSQL
No nó "Processar Dados", adicione mapeamento para campos personalizados:

```javascript
// Adicione no processedContact
custom_field_1: contact.properties?.custom_field_1 || null,
data_source: contact.properties?.data_source || null,
lead_score: contact.properties?.lead_score ? parseInt(contact.properties.lead_score) : null
```

### 4.3 Configurar Frequência de Sincronização
No workflow incremental, ajuste o nó "Cron Trigger":
- **A cada 2 horas**: `hoursInterval: 2` (padrão)
- **A cada 1 hora**: `hoursInterval: 1`
- **A cada 30 minutos**: `minutesInterval: 30`

---

## 🚀 Etapa 5: Execução

### 5.1 Primeira Sincronização (Inicial)
1. Abra o workflow **"HubSpot → PostgreSQL - Sincronização Inicial"**
2. Clique em `Execute Workflow`
3. Monitore os logs para verificar se está funcionando
4. ⏰ **Tempo estimado**: 10-30 minutos (dependendo do número de contatos)

### 5.2 Ativação da Sincronização Automática
1. Abra o workflow **"HubSpot → PostgreSQL - Sincronização Incremental"**
2. Toggle o switch para `Active`
3. O workflow agora executará automaticamente a cada 2 horas

---

## 📊 Etapa 6: Monitoramento e Logs

### 6.1 Verificar Execuções
```sql
-- Verificar contatos sincronizados
SELECT 
    COUNT(*) as total_contatos,
    MAX(last_sync_date) as ultima_sincronizacao,
    COUNT(CASE WHEN sync_status = 'active' THEN 1 END) as ativos,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as com_erro
FROM hubspot_contacts;
```

### 6.2 Logs no n8n
- Acesse `Executions` para ver histórico
- Verifique logs de cada nó para debug
- Configure notificações por email em caso de erro

### 6.3 Monitoramento de Performance
```sql
-- Contatos mais recentes
SELECT firstname, lastname, email, company, last_sync_date 
FROM hubspot_contacts 
ORDER BY last_sync_date DESC 
LIMIT 10;

-- Contatos com erro
SELECT id, email, sync_status, last_sync_date 
FROM hubspot_contacts 
WHERE sync_status = 'error';
```

---

## 🛠️ Etapa 7: Tratamento de Erros

### 7.1 Workflow de Tratamento de Erros
Crie um workflow adicional para monitorar e tratar erros:

```javascript
// Verificar contatos com erro na sincronização
SELECT id, email, hubspot_raw_data, last_sync_date 
FROM hubspot_contacts 
WHERE sync_status = 'error' 
AND last_sync_date > NOW() - INTERVAL '24 hours'
```

### 7.2 Retry Automático
Configure retry nos nós do n8n:
- **Retry**: 3 tentativas
- **Retry Interval**: 5 minutos

### 7.3 Notificações de Erro
Adicione nó de email/Slack para notificar em caso de falhas críticas.

---

## 📈 Etapa 8: Otimizações

### 8.1 Índices de Performance
```sql
-- Já incluídos no script inicial, mas verifique se foram criados
\d+ hubspot_contacts
```

### 8.2 Limpeza de Dados Antigos
```sql
-- Remover dados de teste (se necessário)
DELETE FROM hubspot_contacts WHERE email LIKE '%test%';
```

### 8.3 Backup da Tabela
```sql
-- Criar backup antes de grandes mudanças
CREATE TABLE hubspot_contacts_backup AS 
SELECT * FROM hubspot_contacts;
```

---

## 🔍 Troubleshooting

### Erro: "Rate limit exceeded"
- **Solução**: Adicione delay entre requests no n8n
- **Configuração**: Wait node com 2-5 segundos

### Erro: "Connection timeout"
- **Solução**: Aumentar timeout do PostgreSQL
- **Configuração**: 30-60 segundos

### Erro: "Duplicate key value"
- **Solução**: Usar `UPSERT` em vez de `INSERT`
- **Já configurado** nos workflows fornecidos

### Dados não aparecem no PostgreSQL
1. Verificar credenciais
2. Verificar permissões da tabela
3. Verificar logs do n8n
4. Testar conexão PostgreSQL manualmente

---

## 📊 Métricas de Sucesso

### ✅ KPIs para Monitorar
- **Total de contatos sincronizados**
- **Tempo de sincronização**
- **Taxa de erro < 1%**
- **Frequência de sincronização respeitada**

### 📈 Relatórios Úteis
```sql
-- Relatório de sincronização diária
SELECT 
    DATE(last_sync_date) as data_sync,
    COUNT(*) as contatos_sincronizados,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as erros
FROM hubspot_contacts 
WHERE last_sync_date > NOW() - INTERVAL '7 days'
GROUP BY DATE(last_sync_date)
ORDER BY data_sync DESC;
```

---

## 🎯 Próximos Passos (Opcional)

### 1. Webhooks em Tempo Real
- Implementar webhook do HubSpot para updates instantâneos
- Requer endpoint público e validação de segurança

### 2. Sincronização Bidirecionnal
- Permitir atualizações do PostgreSQL de volta para o HubSpot
- Requer cuidado com conflitos de dados

### 3. Mais Objetos do HubSpot
- Companies, Deals, Tickets
- Usar a mesma estrutura dos workflows

### 4. Dashboard de Monitoramento
- Grafana/Metabase para visualizar métricas
- Alertas automáticos

---

## 📞 Suporte

- **Documentação n8n**: https://docs.n8n.io/
- **API HubSpot**: https://developers.hubspot.com/docs/api/overview
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

**🎉 Parabéns!** Sua sincronização HubSpot → PostgreSQL está configurada e funcionando!

> **Próxima execução incremental**: Em 2 horas (ou conforme configurado)
