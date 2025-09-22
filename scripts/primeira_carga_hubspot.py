#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🚀 PRIMEIRA CARGA HUBSPOT → POSTGRESQL
Script para buscar TODOS os contatos do HubSpot e salvar no PostgreSQL
com rate limiting adequado para não impactar outras integrações.
"""

import os
import sys
import time
import json
import requests
import psycopg2
from psycopg2.extras import execute_values
from datetime import datetime
import logging
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

# ==========================================
# 🔧 CONFIGURAÇÕES
# ==========================================

# Rate Limiting (ajuste conforme necessário)
DELAY_BETWEEN_REQUESTS = 2.0  # segundos entre requests (conservador)
MAX_RETRIES = 3              # tentativas em caso de erro
BACKOFF_MULTIPLIER = 2       # multiplicador para retry delay

# HubSpot API
HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')
HUBSPOT_API_URL = 'https://api.hubapi.com/crm/v3/objects/contacts'
CONTACTS_PER_REQUEST = 100   # máximo por request

# PostgreSQL
PG_HOST = os.getenv('PG_HOST')
PG_PORT = os.getenv('PG_PORT', 5432)
PG_DATABASE = os.getenv('PG_DATABASE')
PG_USER = os.getenv('PG_USER')
PG_PASSWORD = os.getenv('PG_PASSWORD')

# Propriedades a buscar (mesmas do workflow)
HUBSPOT_PROPERTIES = [
    'email', 'firstname', 'lastname', 'company', 'jobtitle', 'website',
    'phone', 'mobilephone', 'hs_whatsapp_phone_number', 'govcs_i_phone_number',
    'lifecyclestage', 'hs_lead_status', 'codigo_do_voucher', 'atendimento_ativo_por',
    'buscador_ncm', 'cnpj_da_empresa_pesquisada', 'contato_por_whatsapp',
    'criado_whatsapp', 'whatsapp_api', 'whatsapp_error_spread_chat',
    'hs_calculated_phone_number', 'hs_calculated_mobile_number',
    'hs_calculated_phone_number_country_code', 'hs_calculated_phone_number_area_code',
    'telefone_ravena_classificado__revops_', 'celular1_gerador_de_personas',
    'celular2_gerador_de_personas', 'address', 'city', 'state', 'zip', 'country',
    'createdate', 'lastmodifieddate', 'closedate', 'hs_lead_source',
    'hs_original_source', 'hs_original_source_data_1', 'hs_original_source_data_2',
    'hubspot_owner_id'
]

# ==========================================
# 🛠️ SETUP LOGGING
# ==========================================

def setup_logging():
    """Configurar logging detalhado"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_filename = f'logs/primeira_carga_hubspot_{timestamp}.log'
    
    # Criar diretório de logs se não existir
    os.makedirs('logs', exist_ok=True)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_filename, encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    logger = logging.getLogger(__name__)
    logger.info("🚀 Iniciando primeira carga HubSpot → PostgreSQL")
    logger.info(f"📝 Log salvo em: {log_filename}")
    
    return logger

# ==========================================
# 🌐 HUBSPOT API FUNCTIONS
# ==========================================

