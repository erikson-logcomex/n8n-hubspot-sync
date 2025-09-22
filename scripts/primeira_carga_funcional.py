#!/usr/bin/env python3
"""
🚀 PRIMEIRA CARGA HUBSPOT FUNCIONAL
Script que VAI FUNCIONAR com rate limiting conservador!
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

# ⚙️ CONFIGURAÇÕES DE PERFORMANCE CONSERVADORAS
DELAY_BETWEEN_REQUESTS = 3.0  # 3 segundos entre requests (mais conservador)
MAX_RETRIES = 5               # Máximo de tentativas para erros
CONTACTS_PER_REQUEST = 100    # Contatos por request
RETRY_DELAY = 10              # 10 segundos de espera antes de tentar novamente

# Propriedades completas da tabela final
PROPERTIES = [
    # Dados pessoais
    'firstname', 'lastname', 'email', 'full_name',
    
    # Dados empresariais
    'company', 'jobtitle', 'website',
    
    # Telefones
    'phone', 'mobilephone', 'govcs_i_phone_number', 
    'hs_calculated_phone_number', 'hs_calculated_phone_number_country_code',
    'hs_searchable_calculated_phone_number',
    
    # Endereço
    'address', 'city', 'state', 'zip', 'country',
    
    # Dados HubSpot
    'lifecyclestage', 'hs_lead_status',
    
    # Datas
    'createdate', 'lastmodifieddate',
    
    # Código voucher
    'codigo_do_voucher',
    
    # Owner
    'hubspot_owner_id',
    
    # WhatsApp
    'whatsapp_api', 'whatsapp_error_spread_chat',
    
    # Dados específicos da Logcomex
    'mkt_lifecycle_stage', 'mkt_business_unit', 'mkt_estrategia', 
    'mkt_em_negociacao', 'status_da_empresa', 'segmento_de_atuacao_',
    
    # Campos específicos que você viu na imagem
    'cargo_', 'departamento', 'classificacao_ravena',
    
    # Analytics
    'hs_analytics_num_visits', 'hs_analytics_num_page_views',
    'hs_analytics_first_timestamp', 'hs_analytics_source',
    'hs_latest_source', 'hs_latest_source_timestamp',
    
    # Scoring
    'hubspotscore', 'hs_predictivecontactscore_v2', 'hs_predictivescoringtier'
]

def main():
    print("🚀 INICIANDO PRIMEIRA CARGA FUNCIONAL")
    print(f"📊 Propriedades: {len(PROPERTIES)}")
    print(f"⏱️ Rate limiting: {DELAY_BETWEEN_REQUESTS}s entre requests")
    print(f"🔄 Max retries: {MAX_RETRIES}")
    print("💾 SALVAMENTO INCREMENTAL: Cada página é salva imediatamente!")
    
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
            'limit': CONTACTS_PER_REQUEST,
            'properties': PROPERTIES
        }
        if after_token:
            params['after'] = after_token
        
        # Retry logic para erros de API
        retry_count = 0
        response = None
        
        while retry_count < MAX_RETRIES:
            try:
                time.sleep(DELAY_BETWEEN_REQUESTS)  # Rate limiting mais conservador
                response = requests.get(url, headers=headers, params=params, timeout=30)
                
                if response.status_code == 200:
                    break  # Sucesso, sair do loop de retry
                elif response.status_code == 429:  # Rate limit exceeded
                    print(f"⚠️ Rate limit atingido na página {page}, aguardando {RETRY_DELAY}s...")
                    time.sleep(RETRY_DELAY)
                    retry_count += 1
                elif response.status_code >= 500:  # Erro do servidor
                    print(f"⚠️ Erro do servidor na página {page} (tentativa {retry_count + 1}/{MAX_RETRIES}): {response.status_code}")
                    if retry_count < MAX_RETRIES - 1:
                        time.sleep(RETRY_DELAY)
                        retry_count += 1
                    else:
                        print(f"❌ Erro persistente na página {page}: {response.status_code}")
                        break
                else:
                    print(f"❌ Erro página {page}: {response.status_code}")
                    break
            except Exception as e:
                print(f"⚠️ Erro de conexão na página {page} (tentativa {retry_count + 1}/{MAX_RETRIES}): {e}")
                if retry_count < MAX_RETRIES - 1:
                    time.sleep(RETRY_DELAY)
                    retry_count += 1
                else:
                    print(f"❌ Erro persistente na página {page}: {e}")
                    break
        
        if retry_count >= MAX_RETRIES or response is None or response.status_code != 200:
            print(f"❌ Máximo de tentativas excedido para página {page}")
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
            
            # Preparar dados completos
            contact_data = {
                'hs_object_id': clean_numeric(properties.get('hs_object_id')),
                'firstname': clean_value(properties.get('firstname'), 300),
                'lastname': clean_value(properties.get('lastname'), 300),
                'email': clean_value(properties.get('email'), 255),
                'full_name': clean_value(properties.get('full_name'), 500),
                'company': clean_value(properties.get('company'), 500),
                'jobtitle': clean_value(properties.get('jobtitle'), 500),
                'website': clean_value(properties.get('website'), 500),
                'phone': clean_value(properties.get('phone'), 100),
                'mobilephone': clean_value(properties.get('mobilephone'), 100),
                'govcs_i_phone_number': clean_value(properties.get('govcs_i_phone_number'), 100),
                'hs_calculated_phone_number': clean_value(properties.get('hs_calculated_phone_number'), 100),
                'hs_calculated_phone_number_country_code': clean_value(properties.get('hs_calculated_phone_number_country_code'), 10),
                'hs_searchable_calculated_phone_number': clean_value(properties.get('hs_searchable_calculated_phone_number'), 100),
                'address': clean_value(properties.get('address'), 1000),
                'city': clean_value(properties.get('city'), 300),
                'state': clean_value(properties.get('state'), 300),
                'zip': clean_value(properties.get('zip'), 50),
                'country': clean_value(properties.get('country'), 100),
                'lifecyclestage': clean_value(properties.get('lifecyclestage'), 100),
                'hs_lead_status': clean_value(properties.get('hs_lead_status'), 100),
                'createdate': convert_timestamp(properties.get('createdate')),
                'lastmodifieddate': convert_timestamp(properties.get('lastmodifieddate')),
                'codigo_do_voucher': clean_value(properties.get('codigo_do_voucher'), 200),
                'hubspot_owner_id': clean_numeric(properties.get('hubspot_owner_id')),
                'whatsapp_api': clean_value(properties.get('whatsapp_api'), 100),
                'whatsapp_error_spread_chat': clean_value(properties.get('whatsapp_error_spread_chat')),
                'mkt_lifecycle_stage': clean_value(properties.get('mkt_lifecycle_stage'), 100),
                'mkt_business_unit': clean_value(properties.get('mkt_business_unit'), 100),
                'mkt_estrategia': clean_value(properties.get('mkt_estrategia'), 100),
                'mkt_em_negociacao': clean_value(properties.get('mkt_em_negociacao'), 50),
                'status_da_empresa': clean_value(properties.get('status_da_empresa'), 100),
                'segmento_de_atuacao_': clean_value(properties.get('segmento_de_atuacao_'), 200),
                'cargo_': clean_value(properties.get('cargo_'), 200),
                'departamento': clean_value(properties.get('departamento'), 200),
                'classificacao_ravena': clean_value(properties.get('classificacao_ravena'), 200),
                'hs_analytics_num_visits': clean_numeric(properties.get('hs_analytics_num_visits')),
                'hs_analytics_num_page_views': clean_numeric(properties.get('hs_analytics_num_page_views')),
                'hs_analytics_first_timestamp': convert_timestamp(properties.get('hs_analytics_first_timestamp')),
                'hs_analytics_source': clean_value(properties.get('hs_analytics_source'), 100),
                'hs_latest_source': clean_value(properties.get('hs_latest_source'), 100),
                'hs_latest_source_timestamp': convert_timestamp(properties.get('hs_latest_source_timestamp')),
                'hubspotscore': clean_numeric(properties.get('hubspotscore')),
                'hs_predictivecontactscore_v2': clean_numeric(properties.get('hs_predictivecontactscore_v2')),
                'hs_predictivescoringtier': clean_value(properties.get('hs_predictivescoringtier'), 50),
                'hubspot_raw_data': json.dumps(contact)
            }
            
            # UPSERT completo
            sql = """
            INSERT INTO contacts (
                hs_object_id, firstname, lastname, email, full_name, company, jobtitle, website,
                phone, mobilephone, govcs_i_phone_number, hs_calculated_phone_number, 
                hs_calculated_phone_number_country_code, hs_searchable_calculated_phone_number,
                address, city, state, zip, country, lifecyclestage, hs_lead_status, 
                createdate, lastmodifieddate, codigo_do_voucher, hubspot_owner_id,
                whatsapp_api, whatsapp_error_spread_chat, mkt_lifecycle_stage, mkt_business_unit,
                mkt_estrategia, mkt_em_negociacao, status_da_empresa, segmento_de_atuacao_,
                cargo_, departamento, classificacao_ravena, hs_analytics_num_visits,
                hs_analytics_num_page_views, hs_analytics_first_timestamp, hs_analytics_source,
                hs_latest_source, hs_latest_source_timestamp, hubspotscore, 
                hs_predictivecontactscore_v2, hs_predictivescoringtier, hubspot_raw_data
            ) VALUES (
                %(hs_object_id)s, %(firstname)s, %(lastname)s, %(email)s, %(full_name)s,
                %(company)s, %(jobtitle)s, %(website)s, %(phone)s, %(mobilephone)s,
                %(govcs_i_phone_number)s, %(hs_calculated_phone_number)s, 
                %(hs_calculated_phone_number_country_code)s, %(hs_searchable_calculated_phone_number)s,
                %(address)s, %(city)s, %(state)s, %(zip)s, %(country)s, %(lifecyclestage)s,
                %(hs_lead_status)s, %(createdate)s, %(lastmodifieddate)s, %(codigo_do_voucher)s,
                %(hubspot_owner_id)s, %(whatsapp_api)s, %(whatsapp_error_spread_chat)s,
                %(mkt_lifecycle_stage)s, %(mkt_business_unit)s, %(mkt_estrategia)s,
                %(mkt_em_negociacao)s, %(status_da_empresa)s, %(segmento_de_atuacao_)s,
                %(cargo_)s, %(departamento)s, %(classificacao_ravena)s, %(hs_analytics_num_visits)s,
                %(hs_analytics_num_page_views)s, %(hs_analytics_first_timestamp)s, %(hs_analytics_source)s,
                %(hs_latest_source)s, %(hs_latest_source_timestamp)s, %(hubspotscore)s,
                %(hs_predictivecontactscore_v2)s, %(hs_predictivescoringtier)s, %(hubspot_raw_data)s
            )
            ON CONFLICT (hs_object_id) 
            DO UPDATE SET
                firstname = EXCLUDED.firstname,
                lastname = EXCLUDED.lastname,
                email = EXCLUDED.email,
                full_name = EXCLUDED.full_name,
                company = EXCLUDED.company,
                jobtitle = EXCLUDED.jobtitle,
                website = EXCLUDED.website,
                phone = EXCLUDED.phone,
                mobilephone = EXCLUDED.mobilephone,
                govcs_i_phone_number = EXCLUDED.govcs_i_phone_number,
                hs_calculated_phone_number = EXCLUDED.hs_calculated_phone_number,
                hs_calculated_phone_number_country_code = EXCLUDED.hs_calculated_phone_number_country_code,
                hs_searchable_calculated_phone_number = EXCLUDED.hs_searchable_calculated_phone_number,
                address = EXCLUDED.address,
                city = EXCLUDED.city,
                state = EXCLUDED.state,
                zip = EXCLUDED.zip,
                country = EXCLUDED.country,
                lifecyclestage = EXCLUDED.lifecyclestage,
                hs_lead_status = EXCLUDED.hs_lead_status,
                createdate = EXCLUDED.createdate,
                lastmodifieddate = EXCLUDED.lastmodifieddate,
                codigo_do_voucher = EXCLUDED.codigo_do_voucher,
                hubspot_owner_id = EXCLUDED.hubspot_owner_id,
                whatsapp_api = EXCLUDED.whatsapp_api,
                whatsapp_error_spread_chat = EXCLUDED.whatsapp_error_spread_chat,
                mkt_lifecycle_stage = EXCLUDED.mkt_lifecycle_stage,
                mkt_business_unit = EXCLUDED.mkt_business_unit,
                mkt_estrategia = EXCLUDED.mkt_estrategia,
                mkt_em_negociacao = EXCLUDED.mkt_em_negociacao,
                status_da_empresa = EXCLUDED.status_da_empresa,
                segmento_de_atuacao_ = EXCLUDED.segmento_de_atuacao_,
                cargo_ = EXCLUDED.cargo_,
                departamento = EXCLUDED.departamento,
                classificacao_ravena = EXCLUDED.classificacao_ravena,
                hs_analytics_num_visits = EXCLUDED.hs_analytics_num_visits,
                hs_analytics_num_page_views = EXCLUDED.hs_analytics_num_page_views,
                hs_analytics_first_timestamp = EXCLUDED.hs_analytics_first_timestamp,
                hs_analytics_source = EXCLUDED.hs_analytics_source,
                hs_latest_source = EXCLUDED.hs_latest_source,
                hs_latest_source_timestamp = EXCLUDED.hs_latest_source_timestamp,
                hubspotscore = EXCLUDED.hubspotscore,
                hs_predictivecontactscore_v2 = EXCLUDED.hs_predictivecontactscore_v2,
                hs_predictivescoringtier = EXCLUDED.hs_predictivescoringtier,
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

def clean_value(value, max_length=None):
    """Limpar e validar valor"""
    if value is None or value == '':
        return None
    
    if isinstance(value, str):
        value = value.strip()
        if value == '':
            return None
        if max_length and len(value) > max_length:
            value = value[:max_length]
    
    return value

def clean_numeric(value):
    """Limpar e converter valor numérico"""
    if value is None or value == '':
        return None
    
    if isinstance(value, str):
        value = value.strip()
        if value == '':
            return None
        try:
            # Tentar converter para float primeiro (para decimais como "0.81")
            float_val = float(value)
            # Se for inteiro, retornar como int
            if float_val.is_integer():
                return int(float_val)
            # Se não, retornar como float (será convertido para numeric no PostgreSQL)
            return float_val
        except (ValueError, TypeError):
            return None
    
    return value

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
