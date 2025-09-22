#!/usr/bin/env python3
"""
Verificar se 'company' é uma propriedade simples ou se devemos usar associations
"""

import requests
import os
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')

def check_company_field():
    print("🔍 VERIFICANDO CAMPO 'COMPANY' NO HUBSPOT")
    print("=" * 50)
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    # 1. Buscar propriedades do Contact para ver se 'company' existe
    print("📋 Verificando propriedades de Contact...")
    try:
        response = requests.get(
            'https://api.hubapi.com/crm/v3/properties/contacts',
            headers=headers
        )
        
        if response.status_code == 200:
            properties = response.json()['results']
            company_props = [p for p in properties if 'company' in p.get('name', '').lower()]
            
            print(f"🔎 Propriedades relacionadas a 'company':")
            for prop in company_props:
                print(f"   • {prop['name']} - '{prop['label']}' ({prop['type']})")
        
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    # 2. Buscar um contato com associations
    print(f"\n📱 Verificando associations de um contato...")
    try:
        # Buscar um contato
        response = requests.get(
            'https://api.hubapi.com/crm/v3/objects/contacts?limit=1&properties=email,firstname',
            headers=headers
        )
        
        if response.status_code == 200:
            contacts = response.json()['results']
            if contacts:
                contact_id = contacts[0]['id']
                print(f"   Testando contato ID: {contact_id}")
                
                # Buscar associations deste contato
                assoc_response = requests.get(
                    f'https://api.hubapi.com/crm/v4/objects/contacts/{contact_id}/associations/companies',
                    headers=headers
                )
                
                if assoc_response.status_code == 200:
                    associations = assoc_response.json()
                    print(f"✅ Associations encontradas: {len(associations.get('results', []))}")
                    
                    if associations.get('results'):
                        print("🏢 Este contato TEM associations com companies!")
                        for assoc in associations['results'][:3]:
                            company_id = assoc.get('toObjectId')
                            print(f"   • Company ID: {company_id}")
                    else:
                        print("⚠️  Este contato NÃO tem associations com companies")
                else:
                    print(f"❌ Erro ao buscar associations: {assoc_response.status_code}")
        
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    # 3. Conclusão
    print(f"\n💡 RECOMENDAÇÃO:")
    print("Se você já tem tabela 'companies' com 16K registros,")
    print("provavelmente deve usar ASSOCIATIONS em vez de campo 'company'")

if __name__ == "__main__":
    check_company_field()
