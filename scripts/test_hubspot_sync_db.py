#!/usr/bin/env python3
"""
Teste de conexão com banco hubspot-sync correto
"""

import os
import psycopg2
from dotenv import load_dotenv

# Carregar .env
load_dotenv()

def test_hubspot_sync_db():
    print("🐘 TESTANDO CONEXÃO COM BANCO HUBSPOT-SYNC")
    print("=" * 50)
    
    # Credenciais do .env
    host = os.getenv('PG_HOST')
    port = os.getenv('PG_PORT') 
    database = os.getenv('PG_DATABASE')
    user = os.getenv('PG_USER')
    password = os.getenv('PG_PASSWORD')
    
    print(f"Host: {host}")
    print(f"Port: {port}")
    print(f"Database: {database}")
    print(f"User: {user}")
    
    try:
        # Conectar
        conn = psycopg2.connect(
            host=host,
            port=port,
            database=database,
            user=user,
            password=password
        )
        
        cursor = conn.cursor()
        
        # Testar conexão
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"\n✅ Conexão SUCESSO!")
        print(f"Versão PostgreSQL: {version}")
        
        # Verificar esquemas
        cursor.execute("SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;")
        schemas = cursor.fetchall()
        print(f"\n📂 Esquemas disponíveis:")
        for schema in schemas:
            print(f"   • {schema[0]}")
        
        # Verificar tabelas existentes no public
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f"\n📋 Tabelas no esquema 'public':")
        for table in tables:
            print(f"   • {table[0]}")
        
        # Verificar se tabela contacts já existe
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'contacts'
            );
        """)
        table_exists = cursor.fetchone()[0]
        
        if table_exists:
            print(f"\n⚠️  Tabela 'contacts' JÁ EXISTE")
            
            # Verificar quantos registros
            cursor.execute("SELECT COUNT(*) FROM contacts;")
            count = cursor.fetchone()[0]
            print(f"   📊 Registros existentes: {count}")
            
            # Verificar últimas atualizações
            cursor.execute("SELECT MAX(last_sync_date) FROM contacts;")
            last_sync = cursor.fetchone()[0]
            print(f"   🕐 Última sincronização: {last_sync}")
            
        else:
            print(f"\n✅ Tabela 'contacts' NÃO EXISTE (pronta para criação)")
        
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"\n❌ Erro na conexão: {e}")
        return False

if __name__ == "__main__":
    test_hubspot_sync_db()
