-- ==========================================
-- 🎯 TABELA CONTACTS OTIMIZADA
-- Baseada na análise real de 50 contatos do HubSpot
-- ==========================================

-- Remover tabela antiga se existir
DROP TABLE IF EXISTS contacts_old CASCADE;

-- Renomear tabela atual para backup
ALTER TABLE contacts RENAME TO contacts_old;

-- ==========================================
-- 📋 CRIAR NOVA TABELA OTIMIZADA
-- ==========================================

CREATE TABLE contacts (
    -- 🔑 CHAVES PRIMÁRIAS
    id BIGSERIAL PRIMARY KEY,
    hs_object_id INTEGER UNIQUE NOT NULL,
    
    -- 👤 DADOS PESSOAIS (100% preenchidos)
    firstname VARCHAR(300),
    lastname VARCHAR(300),
    email VARCHAR(255),
    
    -- 🏢 DADOS EMPRESARIAIS (100% preenchidos)
    company VARCHAR(500),
    jobtitle VARCHAR(500),
    website VARCHAR(500),
    
    -- 📞 TELEFONES (98% phone, 38% mobile)
    phone VARCHAR(100),
    mobilephone VARCHAR(100),
    
    -- 📍 ENDEREÇO (menos usado, mas importante)
    address VARCHAR(1000),
    city VARCHAR(300),
    state VARCHAR(300),
    zip VARCHAR(50),
    country VARCHAR(100),
    
    -- 🎯 DADOS HUBSPOT (100% preenchidos)
    lifecyclestage VARCHAR(100),
    hs_lead_status VARCHAR(100),
    
    -- 📅 DATAS (100% preenchidos)
    createdate TIMESTAMP,
    lastmodifieddate TIMESTAMP,
    
    -- 🎫 CÓDIGO VOUCHER (80% preenchidos)
    codigo_do_voucher VARCHAR(200),
    
    -- 👤 OWNER (se aplicável)
    hubspot_owner_id BIGINT,
    
    -- 📊 DADOS DE AUDITORIA
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(50) DEFAULT 'active',
    
    -- 📄 DADOS RAW (para backup)
    hubspot_raw_data JSONB
);

-- ==========================================
-- 🔍 ÍNDICES OTIMIZADOS
-- ==========================================

-- Índices principais
CREATE INDEX idx_contacts_hs_object_id ON contacts(hs_object_id);
CREATE INDEX idx_contacts_email ON contacts(email) WHERE email IS NOT NULL;
CREATE INDEX idx_contacts_company ON contacts(company);
CREATE INDEX idx_contacts_phone ON contacts(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_contacts_lastmodified ON contacts(lastmodifieddate);
CREATE INDEX idx_contacts_createdate ON contacts(createdate);
CREATE INDEX idx_contacts_lifecyclestage ON contacts(lifecyclestage);

-- Índice composto para busca
CREATE INDEX idx_contacts_search ON contacts(firstname, lastname, company, email);

-- Índice para sincronização incremental
CREATE INDEX idx_contacts_sync ON contacts(lastmodifieddate, sync_status);

-- Índice fulltext para busca avançada
CREATE INDEX idx_contacts_fulltext ON contacts 
USING gin(to_tsvector('portuguese', 
    COALESCE(firstname, '') || ' ' || 
    COALESCE(lastname, '') || ' ' || 
    COALESCE(company, '') || ' ' || 
    COALESCE(email, '')
));

-- ==========================================
-- 🔒 CONSTRAINTS
-- ==========================================

-- Constraint para sync_status
ALTER TABLE contacts ADD CONSTRAINT contacts_sync_status_check 
CHECK (sync_status IN ('active', 'inactive', 'error', 'syncing'));

-- ==========================================
-- 📊 VIEWS ÚTEIS
-- ==========================================

-- View de estatísticas
CREATE OR REPLACE VIEW v_contacts_stats AS
SELECT 
    COUNT(*) as total_contatos,
    COUNT(email) as com_email,
    COUNT(phone) as com_telefone,
    COUNT(company) as com_empresa,
    COUNT(codigo_do_voucher) as com_voucher,
    MIN(createdate) as contato_mais_antigo,
    MAX(lastmodifieddate) as ultima_modificacao,
    MAX(updated_at) as ultima_sincronizacao,
    COUNT(CASE WHEN sync_status = 'active' THEN 1 END) as ativos,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as com_erro
FROM contacts;

-- View por lifecycle stage
CREATE OR REPLACE VIEW v_contacts_by_lifecycle AS
SELECT 
    lifecyclestage,
    COUNT(*) as total,
    COUNT(email) as com_email,
    COUNT(phone) as com_telefone,
    COUNT(company) as com_empresa
FROM contacts 
GROUP BY lifecyclestage 
ORDER BY total DESC;

-- ==========================================
-- 🔄 FUNÇÕES E TRIGGERS
-- ==========================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_contact_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at
CREATE TRIGGER trg_update_contact_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_contact_updated_at();

-- ==========================================
-- 📋 MIGRAÇÃO DE DADOS (OPCIONAL)
-- ==========================================

-- Comentário: Para migrar dados da tabela antiga, descomente:
/*
INSERT INTO contacts (
    hs_object_id, firstname, lastname, email, company, jobtitle, website,
    phone, mobilephone, address, city, state, zip, country,
    lifecyclestage, hs_lead_status, createdate, lastmodifieddate,
    codigo_do_voucher, hubspot_owner_id, sync_status
)
SELECT 
    hs_object_id, firstname, lastname, email, company, jobtitle, website,
    phone, mobilephone, address, city, state, zip, country,
    lifecyclestage, hs_lead_status, 
    CASE 
        WHEN createdate IS NOT NULL THEN createdate::timestamp 
        ELSE CURRENT_TIMESTAMP 
    END,
    CASE 
        WHEN lastmodifieddate IS NOT NULL THEN lastmodifieddate::timestamp 
        ELSE CURRENT_TIMESTAMP 
    END,
    codigo_do_voucher, hubspot_owner_id, 'active'
FROM contacts_old;
*/

-- ==========================================
-- ✅ VERIFICAÇÃO FINAL
-- ==========================================

-- Verificar estrutura
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'contacts' 
ORDER BY ordinal_position;

-- Verificar constraints
SELECT 
    constraint_name, 
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'contacts';

-- Verificar índices
SELECT 
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'contacts';

