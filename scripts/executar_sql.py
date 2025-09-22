#!/usr/bin/env python3
"""
Executar arquivos SQL no PostgreSQL
"""

import os
import sys
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

def executar_sql(arquivo_sql):
    """Executar arquivo SQL no PostgreSQL"""
    
    print(f"🚀 EXECUTANDO: {arquivo_sql}")
    print("=" * 50)
    
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
        
        # Ler arquivo SQL
        print(f"📄 Lendo arquivo: {arquivo_sql}")
        with open(arquivo_sql, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Executar SQL
        print("⚡ Executando SQL...")
        cursor.execute(sql_content)
        conn.commit()
        print("✅ SQL executado com sucesso!")
        
        cursor.close()
        conn.close()
        
        print(f"🎉 {arquivo_sql} executado com sucesso!")
        return True
        
    except Exception as e:
        print(f"❌ ERRO ao executar {arquivo_sql}: {e}")
        return False

def main():
    """Função principal"""
    
    if len(sys.argv) != 2:
        print("❌ Uso: python executar_sql.py <arquivo.sql>")
        return False
    
    arquivo_sql = sys.argv[1]
    
    if not os.path.exists(arquivo_sql):
        print(f"❌ Arquivo não encontrado: {arquivo_sql}")
        return False
    
    return executar_sql(arquivo_sql)

if __name__ == "__main__":
    exit(0 if main() else 1)

