-- Tabela de empresas seguindo padrão das outras tabelas do HubSpot
-- Padrão: companies, deals, owners, contacts

CREATE TABLE IF NOT EXISTS companies (
    -- ID principal (sempre presente)
    id BIGINT PRIMARY KEY,
    hs_object_id INTEGER NOT NULL,
    
    -- Informações básicas da empresa
    name VARCHAR(255) NOT NULL,                    -- Nome da empresa (100% preenchido)
    domain VARCHAR(255),                           -- Domínio da empresa
    website VARCHAR(255),                          -- Website da empresa
    
    -- Informações de contato
    phone VARCHAR(50),                             -- Telefone principal
    city VARCHAR(100),                             -- Cidade
    state VARCHAR(100),                            -- Estado
    country VARCHAR(100),                          -- País
    zip VARCHAR(20),                               -- CEP
    address VARCHAR(255),                          -- Endereço completo
    
    -- Informações de negócio
    industry VARCHAR(100),                         -- Indústria
    numberofemployees INTEGER,                     -- Número de funcionários
    annualrevenue DECIMAL(15,2),                   -- Receita anual
    description TEXT,                              -- Descrição da empresa
    
    -- Status e lifecycle
    lifecyclestage VARCHAR(50) NOT NULL,           -- Estágio do lifecycle
    hubspot_owner_id BIGINT,                       -- ID do proprietário no HubSpot
    
    -- Campos específicos da Logcomex
    cnpj VARCHAR(20),                              -- CNPJ da empresa
    inscricao_estadual VARCHAR(50),                -- Inscrição estadual
    inscricao_municipal VARCHAR(50),               -- Inscrição municipal
    regime_tributario VARCHAR(50),                 -- Regime tributário
    porte_empresa VARCHAR(50),                     -- Porte da empresa
    
    -- Campos de integração
    hs_lead_source VARCHAR(100),                   -- Fonte do lead
    hs_original_source VARCHAR(100),               -- Fonte original
    hs_original_source_data_1 VARCHAR(255),        -- Dados da fonte original 1
    hs_original_source_data_2 VARCHAR(255),        -- Dados da fonte original 2
    
    -- Campos de analytics
    hs_analytics_source VARCHAR(100),              -- Fonte de analytics
    hs_analytics_source_data_1 VARCHAR(255),       -- Dados de analytics 1
    hs_analytics_source_data_2 VARCHAR(255),       -- Dados de analytics 2
    
    -- Datas (sempre presentes)
    createdate TIMESTAMP WITH TIME ZONE NOT NULL,
    lastmodifieddate TIMESTAMP WITH TIME ZONE NOT NULL,
    closedate TIMESTAMP WITH TIME ZONE,
    
    -- Metadados de sincronização
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'active' CHECK (sync_status IN ('active', 'deleted', 'error')),
    hubspot_raw_data JSONB NOT NULL,               -- Backup completo do JSON
    
    -- Constraints
    CONSTRAINT unique_hubspot_company_id UNIQUE (id),
    CONSTRAINT valid_domain CHECK (domain ~ '^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)*$' OR domain IS NULL),
    CONSTRAINT valid_cnpj CHECK (cnpj ~ '^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$' OR cnpj IS NULL)
);

