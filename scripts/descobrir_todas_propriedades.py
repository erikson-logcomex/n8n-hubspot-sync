#!/usr/bin/env python3
"""
Descobrir TODAS as propriedades disponíveis no HubSpot
"""

import requests
import time
import os
from dotenv import load_dotenv
import json
from datetime import datetime

# Carregar variáveis de ambiente
load_dotenv()

# Configurações
HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')
DELAY_BETWEEN_REQUESTS = 1.0

def make_hubspot_request(url, headers, params, retry_count=0):
    """Fazer request para API do HubSpot com retry"""
    
    try:
        time.sleep(DELAY_BETWEEN_REQUESTS)
        response = requests.get(url, headers=headers, params=params, timeout=30)
        
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 429:  # Rate limit
            retry_after = int(response.headers.get('Retry-After', 10))
            print(f"⚠️ Rate limit. Aguardando {retry_after}s...")
            time.sleep(retry_after)
            
            if retry_count < 3:
                return make_hubspot_request(url, headers, params, retry_count + 1)
            else:
                print("❌ Máximo de tentativas atingido")
                return None
        else:
            print(f"❌ Erro na API: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        if retry_count < 3:
            time.sleep(5)
            return make_hubspot_request(url, headers, params, retry_count + 1)
        return None

def descobrir_todas_propriedades():
    """Descobrir todas as propriedades disponíveis"""
    
    print("🔍 DESCOBRINDO TODAS AS PROPRIEDADES DO HUBSPOT")
    print("=" * 60)
    
    # 1. Buscar propriedades do schema
    print("📋 1. Buscando propriedades do schema...")
    url_schema = "https://api.hubapi.com/crm/v3/properties/contacts"
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    params_schema = {
        'limit': 1000  # Máximo de propriedades
    }
    
    schema_data = make_hubspot_request(url_schema, headers, params_schema)
    
    if not schema_data:
        print("❌ Falha ao buscar schema")
        return
    
    propriedades_schema = []
    for prop in schema_data.get('results', []):
        propriedades_schema.append({
            'name': prop.get('name'),
            'label': prop.get('label'),
            'type': prop.get('type'),
            'groupName': prop.get('groupName'),
            'description': prop.get('description')
        })
    
    print(f"✅ Schema: {len(propriedades_schema)} propriedades encontradas")
    
    # 2. Buscar alguns contatos para ver propriedades com dados
    print("\n📊 2. Analisando propriedades com dados reais...")
    url_contacts = "https://api.hubapi.com/crm/v3/objects/contacts"
    
    # Primeiro, buscar sem especificar propriedades para ver o que vem
    params_contacts = {
        'limit': 10  # Poucos contatos para análise rápida
    }
    
    contacts_data = make_hubspot_request(url_contacts, headers, params_contacts)
    
    if not contacts_data:
        print("❌ Falha ao buscar contatos")
        return
    
    # Analisar propriedades que vêm nos contatos
    propriedades_com_dados = set()
    for contact in contacts_data.get('results', []):
        properties = contact.get('properties', {})
        for prop_name in properties.keys():
            propriedades_com_dados.add(prop_name)
    
    print(f"✅ Contatos: {len(propriedades_com_dados)} propriedades com dados encontradas")
    
    # 3. Comparar e mostrar resultados
    print("\n🎯 ANÁLISE COMPLETA:")
    print("=" * 60)
    
    # Propriedades do schema
    print(f"\n📋 PROPRIEDADES DO SCHEMA ({len(propriedades_schema)}):")
    print("-" * 60)
    
    for i, prop in enumerate(propriedades_schema[:20], 1):  # Primeiras 20
        print(f"{i:2d}. {prop['name']:35s} | {prop['label']:30s} | {prop['type']:15s} | {prop['groupName']}")
    
    if len(propriedades_schema) > 20:
        print(f"   ... e mais {len(propriedades_schema) - 20} propriedades")
    
    # Propriedades com dados
    print(f"\n📊 PROPRIEDADES COM DADOS ({len(propriedades_com_dados)}):")
    print("-" * 60)
    
    for i, prop_name in enumerate(sorted(propriedades_com_dados)[:20], 1):  # Primeiras 20
        print(f"{i:2d}. {prop_name}")
    
    if len(propriedades_com_dados) > 20:
        print(f"   ... e mais {len(propriedades_com_dados) - 20} propriedades")
    
    # 4. Salvar resultados
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"analysis/todas_propriedades_{timestamp}.json"
    
    os.makedirs('analysis', exist_ok=True)
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'schema_properties': propriedades_schema,
            'data_properties': list(propriedades_com_dados),
            'total_schema': len(propriedades_schema),
            'total_with_data': len(propriedades_com_dados)
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Resultados salvos em: {filename}")
    
    # 5. Recomendações
    print("\n🎯 RECOMENDAÇÕES:")
    print("-" * 60)
    print("❌ PROBLEMA IDENTIFICADO: Nossa análise anterior estava incompleta!")
    print("✅ SOLUÇÃO: Precisamos analisar TODAS as propriedades do schema")
    print("🚀 PRÓXIMO PASSO: Criar nova análise com todas as propriedades")
    
    return propriedades_schema, propriedades_com_dados

if __name__ == "__main__":
    descobrir_todas_propriedades()

