-- Tabela para logs de monitoramento da sincronização HubSpot
CREATE TABLE IF NOT EXISTS sync_monitoring_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    alert_level VARCHAR(20) NOT NULL CHECK (alert_level IN ('info', 'warning', 'critical')),
    total_contatos INTEGER NOT NULL DEFAULT 0,
    contatos_erro INTEGER NOT NULL DEFAULT 0,
    ultima_sincronizacao TIMESTAMP WITH TIME ZONE,
    alertas JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_monitoring_timestamp ON sync_monitoring_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_monitoring_alert_level ON sync_monitoring_log(alert_level);
CREATE INDEX IF NOT EXISTS idx_monitoring_created_at ON sync_monitoring_log(created_at);

-- Comentários
COMMENT ON TABLE sync_monitoring_log IS 'Log de monitoramento da sincronização HubSpot → PostgreSQL';
COMMENT ON COLUMN sync_monitoring_log.alert_level IS 'Nível do alerta: info, warning, critical';
COMMENT ON COLUMN sync_monitoring_log.alertas IS 'Array JSON com as mensagens de alerta detectadas';

-- View para facilitar consultas de monitoramento
CREATE OR REPLACE VIEW v_sync_monitoring_summary AS
SELECT 
    DATE(created_at) as data,
    COUNT(*) as total_execucoes,
    COUNT(CASE WHEN alert_level = 'warning' THEN 1 END) as warnings,
    COUNT(CASE WHEN alert_level = 'critical' THEN 1 END) as critical_alerts,
    AVG(total_contatos) as media_contatos,
    AVG(contatos_erro) as media_erros,
    MAX(created_at) as ultima_execucao
FROM sync_monitoring_log 
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY data DESC;

COMMENT ON VIEW v_sync_monitoring_summary IS 'Resumo diário do monitoramento de sincronização';
