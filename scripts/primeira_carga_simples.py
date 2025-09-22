#!/usr/bin/env python3
"""
🚀 PRIMEIRA CARGA HUBSPOT SIMPLES
Versão simplificada que VAI FUNCIONAR!
"""

import requests
import psycopg2
import time
import os
from dotenv import load_dotenv
import json
from datetime import datetime

# Carregar variáveis de ambiente
load_dotenv()

# Configurações
HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')
PG_HOST = os.getenv('PG_HOST')
PG_PORT = os.getenv('PG_PORT')
PG_DATABASE = os.getenv('PG_DATABASE')
PG_USER = os.getenv('PG_USER')
PG_PASSWORD = os.getenv('PG_PASSWORD')

# Propriedades essenciais
PROPERTIES = [
    'firstname', 'lastname', 'email', 'company', 'jobtitle', 'phone',
    'lifecyclestage', 'createdate', 'lastmodifieddate', 'hs_object_id'
]

def main():
    print("🚀 INICIANDO PRIMEIRA CARGA SIMPLES")
    print(f"📊 Propriedades: {len(PROPERTIES)}")
    
    # Testar conexão com HubSpot
    print("🔍 Testando conexão com HubSpot...")
    url = "https://api.hubapi.com/crm/v3/objects/contacts"
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    params = {
        'limit': 10,
        'properties': PROPERTIES
    }
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        if response.status_code == 200:
            data = response.json()
            contacts = data.get('results', [])
            print(f"✅ HubSpot OK! {len(contacts)} contatos encontrados")
        else:
            print(f"❌ Erro HubSpot: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ Erro conexão HubSpot: {e}")
        return
    
    # Testar conexão com PostgreSQL
    print("🐘 Testando conexão com PostgreSQL...")
    try:
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM contacts")
        count = cursor.fetchone()[0]
        print(f"✅ PostgreSQL OK! {count} contatos na tabela")
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ Erro PostgreSQL: {e}")
        return
    
    # Buscar e salvar contatos
    print("📥 Buscando contatos do HubSpot...")
    total_saved = 0
    page = 1
    after_token = None
    
    while True:
        print(f"📄 Página {page}: Buscando...")
        
        params = {
            'limit': 100,
            'properties': PROPERTIES
        }
        if after_token:
            params['after'] = after_token
        
        try:
            time.sleep(1)  # Rate limiting
            response = requests.get(url, headers=headers, params=params, timeout=30)
            
            if response.status_code != 200:
                print(f"❌ Erro página {page}: {response.status_code}")
                break
            
            data = response.json()
            contacts = data.get('results', [])
            
            if not contacts:
                print("✅ Nenhum contato encontrado - fim")
                break
            
            # Salvar contatos
            print(f"💾 Salvando {len(contacts)} contatos...")
            saved = save_contacts(contacts)
            total_saved += saved
            
            print(f"✅ Página {page}: {len(contacts)} processados, {saved} salvos")
            print(f"📈 Total: {total_saved} contatos salvos")
            
            # Verificar próxima página
            paging = data.get('paging', {})
            next_page = paging.get('next', {})
            after_token = next_page.get('after')
            
            if not after_token:
                print("✅ Última página alcançada")
                break
            
            page += 1
            
        except Exception as e:
            print(f"❌ Erro página {page}: {e}")
            break
    
    print(f"🎉 PRIMEIRA CARGA COMPLETA!")
    print(f"📊 Total de contatos salvos: {total_saved}")

def save_contacts(contacts):
    """Salvar contatos no PostgreSQL"""
    
    conn = psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        database=PG_DATABASE,
        user=PG_USER,
        password=PG_PASSWORD
    )
    cursor = conn.cursor()
    saved = 0
    
    try:
        for contact in contacts:
            properties = contact.get('properties', {})
            
            # Preparar dados
            contact_data = {
                'hs_object_id': properties.get('hs_object_id'),
                'firstname': properties.get('firstname', '')[:300],
                'lastname': properties.get('lastname', '')[:300],
                'email': properties.get('email', '')[:255],
                'company': properties.get('company', '')[:500],
                'jobtitle': properties.get('jobtitle', '')[:500],
                'phone': properties.get('phone', '')[:100],
                'lifecyclestage': properties.get('lifecyclestage', '')[:100],
                'createdate': convert_timestamp(properties.get('createdate')),
                'lastmodifieddate': convert_timestamp(properties.get('lastmodifieddate')),
                'hubspot_raw_data': json.dumps(contact)
            }
            
            # UPSERT
            sql = """
            INSERT INTO contacts (
                hs_object_id, firstname, lastname, email, company, jobtitle, 
                phone, lifecyclestage, createdate, lastmodifieddate, hubspot_raw_data
            ) VALUES (
                %(hs_object_id)s, %(firstname)s, %(lastname)s, %(email)s, %(company)s,
                %(jobtitle)s, %(phone)s, %(lifecyclestage)s, %(createdate)s, 
                %(lastmodifieddate)s, %(hubspot_raw_data)s
            )
            ON CONFLICT (hs_object_id) 
            DO UPDATE SET
                firstname = EXCLUDED.firstname,
                lastname = EXCLUDED.lastname,
                email = EXCLUDED.email,
                company = EXCLUDED.company,
                jobtitle = EXCLUDED.jobtitle,
                phone = EXCLUDED.phone,
                lifecyclestage = EXCLUDED.lifecyclestage,
                createdate = EXCLUDED.createdate,
                lastmodifieddate = EXCLUDED.lastmodifieddate,
                hubspot_raw_data = EXCLUDED.hubspot_raw_data,
                updated_at = CURRENT_TIMESTAMP
            """
            
            cursor.execute(sql, contact_data)
            saved += 1
        
        conn.commit()
        
    except Exception as e:
        print(f"❌ Erro salvamento: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()
    
    return saved

def convert_timestamp(timestamp_str):
    """Converter timestamp"""
    if not timestamp_str:
        return None
    try:
        dt = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        return None

if __name__ == "__main__":
    main()

