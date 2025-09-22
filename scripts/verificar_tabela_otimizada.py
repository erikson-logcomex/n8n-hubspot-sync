#!/usr/bin/env python3
"""
Verificar se a tabela contacts otimizada foi criada corretamente
"""

import os
import psycopg2
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

# Configurações do PostgreSQL
PG_HOST = os.getenv('PG_HOST')
PG_PORT = os.getenv('PG_PORT')
PG_DATABASE = os.getenv('PG_DATABASE')
PG_USER = os.getenv('PG_USER')
PG_PASSWORD = os.getenv('PG_PASSWORD')

def verificar_tabela():
    """Verificar estrutura da tabela contacts"""
    
    print("🔍 VERIFICANDO TABELA CONTACTS OTIMIZADA")
    print("=" * 60)
    
    try:
        # Conectar ao PostgreSQL
        print("🐘 Conectando ao PostgreSQL...")
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        
        cursor = conn.cursor()
        print("✅ Conexão estabelecida!")
        
        # 1. Verificar se tabela existe
        print("\n📋 1. VERIFICANDO SE TABELA EXISTE:")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_name = 'contacts' AND table_schema = 'public';
        """)
        
        if cursor.fetchone():
            print("✅ Tabela 'contacts' existe!")
        else:
            print("❌ Tabela 'contacts' NÃO existe!")
            return False
        
        # 2. Verificar estrutura das colunas
        print("\n📊 2. ESTRUTURA DAS COLUNAS:")
        cursor.execute("""
            SELECT 
                column_name, 
                data_type, 
                character_maximum_length,
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_name = 'contacts' 
            ORDER BY ordinal_position;
        """)
        
        columns = cursor.fetchall()
        print(f"📈 Total de colunas: {len(columns)}")
        print("\n📝 Colunas encontradas:")
        
        for col in columns:
            col_name, data_type, max_length, nullable, default_val = col
            length_info = f"({max_length})" if max_length else ""
            nullable_info = "NULL" if nullable == "YES" else "NOT NULL"
            default_info = f" DEFAULT {default_val}" if default_val else ""
            
            print(f"   • {col_name}: {data_type}{length_info} {nullable_info}{default_info}")
        
        # 3. Verificar constraints
        print("\n🔒 3. CONSTRAINTS:")
        cursor.execute("""
            SELECT 
                constraint_name, 
                constraint_type
            FROM information_schema.table_constraints 
            WHERE table_name = 'contacts';
        """)
        
        constraints = cursor.fetchall()
        for constraint in constraints:
            print(f"   • {constraint[0]}: {constraint[1]}")
        
        # 4. Verificar índices
        print("\n🔍 4. ÍNDICES:")
        cursor.execute("""
            SELECT 
                indexname, 
                indexdef
            FROM pg_indexes 
            WHERE tablename = 'contacts'
            ORDER BY indexname;
        """)
        
        indexes = cursor.fetchall()
        for index in indexes:
            print(f"   • {index[0]}")
        
        # 5. Verificar views
        print("\n📊 5. VIEWS:")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.views 
            WHERE table_name LIKE 'v_contacts%';
        """)
        
        views = cursor.fetchall()
        for view in views:
            print(f"   • {view[0]}")
        
        # 6. Verificar registros
        print("\n📊 6. REGISTROS:")
        cursor.execute("SELECT COUNT(*) FROM contacts;")
        count = cursor.fetchone()[0]
        print(f"   • Total de registros: {count}")
        
        # 7. Verificar campos essenciais
        print("\n🎯 7. CAMPOS ESSENCIAIS (baseados na análise real):")
        campos_essenciais = [
            'hs_object_id', 'firstname', 'lastname', 'email',
            'company', 'jobtitle', 'website', 'phone', 'mobilephone',
            'address', 'city', 'state', 'zip', 'country',
            'lifecyclestage', 'hs_lead_status', 'createdate', 'lastmodifieddate',
            'codigo_do_voucher', 'hubspot_owner_id'
        ]
        
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'contacts';
        """)
        
        colunas_existentes = [row[0] for row in cursor.fetchall()]
        
        for campo in campos_essenciais:
            if campo in colunas_existentes:
                print(f"   ✅ {campo}")
            else:
                print(f"   ❌ {campo} - FALTANDO!")
        
        # 8. Verificar campos desnecessários (da tabela antiga)
        print("\n🗑️ 8. CAMPOS DESNECESSÁRIOS (não devem existir):")
        campos_desnecessarios = [
            'hs_whatsapp_phone_number', 'govcs_i_phone_number', 
            'atendimento_ativo_por', 'buscador_ncm', 'cnpj_da_empresa_pesquisada',
            'contato_por_whatsapp', 'criado_whatsapp', 'whatsapp_api',
            'whatsapp_error_spread_chat', 'hs_calculated_phone_number',
            'hs_calculated_mobile_number', 'hs_calculated_phone_number_country_code',
            'hs_calculated_phone_number_area_code', 'telefone_ravena_classificado__revops_',
            'celular1_gerador_de_personas', 'celular2_gerador_de_personas'
        ]
        
        for campo in campos_desnecessarios:
            if campo in colunas_existentes:
                print(f"   ❌ {campo} - AINDA EXISTE!")
            else:
                print(f"   ✅ {campo} - REMOVIDO CORRETAMENTE")
        
        cursor.close()
        conn.close()
        
        print("\n🎉 VERIFICAÇÃO CONCLUÍDA!")
        return True
        
    except Exception as e:
        print(f"❌ ERRO na verificação: {e}")
        return False

if __name__ == "__main__":
    verificar_tabela()