def make_hubspot_request(url, headers, params, logger, retry_count=0):
    """
    Fazer request para HubSpot API com rate limiting e retry logic
    """
    try:
        # Rate limiting - delay antes do request
        if retry_count == 0:  # Só delay normal no primeiro try
            time.sleep(DELAY_BETWEEN_REQUESTS)
        
        logger.debug(f"🌐 Request para: {url}")
        logger.debug(f"⏰ Delay aplicado: {DELAY_BETWEEN_REQUESTS}s")
        
        response = requests.get(url, headers=headers, params=params, timeout=30)
        
        # Rate limit hit (HTTP 429)
        if response.status_code == 429:
            retry_after = int(response.headers.get('Retry-After', 60))
            logger.warning(f"⚠️ Rate limit atingido! Aguardando {retry_after}s...")
            time.sleep(retry_after)
            
            if retry_count < MAX_RETRIES:
                return make_hubspot_request(url, headers, params, logger, retry_count + 1)
            else:
                raise Exception(f"Rate limit persistente após {MAX_RETRIES} tentativas")
        
        # Outros erros HTTP
        if response.status_code != 200:
            error_msg = f"Erro HTTP {response.status_code}: {response.text}"
            
            if retry_count < MAX_RETRIES:
                delay = DELAY_BETWEEN_REQUESTS * (BACKOFF_MULTIPLIER ** retry_count)
                logger.warning(f"⚠️ Erro na API. Tentativa {retry_count + 1}/{MAX_RETRIES}. Aguardando {delay}s...")
                time.sleep(delay)
                return make_hubspot_request(url, headers, params, logger, retry_count + 1)
            else:
                raise Exception(error_msg)
        
        return response.json()
        
    except requests.exceptions.Timeout:
        if retry_count < MAX_RETRIES:
            delay = DELAY_BETWEEN_REQUESTS * (BACKOFF_MULTIPLIER ** retry_count)
            logger.warning(f"⏰ Timeout na API. Tentativa {retry_count + 1}/{MAX_RETRIES}. Aguardando {delay}s...")
            time.sleep(delay)
            return make_hubspot_request(url, headers, params, logger, retry_count + 1)
        else:
            raise Exception(f"Timeout persistente após {MAX_RETRIES} tentativas")
    
    except Exception as e:
        if retry_count < MAX_RETRIES:
            delay = DELAY_BETWEEN_REQUESTS * (BACKOFF_MULTIPLIER ** retry_count)
            logger.warning(f"❌ Erro: {str(e)}. Tentativa {retry_count + 1}/{MAX_RETRIES}. Aguardando {delay}s...")
            time.sleep(delay)
            return make_hubspot_request(url, headers, params, logger, retry_count + 1)
        else:
            raise e

def fetch_all_hubspot_contacts(logger):
    """
    Buscar TODOS os contatos do HubSpot com paginação e rate limiting
    """
    logger.info("📡 Iniciando busca de contatos no HubSpot...")
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    params = {
        'limit': CONTACTS_PER_REQUEST,
        'properties': ','.join(HUBSPOT_PROPERTIES)
    }
    
    all_contacts = []
    after_token = None
    page_count = 0
    
    while True:
        page_count += 1
        
        # Adicionar token de paginação se existir
        if after_token:
            params['after'] = after_token
        elif 'after' in params:
            del params['after']
        
        logger.info(f"📄 Página {page_count} - Buscando até {CONTACTS_PER_REQUEST} contatos...")
        
        # Fazer request com rate limiting
        data = make_hubspot_request(HUBSPOT_API_URL, headers, params, logger)
        
        # Processar resultados
        contacts = data.get('results', [])
        if contacts:
            all_contacts.extend(contacts)
            logger.info(f"✅ Página {page_count}: {len(contacts)} contatos. Total: {len(all_contacts)}")
        else:
            logger.warning(f"⚠️ Página {page_count}: Nenhum contato retornado")
        
        # Verificar se há mais páginas
        paging = data.get('paging', {})
        after_token = paging.get('next', {}).get('after')
        
        if not after_token:
            logger.info(f"🎉 Busca completa! Total de páginas: {page_count}")
            break
    
    logger.info(f"📊 Total de contatos buscados: {len(all_contacts)}")
    return all_contacts

# ==========================================
# 🗄️ POSTGRESQL FUNCTIONS
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
        logger.info("🗄️ Conectado ao PostgreSQL com sucesso")
        return conn
    except Exception as e:
        logger.error(f"❌ Erro ao conectar PostgreSQL: {e}")
        raise e

def clean_value(value):
    """Limpar valores para PostgreSQL"""
    if value is None or value == '':
        return None
    
    if isinstance(value, str):
        # Limitar tamanho de strings
        if len(value) > 255:
            return value[:255]
        return value.strip()
    
    return value

def convert_timestamp(timestamp_str):
    """Converter timestamp do HubSpot para PostgreSQL"""
    if not timestamp_str:
        return None
    
    try:
        # HubSpot timestamp está em milliseconds
        if isinstance(timestamp_str, (int, float)):
            return datetime.fromtimestamp(timestamp_str / 1000)
        
        # Se for string, tentar converter
        if isinstance(timestamp_str, str):
            return datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        
        return None
    except:
        return None

