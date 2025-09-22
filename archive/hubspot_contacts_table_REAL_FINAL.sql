-- Tabela REAL baseada nos dados VERDADEIROS do HubSpot da Logcomex
-- Análise de propriedades específicas confirmou muito mais dados!

CREATE TABLE IF NOT EXISTS hubspot_contacts_logcomex (
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
    CONSTRAINT unique_hubspot_id UNIQUE (id),
    CONSTRAINT valid_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- Índices para performance (baseado nos campos REALMENTE usados)
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_email ON hubspot_contacts_logcomex(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_company ON hubspot_contacts_logcomex(company);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_phone ON hubspot_contacts_logcomex(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_mobilephone ON hubspot_contacts_logcomex(mobilephone) WHERE mobilephone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_website ON hubspot_contacts_logcomex(website) WHERE website IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_jobtitle ON hubspot_contacts_logcomex(jobtitle) WHERE jobtitle IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lifecyclestage ON hubspot_contacts_logcomex(lifecyclestage);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_voucher ON hubspot_contacts_logcomex(codigo_do_voucher) WHERE codigo_do_voucher IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastmodified ON hubspot_contacts_logcomex(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_sync_date ON hubspot_contacts_logcomex(last_sync_date);

-- Índice para busca por texto completa (português)
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_fulltext ON hubspot_contacts_logcomex 
USING gin(to_tsvector('portuguese', 
    COALESCE(firstname,'') || ' ' || 
    COALESCE(lastname,'') || ' ' || 
    COALESCE(email,'') || ' ' || 
    COALESCE(company,'') || ' ' || 
    COALESCE(jobtitle,'')
));

-- Índice para busca por telefones
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_phones ON hubspot_contacts_logcomex 
USING gin((COALESCE(phone,'') || ' ' || COALESCE(mobilephone,'') || ' ' || COALESCE(hs_whatsapp_phone_number,'')) gin_trgm_ops);

-- View para estatísticas REAIS de preenchimento
CREATE OR REPLACE VIEW v_hubspot_contacts_stats_real AS
SELECT 
    COUNT(*) as total_contatos,
    
    -- Campos básicos
    COUNT(email) as contatos_com_email,
    ROUND((COUNT(email)::numeric / COUNT(*)) * 100, 1) as percentual_email,
    
    COUNT(company) as contatos_com_empresa,
    ROUND((COUNT(company)::numeric / COUNT(*)) * 100, 1) as percentual_empresa,
    
    -- Telefones
    COUNT(phone) as contatos_com_telefone,
    ROUND((COUNT(phone)::numeric / COUNT(*)) * 100, 1) as percentual_telefone,
    
    COUNT(mobilephone) as contatos_com_celular,
    ROUND((COUNT(mobilephone)::numeric / COUNT(*)) * 100, 1) as percentual_celular,
    
    COUNT(hs_whatsapp_phone_number) as contatos_com_whatsapp,
    ROUND((COUNT(hs_whatsapp_phone_number)::numeric / COUNT(*)) * 100, 1) as percentual_whatsapp,
    
    -- Profissionais
    COUNT(jobtitle) as contatos_com_cargo,
    ROUND((COUNT(jobtitle)::numeric / COUNT(*)) * 100, 1) as percentual_cargo,
    
    COUNT(website) as contatos_com_website,
    ROUND((COUNT(website)::numeric / COUNT(*)) * 100, 1) as percentual_website,
    
    -- Específicos Logcomex
    COUNT(codigo_do_voucher) as contatos_com_voucher,
    ROUND((COUNT(codigo_do_voucher)::numeric / COUNT(*)) * 100, 1) as percentual_voucher,
    
    -- Status
    COUNT(lifecyclestage) as contatos_com_lifecycle,
    ROUND((COUNT(lifecyclestage)::numeric / COUNT(*)) * 100, 1) as percentual_lifecycle,
    
    -- Metadados
    MAX(last_sync_date) as ultima_sincronizacao,
    COUNT(CASE WHEN sync_status = 'active' THEN 1 END) as contatos_ativos,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as contatos_com_erro
FROM hubspot_contacts_logcomex;

-- Comentários atualizados com dados reais
COMMENT ON TABLE hubspot_contacts_logcomex IS 'Contatos HubSpot Logcomex - Estrutura baseada em análise real de propriedades específicas';
COMMENT ON COLUMN hubspot_contacts_logcomex.company IS '100% dos contatos têm empresa preenchida';
COMMENT ON COLUMN hubspot_contacts_logcomex.phone IS '98% dos contatos têm telefone preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.website IS '92% dos contatos têm website preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.codigo_do_voucher IS '80% dos contatos têm voucher preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.jobtitle IS '76% dos contatos têm cargo preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.lifecyclestage IS '100% dos contatos têm lifecycle preenchido';
COMMENT ON COLUMN hubspot_contacts_logcomex.mobilephone IS '38% dos contatos têm celular preenchido';
COMMENT ON VIEW v_hubspot_contacts_stats_real IS 'Estatísticas baseadas em dados reais do HubSpot Logcomex';
