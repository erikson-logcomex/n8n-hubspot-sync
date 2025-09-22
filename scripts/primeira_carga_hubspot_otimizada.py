#!/usr/bin/env python3
"""
🚀 PRIMEIRA CARGA HUBSPOT OTIMIZADA
Baseada na análise real de 50 contatos do HubSpot
"""

import requests
import psycopg2
import time
import os
from dotenv import load_dotenv
import logging
import json
from datetime import datetime

# ==========================================
# ⚙️ CONFIGURAÇÕES
# ==========================================

# Carregar variáveis de ambiente
load_dotenv()

# Configurações do HubSpot
HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')

# Configurações do PostgreSQL
PG_HOST = os.getenv('PG_HOST')
PG_PORT = os.getenv('PG_PORT')
PG_DATABASE = os.getenv('PG_DATABASE')
PG_USER = os.getenv('PG_USER')
PG_PASSWORD = os.getenv('PG_PASSWORD')

# ⚙️ CONFIGURAÇÕES DE PERFORMANCE
DELAY_BETWEEN_REQUESTS = 2.0  # 2 segundos entre requests
MAX_RETRIES = 3               # Máximo de tentativas
CONTACTS_PER_REQUEST = 100    # Contatos por request

# 🎯 PROPRIEDADES OTIMIZADAS (baseadas na análise real)
HUBSPOT_PROPERTIES = [
    # Dados pessoais (100% preenchidos)
    'firstname', 'lastname', 'email',
    
    # Dados empresariais (100% preenchidos)
    'company', 'jobtitle', 'website',
    
    # Telefones (98% phone, 38% mobile)
    'phone', 'mobilephone',
    
    # Endereço (menos usado, mas importante)
    'address', 'city', 'state', 'zip', 'country',
    
    # Dados HubSpot (100% preenchidos)
    'lifecyclestage', 'hs_lead_status',
    
    # Datas (100% preenchidos)
    'createdate', 'lastmodifieddate',
    
    # Código voucher (80% preenchidos)
    'codigo_do_voucher',
    
    # Owner (se aplicável)
    'hubspot_owner_id'
]

# ==========================================
# 📝 LOGGING
# ==========================================

def setup_logging():
    """Configurar logging detalhado"""
    
    # Criar pasta logs se não existir
    os.makedirs('logs', exist_ok=True)
    
    # Nome do arquivo de log
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f'logs/primeira_carga_otimizada_{timestamp}.log'
    
    # Configurar logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_filename, encoding='utf-8'),
            logging.StreamHandler()
        ]
    )
    
    logger = logging.getLogger(__name__)
    logger.info("🚀 INICIANDO PRIMEIRA CARGA HUBSPOT OTIMIZADA")
    logger.info(f"📄 Log salvo em: {log_filename}")
    
    return logger

# ==========================================
# 🔄 FUNÇÕES DE API HUBSPOT
# ==========================================

def make_hubspot_request(url, headers, params, logger, retry_count=0):
    """Fazer request para API do HubSpot com retry"""
    
    try:
        # Rate limiting
        time.sleep(DELAY_BETWEEN_REQUESTS)
        
        response = requests.get(url, headers=headers, params=params, timeout=30)
        
        if response.status_code == 200:
            return response.json()
        
        elif response.status_code == 429:  # Rate limit
            retry_after = int(response.headers.get('Retry-After', 10))
            logger.warning(f"⚠️ Rate limit atingido. Aguardando {retry_after}s...")
            time.sleep(retry_after)
            
            if retry_count < MAX_RETRIES:
                return make_hubspot_request(url, headers, params, logger, retry_count + 1)
            else:
                logger.error("❌ Máximo de tentativas atingido para rate limit")
                return None
        
        else:
            logger.error(f"❌ Erro na API: {response.status_code} - {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Erro de conexão: {e}")
        if retry_count < MAX_RETRIES:
            time.sleep(5)
            return make_hubspot_request(url, headers, params, logger, retry_count + 1)
        return None

