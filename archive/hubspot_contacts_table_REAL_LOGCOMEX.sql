-- Tabela REAL baseada na análise de 500 contatos do HubSpot da Logcomex
-- Apenas campos que realmente têm dados na base atual

CREATE TABLE IF NOT EXISTS hubspot_contacts_logcomex (
    -- ID principal (sempre presente)
    id BIGINT PRIMARY KEY,
    hs_object_id INTEGER NOT NULL,
    
    -- Informações básicas (dados reais confirmados)
    email VARCHAR(100),                    -- 86.4% preenchido (432/500 contatos)
    firstname VARCHAR(50) NOT NULL,        -- 100% preenchido (500/500 contatos)
    lastname VARCHAR(50),                  -- 54.8% preenchido (274/500 contatos)
    
    -- Datas (sempre presentes, convertendo para timestamp)
    createdate TIMESTAMP WITH TIME ZONE NOT NULL,
    lastmodifieddate TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Campos preparados para expansão futura (caso comecem a usar)
    phone VARCHAR(50),                     -- Preparado para telefone
    company VARCHAR(255),                  -- Preparado para empresa
    jobtitle VARCHAR(150),                 -- Preparado para cargo
    city VARCHAR(100),                     -- Preparado para cidade
    state VARCHAR(100),                    -- Preparado para estado
    
    -- Campos específicos da Logcomex (disponíveis mas não usados ainda)
    atendimento_ativo_por VARCHAR(255),           -- E-mail agente Twilio
    buscador_ncm VARCHAR(100),                    -- NCM buscada
    cnpj_da_empresa_pesquisada VARCHAR(20),       -- CNPJ empresa
    codigo_do_voucher VARCHAR(100),               -- Voucher promocional
    
    -- Status e lifecycle (preparado)
    hs_lead_status VARCHAR(50),
    lifecyclestage VARCHAR(50),
    hubspot_owner_id BIGINT,
    
    -- Origem e tracking (preparado)
    hs_lead_source VARCHAR(100),
    hs_original_source VARCHAR(100),
    
    -- Metadados de sincronização
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'active' CHECK (sync_status IN ('active', 'deleted', 'error')),
    hubspot_raw_data JSONB NOT NULL,  -- Backup completo do JSON do HubSpot
    
    -- Constraints
    CONSTRAINT unique_hubspot_id UNIQUE (id),
    CONSTRAINT valid_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- Índices para performance (baseado nos campos realmente usados)
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_email ON hubspot_contacts_logcomex(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_firstname ON hubspot_contacts_logcomex(firstname);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastname ON hubspot_contacts_logcomex(lastname) WHERE lastname IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastmodified ON hubspot_contacts_logcomex(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_sync_date ON hubspot_contacts_logcomex(last_sync_date);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_createdate ON hubspot_contacts_logcomex(createdate);

-- Índice para busca por texto em português
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_fulltext ON hubspot_contacts_logcomex 
USING gin(to_tsvector('portuguese', 
    COALESCE(firstname,'') || ' ' || 
    COALESCE(lastname,'') || ' ' || 
    COALESCE(email,'')
));

-- View para estatísticas de preenchimento
CREATE OR REPLACE VIEW v_hubspot_contacts_stats AS
SELECT 
    COUNT(*) as total_contatos,
    COUNT(email) as contatos_com_email,
    COUNT(lastname) as contatos_com_sobrenome,
    COUNT(phone) as contatos_com_telefone,
    COUNT(company) as contatos_com_empresa,
    ROUND((COUNT(email)::numeric / COUNT(*)) * 100, 1) as percentual_email,
    ROUND((COUNT(lastname)::numeric / COUNT(*)) * 100, 1) as percentual_sobrenome,
    MAX(last_sync_date) as ultima_sincronizacao,
    COUNT(CASE WHEN sync_status = 'active' THEN 1 END) as contatos_ativos,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as contatos_com_erro
FROM hubspot_contacts_logcomex;

-- Comentários para documentação
COMMENT ON TABLE hubspot_contacts_logcomex IS 'Contatos sincronizados do HubSpot - Baseado em análise real de 500 contatos da Logcomex';
COMMENT ON COLUMN hubspot_contacts_logcomex.email IS '86.4% dos contatos têm email preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.firstname IS '100% dos contatos têm nome preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.lastname IS '54.8% dos contatos têm sobrenome preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.hubspot_raw_data IS 'JSON completo do HubSpot para backup e campos futuros';
COMMENT ON VIEW v_hubspot_contacts_stats IS 'Estatísticas de preenchimento dos campos dos contatos';

-- Função para atualizar timestamp de sincronização
CREATE OR REPLACE FUNCTION update_sync_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_sync_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER trg_update_sync_timestamp
    BEFORE UPDATE ON hubspot_contacts_logcomex
    FOR EACH ROW
    EXECUTE FUNCTION update_sync_timestamp();