-- Índices para performance (seguindo padrão das outras tabelas)
CREATE INDEX IF NOT EXISTS idx_companies_name ON companies(name);
CREATE INDEX IF NOT EXISTS idx_companies_domain ON companies(domain) WHERE domain IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_website ON companies(website) WHERE website IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_phone ON companies(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_city ON companies(city) WHERE city IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_state ON companies(state) WHERE state IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_country ON companies(country) WHERE country IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_industry ON companies(industry) WHERE industry IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_lifecyclestage ON companies(lifecyclestage);
CREATE INDEX IF NOT EXISTS idx_companies_lastmodified ON companies(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_companies_sync_date ON companies(last_sync_date);
CREATE INDEX IF NOT EXISTS idx_companies_createdate ON companies(createdate);
CREATE INDEX IF NOT EXISTS idx_companies_hubspot_owner ON companies(hubspot_owner_id) WHERE hubspot_owner_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_companies_cnpj ON companies(cnpj) WHERE cnpj IS NOT NULL;

-- Índice para busca por texto completa (português)
CREATE INDEX IF NOT EXISTS idx_companies_fulltext ON companies 
USING gin(to_tsvector('portuguese', 
    COALESCE(name,'') || ' ' || 
    COALESCE(domain,'') || ' ' || 
    COALESCE(description,'') || ' ' || 
    COALESCE(industry,'')
));

-- View para estatísticas de preenchimento (seguindo padrão)
CREATE OR REPLACE VIEW v_companies_stats AS
SELECT 
    COUNT(*) as total_companies,
    
    -- Campos básicos
    COUNT(domain) as companies_with_domain,
    ROUND((COUNT(domain)::numeric / COUNT(*)) * 100, 1) as domain_percentage,
    
    COUNT(website) as companies_with_website,
    ROUND((COUNT(website)::numeric / COUNT(*)) * 100, 1) as website_percentage,
    
    COUNT(phone) as companies_with_phone,
    ROUND((COUNT(phone)::numeric / COUNT(*)) * 100, 1) as phone_percentage,
    
    COUNT(industry) as companies_with_industry,
    ROUND((COUNT(industry)::numeric / COUNT(*)) * 100, 1) as industry_percentage,
    
    COUNT(numberofemployees) as companies_with_employees,
    ROUND((COUNT(numberofemployees)::numeric / COUNT(*)) * 100, 1) as employees_percentage,
    
    COUNT(annualrevenue) as companies_with_revenue,
    ROUND((COUNT(annualrevenue)::numeric / COUNT(*)) * 100, 1) as revenue_percentage,
    
    -- Específicos Logcomex
    COUNT(cnpj) as companies_with_cnpj,
    ROUND((COUNT(cnpj)::numeric / COUNT(*)) * 100, 1) as cnpj_percentage,
    
    -- Status
    COUNT(lifecyclestage) as companies_with_lifecycle,
    ROUND((COUNT(lifecyclestage)::numeric / COUNT(*)) * 100, 1) as lifecycle_percentage,
    
    -- Metadados
    MAX(last_sync_date) as last_sync,
    COUNT(CASE WHEN sync_status = 'active' THEN 1 END) as active_companies,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as error_companies
FROM companies;

-- View para empresas por lifecycle stage (padrão HubSpot)
CREATE OR REPLACE VIEW v_companies_by_lifecycle AS
SELECT 
    lifecyclestage,
    COUNT(*) as total_companies,
    ROUND((COUNT(*)::numeric / (SELECT COUNT(*) FROM companies)) * 100, 1) as percentage
FROM companies 
WHERE lifecyclestage IS NOT NULL
GROUP BY lifecyclestage
ORDER BY total_companies DESC;

-- View para empresas por indústria
CREATE OR REPLACE VIEW v_companies_by_industry AS
SELECT 
    industry,
    COUNT(*) as total_companies,
    ROUND((COUNT(*)::numeric / (SELECT COUNT(*) FROM companies)) * 100, 1) as percentage
FROM companies 
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY total_companies DESC;

-- View para empresas por porte
CREATE OR REPLACE VIEW v_companies_by_size AS
SELECT 
    CASE 
        WHEN numberofemployees IS NULL THEN 'Não informado'
        WHEN numberofemployees <= 10 THEN 'Micro (1-10)'
        WHEN numberofemployees <= 50 THEN 'Pequena (11-50)'
        WHEN numberofemployees <= 200 THEN 'Média (51-200)'
        WHEN numberofemployees <= 500 THEN 'Grande (201-500)'
        ELSE 'Muito Grande (500+)'
    END as company_size,
    COUNT(*) as total_companies,
    ROUND((COUNT(*)::numeric / (SELECT COUNT(*) FROM companies)) * 100, 1) as percentage
FROM companies 
GROUP BY 
    CASE 
        WHEN numberofemployees IS NULL THEN 'Não informado'
        WHEN numberofemployees <= 10 THEN 'Micro (1-10)'
        WHEN numberofemployees <= 50 THEN 'Pequena (11-50)'
        WHEN numberofemployees <= 200 THEN 'Média (51-200)'
        WHEN numberofemployees <= 500 THEN 'Grande (201-500)'
        ELSE 'Muito Grande (500+)'
    END
ORDER BY total_companies DESC;

-- Comentários seguindo padrão das outras tabelas
COMMENT ON TABLE companies IS 'Empresas sincronizadas do HubSpot - Segue padrão das outras tabelas (companies, deals, owners, contacts)';
COMMENT ON COLUMN companies.name IS 'Nome da empresa - campo obrigatório';
COMMENT ON COLUMN companies.domain IS 'Domínio da empresa para identificação';
COMMENT ON COLUMN companies.website IS 'Website da empresa';
COMMENT ON COLUMN companies.cnpj IS 'CNPJ da empresa (formato: XX.XXX.XXX/XXXX-XX)';
COMMENT ON COLUMN companies.lifecyclestage IS 'Estágio do lifecycle da empresa no HubSpot';
COMMENT ON VIEW v_companies_stats IS 'Estatísticas de preenchimento das empresas';
COMMENT ON VIEW v_companies_by_lifecycle IS 'Distribuição de empresas por estágio do lifecycle';
COMMENT ON VIEW v_companies_by_industry IS 'Distribuição de empresas por indústria';
COMMENT ON VIEW v_companies_by_size IS 'Distribuição de empresas por porte (número de funcionários)';

-- Função para atualizar timestamp de sincronização
CREATE OR REPLACE FUNCTION update_company_sync_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_sync_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar automaticamente o timestamp
CREATE TRIGGER trg_update_company_sync_timestamp
    BEFORE UPDATE ON companies
    FOR EACH ROW
    EXECUTE FUNCTION update_company_sync_timestamp();