def fetch_all_hubspot_contacts(logger):
    """Buscar todos os contatos do HubSpot com paginação"""
    
    url = "https://api.hubapi.com/crm/v3/objects/contacts"
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    all_contacts = []
    page = 1
    after_token = None
    
    logger.info(f"🔍 Buscando contatos do HubSpot...")
    logger.info(f"📋 Propriedades: {len(HUBSPOT_PROPERTIES)}")
    logger.info(f"⏱️ Delay entre requests: {DELAY_BETWEEN_REQUESTS}s")
    
    while True:
        params = {
            'limit': CONTACTS_PER_REQUEST,
            'properties': HUBSPOT_PROPERTIES
        }
        
        if after_token:
            params['after'] = after_token
        
        logger.info(f"📄 Página {page} - Buscando até {CONTACTS_PER_REQUEST} contatos...")
        
        data = make_hubspot_request(url, headers, params, logger)
        
        if not data:
            logger.error("❌ Falha ao buscar dados do HubSpot")
            break
        
        contacts = data.get('results', [])
        if not contacts:
            logger.info("✅ Nenhum contato encontrado. Busca completa!")
            break
        
        all_contacts.extend(contacts)
        logger.info(f"✅ Página {page}: {len(contacts)} contatos. Total: {len(all_contacts)}")
        
        # Verificar se há mais páginas
        paging = data.get('paging', {})
        next_page = paging.get('next', {})
        after_token = next_page.get('after')
        
        if not after_token:
            logger.info("✅ Última página alcançada. Busca completa!")
            break
        
        page += 1
    
    logger.info(f"🎉 Busca completa! Total de contatos: {len(all_contacts)}")
    return all_contacts

# ==========================================
# 🗄️ FUNÇÕES POSTGRESQL
# ==========================================

def get_db_connection(logger):
    """Conectar ao PostgreSQL"""
    
    try:
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        logger.info("✅ Conectado ao PostgreSQL com sucesso")
        return conn
    except Exception as e:
        logger.error(f"❌ Erro ao conectar ao PostgreSQL: {e}")
        return None

def clean_value(value, max_length=None):
    """Limpar e validar valor"""
    
    if value is None or value == '':
        return None
    
    if isinstance(value, str):
        value = value.strip()
        if max_length and len(value) > max_length:
            value = value[:max_length]
    
    return value

def convert_timestamp(timestamp_str):
    """Converter timestamp do HubSpot para PostgreSQL"""
    
    if not timestamp_str:
        return None
    
    try:
        # Converter timestamp do HubSpot (ISO 8601) para PostgreSQL
        dt = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        return None

def prepare_contact_data(contact):
    """Preparar dados do contato para inserção"""
    
    properties = contact.get('properties', {})
    
    # Mapear propriedades para colunas da tabela otimizada
    contact_data = {
        'hs_object_id': properties.get('hs_object_id'),
        'firstname': clean_value(properties.get('firstname'), 300),
        'lastname': clean_value(properties.get('lastname'), 300),
        'email': clean_value(properties.get('email'), 255),
        'company': clean_value(properties.get('company'), 500),
        'jobtitle': clean_value(properties.get('jobtitle'), 500),
        'website': clean_value(properties.get('website'), 500),
        'phone': clean_value(properties.get('phone'), 100),
        'mobilephone': clean_value(properties.get('mobilephone'), 100),
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
        'hubspot_owner_id': properties.get('hubspot_owner_id'),
        'hubspot_raw_data': json.dumps(contact)
    }
    
    return contact_data

