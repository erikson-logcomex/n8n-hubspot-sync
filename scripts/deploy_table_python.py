#!/usr/bin/env python3
"""
Deploy da tabela contacts usando Python
"""

import os
import sys
import psycopg2

# Credenciais diretas (do .env)
PG_HOST = "35.239.64.56"
PG_PORT = "5432"
PG_DATABASE = "hubspot-sync"
PG_USER = "meetrox_user"
PG_PASSWORD = ":NZ%A{%Yi$3\p=mC"

def deploy_table():
    print("🚀 CRIANDO TABELA CONTACTS NO BANCO HUBSPOT-SYNC")
    print("=" * 50)
    
    try:
        # Conectar
        print("🐘 Conectando ao banco...")
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        
        cursor = conn.cursor()
        print("✅ Conexão estabelecida!")
        
        # Ler arquivo SQL
        print("📄 Lendo arquivo SQL...")
        with open('hubspot_contacts_table_PADRAO_CORRETO.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Executar SQL
        print("⚡ Executando SQL...")
        cursor.execute(sql_content)
        conn.commit()
        print("✅ SQL executado com sucesso!")
        
        # Verificar se tabela foi criada
        print("🔍 Verificando tabela criada...")
        cursor.execute("""
            SELECT table_name, column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'contacts' 
            ORDER BY ordinal_position 
            LIMIT 10;
        """)
        columns = cursor.fetchall()
        
        print(f"📊 Primeiras 10 colunas da tabela 'contacts':")
        for col in columns:
            print(f"   • {col[1]} ({col[2]})")
        
        # Contar total de colunas
        cursor.execute("""
            SELECT COUNT(*) 
            FROM information_schema.columns 
            WHERE table_name = 'contacts';
        """)
        total_cols = cursor.fetchone()[0]
        print(f"📈 Total de colunas criadas: {total_cols}")
        
        # Verificar views criadas
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.views 
            WHERE table_name LIKE 'v_contacts%';
        """)
        views = cursor.fetchall()
        print(f"📊 Views criadas: {len(views)}")
        for view in views:
            print(f"   • {view[0]}")
        
        cursor.close()
        conn.close()
        
        print("\n🎉 DEPLOY CONCLUÍDO COM SUCESSO!")
        print("📋 Próximos passos:")
        print("   1. Importar workflow: n8n_workflow_hubspot_sync_PADRAO_CORRETO.json")
        print("   2. Configurar credenciais no n8n")
        print("   3. Executar primeira sincronização")
        
        return True
        
    except Exception as e:
        print(f"\n❌ ERRO no deploy: {e}")
        return False

if __name__ == "__main__":
    deploy_table()