def prepare_contact_data(contact):
    """Preparar dados do contato para inserção no PostgreSQL"""
    props = contact.get('properties', {})
    
    return (
        clean_value(contact.get('id')),  # id
        clean_value(contact.get('id')),  # hs_object_id
        clean_value(props.get('email')),
        clean_value(props.get('firstname')),
        clean_value(props.get('lastname')),
        clean_value(props.get('company')),
        clean_value(props.get('jobtitle')),
        clean_value(props.get('website')),
        clean_value(props.get('phone')),
        clean_value(props.get('mobilephone')),
        clean_value(props.get('hs_whatsapp_phone_number')),
        clean_value(props.get('govcs_i_phone_number')),
        clean_value(props.get('lifecyclestage')),
        clean_value(props.get('hs_lead_status')),
        clean_value(props.get('hubspot_owner_id')),
        clean_value(props.get('codigo_do_voucher')),
        clean_value(props.get('atendimento_ativo_por')),
        clean_value(props.get('buscador_ncm')),
        clean_value(props.get('cnpj_da_empresa_pesquisada')),
        clean_value(props.get('contato_por_whatsapp')),
        clean_value(props.get('criado_whatsapp')),
        clean_value(props.get('whatsapp_api')),
        clean_value(props.get('whatsapp_error_spread_chat')),
        clean_value(props.get('hs_calculated_phone_number')),
        clean_value(props.get('hs_calculated_mobile_number')),
        clean_value(props.get('hs_calculated_phone_number_country_code')),
        clean_value(props.get('hs_calculated_phone_number_area_code')),
        clean_value(props.get('telefone_ravena_classificado__revops_')),
        clean_value(props.get('celular1_gerador_de_personas')),
        clean_value(props.get('celular2_gerador_de_personas')),
        clean_value(props.get('address')),
        clean_value(props.get('city')),
        clean_value(props.get('state')),
        clean_value(props.get('zip')),
        clean_value(props.get('country')),
        convert_timestamp(props.get('createdate')),
        convert_timestamp(props.get('lastmodifieddate')),
        convert_timestamp(props.get('closedate')),
        clean_value(props.get('hs_lead_source')),
        clean_value(props.get('hs_original_source')),
        clean_value(props.get('hs_original_source_data_1')),
        clean_value(props.get('hs_original_source_data_2')),
        datetime.now(),  # last_sync_date
        'active',        # sync_status
        json.dumps(contact)  # hubspot_raw_data
    )