def save_contacts_to_db(contacts, logger):
    """Salvar contatos no PostgreSQL usando UPSERT"""
    
    conn = get_db_connection(logger)
    if not conn:
        return 0
    
    cursor = conn.cursor()
    saved_count = 0
    
    try:
        # SQL UPSERT otimizado
        upsert_sql = """
        INSERT INTO contacts (
            hs_object_id, firstname, lastname, email, company, jobtitle, website,
            phone, mobilephone, address, city, state, zip, country,
            lifecyclestage, hs_lead_status, createdate, lastmodifieddate,
            codigo_do_voucher, hubspot_owner_id, hubspot_raw_data
        ) VALUES (
            %(hs_object_id)s, %(firstname)s, %(lastname)s, %(email)s, %(company)s, 
            %(jobtitle)s, %(website)s, %(phone)s, %(mobilephone)s, %(address)s, 
            %(city)s, %(state)s, %(zip)s, %(country)s, %(lifecyclestage)s, 
            %(hs_lead_status)s, %(createdate)s, %(lastmodifieddate)s, 
            %(codigo_do_voucher)s, %(hubspot_owner_id)s, %(hubspot_raw_data)s
        )
        ON CONFLICT (hs_object_id) 
        DO UPDATE SET
            firstname = EXCLUDED.firstname,
            lastname = EXCLUDED.lastname,
            email = EXCLUDED.email,
            company = EXCLUDED.company,
            jobtitle = EXCLUDED.jobtitle,
            website = EXCLUDED.website,
            phone = EXCLUDED.phone,
            mobilephone = EXCLUDED.mobilephone,
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
            hubspot_raw_data = EXCLUDED.hubspot_raw_data,
            updated_at = CURRENT_TIMESTAMP
        """
        
        logger.info(f"💾 Salvando {len(contacts)} contatos no PostgreSQL...")
        
        for i, contact in enumerate(contacts):
            try:
                contact_data = prepare_contact_data(contact)
                cursor.execute(upsert_sql, contact_data)
                saved_count += 1
                
                # Log de progresso a cada 1000 contatos
                if (i + 1) % 1000 == 0:
                    logger.info(f"💾 Salvos {i + 1}/{len(contacts)} contatos...")
                    conn.commit()
                    
            except Exception as e:
                logger.error(f"❌ Erro ao salvar contato {contact_data.get('hs_object_id')}: {e}")
                continue
        
        # Commit final
        conn.commit()
        logger.info(f"✅ Salvamento completo! {saved_count} contatos salvos")
        
    except Exception as e:
        logger.error(f"❌ Erro crítico no salvamento: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()
    
    return saved_count

# ==========================================
# 🚀 MAIN FUNCTION
# ==========================================

def main():
    """Função principal"""
    logger = setup_logging()
    
    try:
        # Validar variáveis de ambiente
        if not all([HUBSPOT_TOKEN, PG_HOST, PG_DATABASE, PG_USER, PG_PASSWORD]):
            raise Exception("❌ Variáveis de ambiente faltando! Verifique o arquivo .env")
        
        logger.info("🔧 Configurações:")
        logger.info(f"   ⏱️  Delay entre requests: {DELAY_BETWEEN_REQUESTS}s")
        logger.info(f"   🔄 Max retries: {MAX_RETRIES}")
        logger.info(f"   📊 Contatos por request: {CONTACTS_PER_REQUEST}")
        logger.info(f"   📋 Propriedades: {len(HUBSPOT_PROPERTIES)}")
        
        # Buscar contatos do HubSpot
        start_time = time.time()
        contacts = fetch_all_hubspot_contacts(logger)
        fetch_time = time.time() - start_time
        
        logger.info(f"⏱️ Tempo de busca no HubSpot: {fetch_time:.2f}s ({fetch_time/60:.1f} min)")
        
        if not contacts:
            logger.warning("⚠️ Nenhum contato encontrado no HubSpot!")
            return
        
        # Salvar no PostgreSQL
        save_start = time.time()
        saved_count = save_contacts_to_db(contacts, logger)
        save_time = time.time() - save_start
        
        logger.info(f"⏱️ Tempo de salvamento no PostgreSQL: {save_time:.2f}s ({save_time/60:.1f} min)")
        
        # Estatísticas finais
        total_time = time.time() - start_time
        logger.info("🎉 PRIMEIRA CARGA OTIMIZADA COMPLETA!")
        logger.info(f"📊 Contatos processados: {len(contacts)}")
        logger.info(f"💾 Contatos salvos: {saved_count}")
        logger.info(f"⏱️ Tempo total: {total_time:.2f}s ({total_time/60:.1f} min)")
        logger.info(f"📈 Velocidade média: {len(contacts)/(total_time/60):.1f} contatos/min")
        
    except Exception as e:
        logger.error(f"❌ ERRO CRÍTICO: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())

