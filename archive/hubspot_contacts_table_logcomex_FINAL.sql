-- Tabela final para contatos HubSpot → PostgreSQL da Logcomex
-- Baseada na análise real + campos importantes para o futuro

CREATE TABLE IF NOT EXISTS hubspot_contacts_logcomex (
    -- ID principal
    id BIGINT PRIMARY KEY,
    hs_object_id INTEGER,
    
    -- Informações básicas (com dados atuais)
    email VARCHAR(255),
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    
    -- Informações de contato (preparado para futuro)
    phone VARCHAR(50),
    celular1_gerador_de_personas VARCHAR(50),
    celular2_gerador_de_personas VARCHAR(50),
    
    -- Informações profissionais
    company VARCHAR(255),
    cargo VARCHAR(150),  -- Campo personalizado da Logcomex
    
    -- Endereço
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip VARCHAR(20),
    country VARCHAR(100),
    
    -- Campos específicos da Logcomex
    atendimento_ativo_por VARCHAR(255),           -- E-mail agente Twilio
    buscador_ncm VARCHAR(100),                    -- NCM buscada
    cnpj_da_empresa_pesquisada VARCHAR(20),       -- CNPJ empresa
    codigo_do_voucher VARCHAR(100),               -- Voucher promocional
    como_realizam_o_acompanhamento_hoje_ TEXT,    -- Processo atual
    
    -- Informações comerciais
    annualrevenue DECIMAL(15,2),
    industria VARCHAR(100),
    
    -- Status e lifecycle
    hs_lead_status VARCHAR(50),
    lifecyclestage VARCHAR(50),
    hubspot_owner_id BIGINT,
    
    -- Datas (convertendo para timestamp)
    createdate TIMESTAMP WITH TIME ZONE,
    lastmodifieddate TIMESTAMP WITH TIME ZONE,
    closedate TIMESTAMP WITH TIME ZONE,
    
    -- Origem e tracking
    hs_lead_source VARCHAR(100),
    hs_original_source VARCHAR(100),
    hs_original_source_data_1 VARCHAR(255),
    hs_original_source_data_2 VARCHAR(255),
    hs_analytics_source VARCHAR(100),
    
    -- Metadados de sincronização
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'active',
    hubspot_raw_data JSONB,  -- Backup completo do JSON do HubSpot
    
    -- Constraint
    CONSTRAINT unique_hubspot_id UNIQUE (id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_email ON hubspot_contacts_logcomex(email);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_company ON hubspot_contacts_logcomex(company);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastmodified ON hubspot_contacts_logcomex(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_sync_date ON hubspot_contacts_logcomex(last_sync_date);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_cnpj ON hubspot_contacts_logcomex(cnpj_da_empresa_pesquisada);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_voucher ON hubspot_contacts_logcomex(codigo_do_voucher);

-- Índice para busca por texto (português)
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_fulltext ON hubspot_contacts_logcomex 
USING gin(to_tsvector('portuguese', 
    COALESCE(firstname,'') || ' ' || 
    COALESCE(lastname,'') || ' ' || 
    COALESCE(email,'') || ' ' || 
    COALESCE(company,'')
));

-- Comentários
COMMENT ON TABLE hubspot_contacts_logcomex IS 'Contatos sincronizados do HubSpot para PostgreSQL - Logcomex';
COMMENT ON COLUMN hubspot_contacts_logcomex.atendimento_ativo_por IS 'E-mail do agente que disparou mensagem pelo Flex da Twilio';
COMMENT ON COLUMN hubspot_contacts_logcomex.buscador_ncm IS 'NCM buscada na hora da conversão';
COMMENT ON COLUMN hubspot_contacts_logcomex.cnpj_da_empresa_pesquisada IS 'CNPJ da empresa pesquisada (propriedade de produto)';
COMMENT ON COLUMN hubspot_contacts_logcomex.codigo_do_voucher IS 'Voucher promocional enviado para os loggers';
COMMENT ON COLUMN hubspot_contacts_logcomex.hubspot_raw_data IS 'JSON completo do HubSpot para backup e campos futuros';
