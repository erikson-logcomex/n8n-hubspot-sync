-- Tabela para sincronização de contatos do HubSpot
CREATE TABLE IF NOT EXISTS hubspot_contacts (
    -- Identificadores
    id BIGINT PRIMARY KEY,                          -- HubSpot contact ID
    hubspot_object_id VARCHAR(50),                  -- HubSpot object ID
    
    -- Informações básicas
    email VARCHAR(255),
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    phone VARCHAR(50),
    company VARCHAR(255),
    jobtitle VARCHAR(150),
    website VARCHAR(255),
    
    -- Endereço
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip VARCHAR(20),
    country VARCHAR(100),
    
    -- Informações de negócio
    industry VARCHAR(100),
    num_employees INTEGER,
    annual_revenue DECIMAL(15,2),
    lead_status VARCHAR(50),
    lifecycle_stage VARCHAR(50),
    
    -- Datas importantes (em UTC)
    createdate TIMESTAMP WITH TIME ZONE,
    lastmodifieddate TIMESTAMP WITH TIME ZONE,
    closedate TIMESTAMP WITH TIME ZONE,
    
    -- Informações de origem
    hs_lead_source VARCHAR(100),
    hs_original_source VARCHAR(100),
    hs_original_source_data_1 VARCHAR(255),
    hs_original_source_data_2 VARCHAR(255),
    
    -- Campos personalizados comuns
    hubspot_owner_id BIGINT,
    hs_analytics_source VARCHAR(100),
    hs_analytics_source_data_1 VARCHAR(255),
    
    -- Metadados de sincronização
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'active',       -- active, deleted, error
    hubspot_raw_data JSONB,                         -- JSON completo do HubSpot para backup
    
    -- Índices para performance
    CONSTRAINT unique_hubspot_id UNIQUE (id)
);

-- Índices para otimização
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_email ON hubspot_contacts(email);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_company ON hubspot_contacts(company);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastmodified ON hubspot_contacts(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_sync_date ON hubspot_contacts(last_sync_date);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lifecycle ON hubspot_contacts(lifecycle_stage);

-- Índice para busca por texto
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_fulltext ON hubspot_contacts 
USING gin(to_tsvector('portuguese', COALESCE(firstname,'') || ' ' || COALESCE(lastname,'') || ' ' || COALESCE(email,'') || ' ' || COALESCE(company,'')));

-- Comentários para documentação
COMMENT ON TABLE hubspot_contacts IS 'Tabela espelho dos contatos do HubSpot - sincronizada via n8n';
COMMENT ON COLUMN hubspot_contacts.hubspot_raw_data IS 'JSON completo retornado pela API do HubSpot para backup e campos futuros';
COMMENT ON COLUMN hubspot_contacts.last_sync_date IS 'Data da última sincronização com o HubSpot';
COMMENT ON COLUMN hubspot_contacts.sync_status IS 'Status da sincronização: active, deleted, error';
