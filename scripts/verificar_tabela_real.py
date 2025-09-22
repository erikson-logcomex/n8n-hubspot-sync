#!/usr/bin/env python3
"""
Script para verificar EXATAMENTE quais campos existem na tabela contacts
"""

import psycopg2
import os
from dotenv import load_dotenv
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Carregar variáveis de ambiente
load_dotenv()

# Configurações do banco
PG_HOST = os.getenv('PG_HOST')
PG_PORT = os.getenv('PG_PORT')
PG_DATABASE = os.getenv('PG_DATABASE')
PG_USER = os.getenv('PG_USER')
PG_PASSWORD = os.getenv('PG_PASSWORD')

def verificar_tabela():
    """Verifica exatamente quais campos existem na tabela contacts"""
    
    logging.info("🔍 VERIFICANDO TABELA CONTACTS - CAMPOS REAIS")
    
    try:
        # Conectar ao PostgreSQL
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        cursor = conn.cursor()
        logging.info("✅ Conectado ao PostgreSQL")
        
        # Verificar estrutura da tabela
        cursor.execute("""
            SELECT column_name, data_type, character_maximum_length, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'contacts' 
            ORDER BY ordinal_position
        """)
        
        columns = cursor.fetchall()
        
        logging.info("📋 ESTRUTURA DA TABELA CONTACTS:")
        logging.info("=" * 80)
        
        campos_existentes = []
        for col in columns:
            nome = col[0]
            tipo = col[1]
            tamanho = col[2] if col[2] else 'N/A'
            nullable = col[3]
            
            campos_existentes.append(nome)
            
            logging.info(f"📝 {nome:<25} | {tipo:<15} | Tamanho: {tamanho:<8} | Nullable: {nullable}")
        
        logging.info("=" * 80)
        logging.info(f"🎯 TOTAL DE CAMPOS: {len(campos_existentes)}")
        
        # Verificar constraints
        cursor.execute("""
            SELECT constraint_name, constraint_type
            FROM information_schema.table_constraints 
            WHERE table_name = 'contacts'
        """)
        
        constraints = cursor.fetchall()
        
        logging.info("🔒 CONSTRAINTS DA TABELA:")
        for const in constraints:
            logging.info(f"   {const[0]} - {const[1]}")
        
        # Verificar se tem dados
        cursor.execute("SELECT COUNT(*) FROM contacts")
        count = cursor.fetchone()[0]
        logging.info(f"📊 REGISTROS NA TABELA: {count}")
        
        return campos_existentes
        
    except Exception as e:
        logging.error(f"❌ ERRO: {e}")
        return []
    finally:
        if 'conn' in locals():
            cursor.close()
            conn.close()
            logging.info("🔌 Conexão fechada")

if __name__ == "__main__":
    verificar_tabela()

