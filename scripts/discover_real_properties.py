#!/usr/bin/env python3
"""
Descobrir os nomes EXATOS das propriedades do HubSpot da Logcomex
Baseado no que vemos na interface mostrada pelo usuário
"""

import os
import requests
import json
from dotenv import load_dotenv
from collections import defaultdict

# Carregar .env
load_dotenv()

HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')

def discover_real_properties():
    print("🔍 DESCOBRINDO PROPRIEDADES REAIS DO HUBSPOT LOGCOMEX")
    print("=" * 60)
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    # 1. Buscar contatos especificando TODAS as propriedades possíveis
    print("📱 Buscando contatos com propriedades específicas de telefone...")
    
    # Propriedades que provavelmente existem baseado na interface
    suspected_properties = [
        # Básicas
        'email', 'firstname', 'lastname', 
        'createdate', 'lastmodifieddate', 'hs_object_id',
        
        # Telefones - várias possibilidades de nome
        'phone', 'mobilephone', 'celular', 'numero_de_celular',
        'numero_celular', 'telefone', 'numero_telefone', 'numero_de_telefone',
        'whatsapp', 'numero_whatsapp', 'numero_de_telefone_do_whatsapp',
        'telefone_whatsapp', 'whatsapp_phone', 'phone_whatsapp',
        
        # Outros campos comuns
        'company', 'jobtitle', 'cargo', 'website', 'city', 'state', 'country',
        'address', 'zip', 'lifecyclestage', 'hs_lead_status',
        
        # Campos específicos da Logcomex que vimos antes
        'atendimento_ativo_por', 'buscador_ncm', 'cnpj_da_empresa_pesquisada',
        'codigo_do_voucher', 'como_realizam_o_acompanhamento_hoje_'
    ]
    
    # Construir URL com propriedades específicas
    properties_param = ','.join(suspected_properties)
    
    try:
        # Buscar com propriedades específicas
        url = f'https://api.hubapi.com/crm/v3/objects/contacts?limit=50&properties={properties_param}'
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            contacts = response.json()['results']
            print(f"✅ Analisando {len(contacts)} contatos com propriedades específicas")
            
            # Analisar o que realmente tem dados
            properties_with_data = defaultdict(list)
            
            for contact in contacts:
                props = contact.get('properties', {})
                for prop_name, prop_value in props.items():
                    if prop_value is not None and prop_value != '':
                        properties_with_data[prop_name].append(prop_value)
            
            print(f"\n📊 PROPRIEDADES ENCONTRADAS COM DADOS:")
            sorted_props = sorted(properties_with_data.items(), key=lambda x: len(x[1]), reverse=True)
            
            for prop_name, values in sorted_props:
                percentage = (len(values) / len(contacts)) * 100
                unique_count = len(set(values))
                print(f"   • {prop_name}: {len(values)} contatos ({percentage:.1f}%) - {unique_count} valores únicos")
                
                # Mostrar amostras dos dados
                if prop_name in ['phone', 'mobilephone', 'celular', 'numero_de_celular', 'telefone', 'whatsapp'] or 'telefone' in prop_name.lower() or 'phone' in prop_name.lower():
                    samples = list(set(values))[:3]
                    print(f"      Amostras: {samples}")
            
            # Salvar resultado detalhado
            with open('hubspot_propriedades_REAIS.json', 'w', encoding='utf-8') as f:
                json.dump({
                    'total_contatos_analisados': len(contacts),
                    'propriedades_com_dados': len(properties_with_data),
                    'detalhes_propriedades': {
                        prop_name: {
                            'total_preenchidos': len(values),
                            'percentual': round((len(values) / len(contacts)) * 100, 2),
                            'valores_unicos': len(set(values)),
                            'amostras': list(set(values))[:5]
                        }
                        for prop_name, values in sorted_props
                    }
                }, f, indent=2, ensure_ascii=False)
            
            print(f"\n💾 Relatório detalhado salvo em: hubspot_propriedades_REAIS.json")
            
        else:
            print(f"❌ Erro: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Erro: {e}")
    
    # 2. Buscar TODAS as propriedades disponíveis e filtrar por telefone
    print(f"\n🔍 Buscando TODAS as propriedades disponíveis...")
    
    try:
        response = requests.get(
            'https://api.hubapi.com/crm/v3/properties/contacts',
            headers=headers
        )
        
        if response.status_code == 200:
            all_properties = response.json()['results']
            
            # Filtrar propriedades que podem ser telefone/celular
            phone_properties = []
            for prop in all_properties:
                name = prop.get('name', '').lower()
                label = prop.get('label', '').lower()
                
                if any(keyword in name or keyword in label for keyword in [
                    'phone', 'telefone', 'celular', 'whatsapp', 'mobile', 'cell'
                ]):
                    phone_properties.append({
                        'name': prop.get('name'),
                        'label': prop.get('label'),
                        'type': prop.get('type'),
                        'description': prop.get('description', '')
                    })
            
            print(f"\n📱 PROPRIEDADES RELACIONADAS A TELEFONE ENCONTRADAS:")
            for prop in phone_properties:
                print(f"   • {prop['name']} - '{prop['label']}' ({prop['type']})")
                if prop['description']:
                    print(f"     Descrição: {prop['description']}")
            
            # Salvar lista de propriedades de telefone
            with open('hubspot_telefone_properties.json', 'w', encoding='utf-8') as f:
                json.dump(phone_properties, f, indent=2, ensure_ascii=False)
            
            print(f"\n💾 Propriedades de telefone salvas em: hubspot_telefone_properties.json")
            
        else:
            print(f"❌ Erro ao buscar propriedades: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Erro ao buscar propriedades: {e}")

if __name__ == "__main__":
    discover_real_properties()
