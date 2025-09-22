-- Tabela de contatos seguindo padrão das outras tabelas do HubSpot
-- Padrão: companies, deals, owners, contacts

CREATE TABLE IF NOT EXISTS contacts (
    -- ID principal (sempre presente)
    id BIGINT PRIMARY KEY,
    hs_object_id INTEGER NOT NULL,
    
    -- Informações básicas (CONFIRMADO com dados reais)
    email VARCHAR(255),                    -- 80% preenchido
    firstname VARCHAR(100) NOT NULL,       -- 100% preenchido
    lastname VARCHAR(100),                 -- 42% preenchido
    
    -- Informações profissionais (CONFIRMADO!)
    company VARCHAR(255) NOT NULL,         -- 100% preenchido! 🏢
    jobtitle VARCHAR(255),                 -- 76% preenchido! 💼
    website VARCHAR(255),                  -- 92% preenchido! 🌐
    
    -- Telefones (CONFIRMADO - múltiplos tipos!)
    phone VARCHAR(50),                     -- 98% preenchido! ☎️ 
    mobilephone VARCHAR(50),               -- 38% preenchido! 📱
    hs_whatsapp_phone_number VARCHAR(50),  -- WhatsApp dedicado
    govcs_i_phone_number VARCHAR(50),      -- Integração Twilio
    
    -- Status e lifecycle (CONFIRMADO!)
    lifecyclestage VARCHAR(50) NOT NULL,   -- 100% preenchido! 📊
    hs_lead_status VARCHAR(50),
    hubspot_owner_id BIGINT,
    
    -- Campos específicos da Logcomex (CONFIRMADO em uso!)
    codigo_do_voucher VARCHAR(100),               -- 80% preenchido! 🎫
    atendimento_ativo_por VARCHAR(255),           -- E-mail agente Twilio
    buscador_ncm VARCHAR(100),                    -- NCM buscada
    cnpj_da_empresa_pesquisada VARCHAR(20),       -- CNPJ empresa
    
    -- Campos de WhatsApp (específicos da Logcomex)
    contato_por_whatsapp VARCHAR(50),             -- Aceita WhatsApp
    criado_whatsapp VARCHAR(50),                  -- Criado via WhatsApp
    whatsapp_api VARCHAR(100),                    -- API WhatsApp
    whatsapp_error_spread_chat TEXT,              -- Erros disparo WhatsApp
    
    -- Campos de telefone calculados pelo HubSpot
    hs_calculated_phone_number VARCHAR(50),
    hs_calculated_mobile_number VARCHAR(50),
    hs_calculated_phone_number_country_code VARCHAR(10),
    hs_calculated_phone_number_area_code VARCHAR(10),
    
    -- Campos específicos Ravena/RevOps
    telefone_ravena_classificado__revops_ VARCHAR(50),
    
    -- Campos de personas
    celular1_gerador_de_personas VARCHAR(50),
    celular2_gerador_de_personas VARCHAR(50),
    
    -- Endereço (preparado)
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip VARCHAR(20),
    country VARCHAR(100),
    
    -- Datas (sempre presentes)
    createdate TIMESTAMP WITH TIME ZONE NOT NULL,
    lastmodifieddate TIMESTAMP WITH TIME ZONE NOT NULL,
    closedate TIMESTAMP WITH TIME ZONE,
    
    -- Origem e tracking
    hs_lead_source VARCHAR(100),
    hs_original_source VARCHAR(100),
    hs_original_source_data_1 VARCHAR(255),
    hs_original_source_data_2 VARCHAR(255),
    
    -- Metadados de sincronização
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'active' CHECK (sync_status IN ('active', 'deleted', 'error')),
    hubspot_raw_data JSONB NOT NULL,  -- Backup completo do JSON
    
    -- Constraints
    CONSTRAINT unique_hubspot_contact_id UNIQUE (id),
    CONSTRAINT valid_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- Índices para performance (seguindo padrão das outras tabelas)
CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_company ON contacts(company);
CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_mobilephone ON contacts(mobilephone) WHERE mobilephone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_website ON contacts(website) WHERE website IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_jobtitle ON contacts(jobtitle) WHERE jobtitle IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_lifecyclestage ON contacts(lifecyclestage);
CREATE INDEX IF NOT EXISTS idx_contacts_voucher ON contacts(codigo_do_voucher) WHERE codigo_do_voucher IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_lastmodified ON contacts(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_contacts_sync_date ON contacts(last_sync_date);
CREATE INDEX IF NOT EXISTS idx_contacts_createdate ON contacts(createdate);
CREATE INDEX IF NOT EXISTS idx_contacts_hubspot_owner ON contacts(hubspot_owner_id) WHERE hubspot_owner_id IS NOT NULL;

-- Índice para busca por texto completa (português)
CREATE INDEX IF NOT EXISTS idx_contacts_fulltext ON contacts 
USING gin(to_tsvector('portuguese', 
    COALESCE(firstname,'') || ' ' || 
    COALESCE(lastname,'') || ' ' || 
    COALESCE(email,'') || ' ' || 
    COALESCE(company,'') || ' ' || 
    COALESCE(jobtitle,'')
));

-- Índice para busca por telefones (simplificado)
CREATE INDEX IF NOT EXISTS idx_contacts_phone_search ON contacts(phone, mobilephone, hs_whatsapp_phone_number);

-- View para estatísticas de preenchimento (seguindo padrão)
CREATE OR REPLACE VIEW v_contacts_stats AS
SELECT 
    COUNT(*) as total_contacts,
    
    -- Campos básicos
    COUNT(email) as contacts_with_email,
    ROUND((COUNT(email)::numeric / COUNT(*)) * 100, 1) as email_percentage,
    
    COUNT(company) as contacts_with_company,
    ROUND((COUNT(company)::numeric / COUNT(*)) * 100, 1) as company_percentage,
    
    -- Telefones
    COUNT(phone) as contacts_with_phone,
    ROUND((COUNT(phone)::numeric / COUNT(*)) * 100, 1) as phone_percentage,
    
    COUNT(mobilephone) as contacts_with_mobile,
    ROUND((COUNT(mobilephone)::numeric / COUNT(*)) * 100, 1) as mobile_percentage,
    
    COUNT(hs_whatsapp_phone_number) as contacts_with_whatsapp,
    ROUND((COUNT(hs_whatsapp_phone_number)::numeric / COUNT(*)) * 100, 1) as whatsapp_percentage,
    
    -- Profissionais
    COUNT(jobtitle) as contacts_with_jobtitle,
    ROUND((COUNT(jobtitle)::numeric / COUNT(*)) * 100, 1) as jobtitle_percentage,
    
    COUNT(website) as contacts_with_website,
    ROUND((COUNT(website)::numeric / COUNT(*)) * 100, 1) as website_percentage,
    
    -- Específicos Logcomex
    COUNT(codigo_do_voucher) as contacts_with_voucher,
    ROUND((COUNT(codigo_do_voucher)::numeric / COUNT(*)) * 100, 1) as voucher_percentage,
    
    -- Status
    COUNT(lifecyclestage) as contacts_with_lifecycle,
    ROUND((COUNT(lifecyclestage)::numeric / COUNT(*)) * 100, 1) as lifecycle_percentage,
    
    -- Metadados
    MAX(last_sync_date) as last_sync,
    COUNT(CASE WHEN sync_status = 'active' THEN 1 END) as active_contacts,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as error_contacts
FROM contacts;

-- View para contatos por lifecycle stage (padrão HubSpot)
CREATE OR REPLACE VIEW v_contacts_by_lifecycle AS
SELECT 
    lifecyclestage,
    COUNT(*) as total_contacts,
    ROUND((COUNT(*)::numeric / (SELECT COUNT(*) FROM contacts)) * 100, 1) as percentage
FROM contacts 
WHERE lifecyclestage IS NOT NULL
GROUP BY lifecyclestage
ORDER BY total_contacts DESC;

-- View para top empresas (útil para análises)
CREATE OR REPLACE VIEW v_contacts_by_company AS
SELECT 
    company,
    COUNT(*) as total_contacts,
    COUNT(email) as contacts_with_email,
    COUNT(phone) as contacts_with_phone
FROM contacts 
WHERE company IS NOT NULL
GROUP BY company
ORDER BY total_contacts DESC;

-- Comentários seguindo padrão das outras tabelas
COMMENT ON TABLE contacts IS 'Contatos sincronizados do HubSpot - Segue padrão das outras tabelas (companies, deals, owners)';
COMMENT ON COLUMN contacts.company IS '100% dos contatos têm empresa preenchida';
COMMENT ON COLUMN contacts.phone IS '98% dos contatos têm telefone preenchido';
COMMENT ON COLUMN contacts.website IS '92% dos contatos têm website preenchido';
COMMENT ON COLUMN contacts.codigo_do_voucher IS '80% dos contatos têm voucher preenchido';
COMMENT ON COLUMN contacts.jobtitle IS '76% dos contatos têm cargo preenchido';
COMMENT ON COLUMN contacts.lifecyclestage IS '100% dos contatos têm lifecycle preenchido';
COMMENT ON COLUMN contacts.mobilephone IS '38% dos contatos têm celular preenchido';
COMMENT ON VIEW v_contacts_stats IS 'Estatísticas de preenchimento dos contatos';
COMMENT ON VIEW v_contacts_by_lifecycle IS 'Distribuição de contatos por estágio do lifecycle';
COMMENT ON VIEW v_contacts_by_company IS 'Contatos agrupados por empresa';

-- Função para atualizar timestamp de sincronização
CREATE OR REPLACE FUNCTION update_contact_sync_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_sync_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER trg_update_contact_sync_timestamp
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_contact_sync_timestamp();
