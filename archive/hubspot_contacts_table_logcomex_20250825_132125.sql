-- Tabela gerada automaticamente baseada na análise do HubSpot
CREATE TABLE IF NOT EXISTS hubspot_contacts_logcomex (
    id BIGINT PRIMARY KEY,
    createdate VARCHAR(50), -- Max length observed: 24, Samples: 500
    email VARCHAR(72), -- Max length observed: 36, Samples: 432
    firstname VARCHAR(50), -- Max length observed: 9, Samples: 500
    hs_object_id INTEGER, -- Max length observed: 5, Samples: 500
    lastmodifieddate VARCHAR(50), -- Max length observed: 24, Samples: 500
    lastname VARCHAR(50), -- Max length observed: 14, Samples: 274
    
    -- Metadados de sincronização
    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'active',
    hubspot_raw_data JSONB
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_email ON hubspot_contacts_logcomex(email);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_company ON hubspot_contacts_logcomex(company);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastmodified ON hubspot_contacts_logcomex(lastmodifieddate);
CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_sync_date ON hubspot_contacts_logcomex(last_sync_date);