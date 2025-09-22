-- ==========================================
-- 🗑️ TRUNCAR TABELA CONTACTS ATUAL
-- ==========================================

-- Verificar registros atuais
SELECT COUNT(*) as total_registros FROM contacts;

-- Truncar tabela (remove todos os dados)
TRUNCATE TABLE contacts RESTART IDENTITY CASCADE;

-- Verificar se foi truncada
SELECT COUNT(*) as registros_apos_truncate FROM contacts;

-- Verificar estrutura atual
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'contacts' 
ORDER BY ordinal_position;