def save_contacts_to_db(contacts, logger):
    """Salvar contatos no PostgreSQL com UPSERT"""
    if not contacts:
        logger.warning("⚠️ Nenhum contato para salvar")
        return 0
    
    logger.info(f"💾 Salvando {len(contacts)} contatos no PostgreSQL...")
    
    conn = get_db_connection(logger)
    cursor = conn.cursor()
    
    try:
        # Preparar dados
        contact_data = [prepare_contact_data(contact) for contact in contacts]
        
        # SQL de UPSERT
        upsert_sql = """
        INSERT INTO contacts (
            id, hs_object_id, email, firstname, lastname, company, jobtitle, website,
            phone, mobilephone, hs_whatsapp_phone_number, govcs_i_phone_number,
            lifecyclestage, hs_lead_status, hubspot_owner_id, codigo_do_voucher,
            atendimento_ativo_por, buscador_ncm, cnpj_da_empresa_pesquisada,
            contato_por_whatsapp, criado_whatsapp, whatsapp_api, whatsapp_error_spread_chat,
            hs_calculated_phone_number, hs_calculated_mobile_number,
            hs_calculated_phone_number_country_code, hs_calculated_phone_number_area_code,
            telefone_ravena_classificado__revops_, celular1_gerador_de_personas,
            celular2_gerador_de_personas, address, city, state, zip, country,
            createdate, lastmodifieddate, closedate, hs_lead_source, hs_original_source,
            hs_original_source_data_1, hs_original_source_data_2, last_sync_date,
            sync_status, hubspot_raw_data
        ) VALUES %s
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            firstname = EXCLUDED.firstname,
            lastname = EXCLUDED.lastname,
            company = EXCLUDED.company,
            jobtitle = EXCLUDED.jobtitle,
            website = EXCLUDED.website,
            phone = EXCLUDED.phone,
            mobilephone = EXCLUDED.mobilephone,
            hs_whatsapp_phone_number = EXCLUDED.hs_whatsapp_phone_number,
            govcs_i_phone_number = EXCLUDED.govcs_i_phone_number,
            lifecyclestage = EXCLUDED.lifecyclestage,
            hs_lead_status = EXCLUDED.hs_lead_status,
            hubspot_owner_id = EXCLUDED.hubspot_owner_id,
            codigo_do_voucher = EXCLUDED.codigo_do_voucher,
            atendimento_ativo_por = EXCLUDED.atendimento_ativo_por,
            buscador_ncm = EXCLUDED.buscador_ncm,
            cnpj_da_empresa_pesquisada = EXCLUDED.cnpj_da_empresa_pesquisada,
            contato_por_whatsapp = EXCLUDED.contato_por_whatsapp,
            criado_whatsapp = EXCLUDED.criado_whatsapp,
            whatsapp_api = EXCLUDED.whatsapp_api,
            whatsapp_error_spread_chat = EXCLUDED.whatsapp_error_spread_chat,
            hs_calculated_phone_number = EXCLUDED.hs_calculated_phone_number,
            hs_calculated_mobile_number = EXCLUDED.hs_calculated_mobile_number,
            hs_calculated_phone_number_country_code = EXCLUDED.hs_calculated_phone_number_country_code,
            hs_calculated_phone_number_area_code = EXCLUDED.hs_calculated_phone_number_area_code,
            telefone_ravena_classificado__revops_ = EXCLUDED.telefone_ravena_classificado__revops_,
            celular1_gerador_de_personas = EXCLUDED.celular1_gerador_de_personas,
            celular2_gerador_de_personas = EXCLUDED.celular2_gerador_de_personas,
            address = EXCLUDED.address,
            city = EXCLUDED.city,
            state = EXCLUDED.state,
            zip = EXCLUDED.zip,
            country = EXCLUDED.country,
            createdate = EXCLUDED.createdate,
            lastmodifieddate = EXCLUDED.lastmodifieddate,
            closedate = EXCLUDED.closedate,
            hs_lead_source = EXCLUDED.hs_lead_source,
            hs_original_source = EXCLUDED.hs_original_source,
            hs_original_source_data_1 = EXCLUDED.hs_original_source_data_1,
            hs_original_source_data_2 = EXCLUDED.hs_original_source_data_2,
            last_sync_date = EXCLUDED.last_sync_date,
            sync_status = EXCLUDED.sync_status,
            hubspot_raw_data = EXCLUDED.hubspot_raw_data
        """
        
        # Executar UPSERT em batches de 1000
        batch_size = 1000
        total_saved = 0
        
        for i in range(0, len(contact_data), batch_size):
            batch = contact_data[i:i + batch_size]
            execute_values(cursor, upsert_sql, batch, template=None, page_size=batch_size)
            total_saved += len(batch)
            logger.info(f"💾 Salvos {total_saved}/{len(contact_data)} contatos...")
        
        conn.commit()
        logger.info(f"✅ {total_saved} contatos salvos com sucesso!")
        
        return total_saved
        
    except Exception as e:
        conn.rollback()
        logger.error(f"❌ Erro ao salvar contatos: {e}")
        raise e
    finally:
        cursor.close()
        conn.close()

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
        logger.info("🎉 PRIMEIRA CARGA COMPLETA!")
        logger.info(f"📊 Contatos processados: {len(contacts)}")
        logger.info(f"💾 Contatos salvos: {saved_count}")
        logger.info(f"⏱️ Tempo total: {total_time:.2f}s ({total_time/60:.1f} min)")
        logger.info(f"📈 Velocidade média: {len(contacts)/(total_time/60):.1f} contatos/min")
        
    except Exception as e:
        logger.error(f"❌ ERRO CRÍTICO: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

