#!/usr/bin/env python3
"""
Teste rápido de conexão com HubSpot e listagem de propriedades básicas
"""

import os
import requests
import json
from dotenv import load_dotenv

# Carregar .env
load_dotenv()

HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')

def quick_test():
    print("🚀 TESTE RÁPIDO - HUBSPOT API")
    print("=" * 40)
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    # 1. Testar conexão básica
    print("🔍 Testando conexão...")
    try:
        response = requests.get(
            'https://api.hubapi.com/crm/v3/objects/contacts?limit=1',
            headers=headers
        )
        
        if response.status_code == 200:
            print("✅ Conexão: SUCESSO")
        else:
            print(f"❌ Erro: {response.status_code} - {response.text}")
            return
            
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return
    
    # 2. Buscar 3 contatos de exemplo
    print("\n👥 Buscando contatos de exemplo...")
    try:
        response = requests.get(
            'https://api.hubapi.com/crm/v3/objects/contacts?limit=3',
            headers=headers
        )
        
        if response.status_code == 200:
            contacts = response.json()['results']
            print(f"✅ Encontrados {len(contacts)} contatos")
            
            # Mostrar propriedades do primeiro contato
            if contacts:
                first_contact = contacts[0]
                properties = first_contact.get('properties', {})
                
                print(f"\n📋 PROPRIEDADES DO PRIMEIRO CONTATO (ID: {first_contact.get('id')}):")
                print("-" * 50)
                
                for prop_name, prop_value in sorted(properties.items()):
                    if prop_value:  # Só mostrar propriedades com valor
                        value_preview = str(prop_value)[:50] + "..." if len(str(prop_value)) > 50 else str(prop_value)
                        print(f"  {prop_name}: {value_preview}")
                
                print(f"\n📊 Total de propriedades com dados: {len([p for p in properties.values() if p])}")
                print(f"📊 Total de propriedades vazias: {len([p for p in properties.values() if not p])}")
                
            else:
                print("⚠️  Nenhum contato encontrado")
                
        else:
            print(f"❌ Erro ao buscar contatos: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro ao buscar contatos: {e}")
    
    # 3. Listar propriedades mais comuns
    print(f"\n🔧 PROPRIEDADES MAIS COMUNS NO HUBSPOT:")
    common_props = [
        'email', 'firstname', 'lastname', 'phone', 'company', 'jobtitle',
        'website', 'address', 'city', 'state', 'country', 'zip',
        'createdate', 'lastmodifieddate', 'hs_lead_status', 'lifecyclestage'
    ]
    
    all_properties = set()
    for contact in contacts:
        all_properties.update(contact.get('properties', {}).keys())
    
    print("  Propriedades que vocês TÊM:")
    for prop in common_props:
        if prop in all_properties:
            print(f"    ✅ {prop}")
        else:
            print(f"    ❌ {prop} (não encontrado)")
    
    print(f"\n💡 Total de propriedades únicas encontradas: {len(all_properties)}")
    print("💡 Execute 'python test_hubspot_properties.py' para análise completa")

if __name__ == "__main__":
    quick_test()
