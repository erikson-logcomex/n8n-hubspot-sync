#!/usr/bin/env python3
"""
Análise rápida com amostra média (100 contatos) do HubSpot da Logcomex
"""

import os
import requests
import json
from dotenv import load_dotenv
from collections import defaultdict

# Carregar .env
load_dotenv()

HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')

def quick_sample_analysis():
    print("🚀 ANÁLISE RÁPIDA - AMOSTRA DE 100 CONTATOS")
    print("=" * 50)
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    # Buscar 100 contatos
    print("👥 Buscando 100 contatos...")
    try:
        response = requests.get(
            'https://api.hubapi.com/crm/v3/objects/contacts?limit=100&archived=false',
            headers=headers
        )
        
        if response.status_code != 200:
            print(f"❌ Erro: {response.status_code} - {response.text}")
            return
            
        contacts = response.json()['results']
        print(f"✅ Analisando {len(contacts)} contatos")
        
        # Analisar propriedades
        properties_with_data = defaultdict(list)
        
        for contact in contacts:
            props = contact.get('properties', {})
            for prop_name, prop_value in props.items():
                if prop_value is not None and prop_value != '':
                    properties_with_data[prop_name].append(prop_value)
        
        # Mostrar estatísticas
        print(f"\n📊 ESTATÍSTICAS:")
        print(f"   • Total de contatos analisados: {len(contacts)}")
        print(f"   • Propriedades com dados: {len(properties_with_data)}")
        
        # Top propriedades
        print(f"\n🔝 TOP 15 PROPRIEDADES MAIS PREENCHIDAS:")
        sorted_props = sorted(properties_with_data.items(), key=lambda x: len(x[1]), reverse=True)
        
        important_props = []
        
        for prop_name, values in sorted_props[:15]:
            percentage = (len(values) / len(contacts)) * 100
            print(f"   • {prop_name}: {len(values)} contatos ({percentage:.1f}%)")
            
            if percentage >= 10:  # Propriedades com pelo menos 10% de preenchimento
                important_props.append(prop_name)
        
        # Mostrar amostras de dados importantes
        print(f"\n📋 AMOSTRAS DE DADOS DAS PROPRIEDADES PRINCIPAIS:")
        for prop_name in important_props[:10]:  # Top 10
            values = properties_with_data[prop_name]
            unique_samples = list(set(values))[:3]  # 3 amostras únicas
            max_len = max(len(str(v)) for v in values) if values else 0
            
            print(f"\n   🔸 {prop_name} (max: {max_len} chars)")
            for sample in unique_samples:
                sample_str = str(sample)[:50] + "..." if len(str(sample)) > 50 else str(sample)
                print(f"      └─ {sample_str}")
        
        # Gerar lista de propriedades recomendadas
        print(f"\n💡 PROPRIEDADES RECOMENDADAS PARA SINCRONIZAÇÃO:")
        recommended = [prop for prop, values in sorted_props if len(values) >= len(contacts) * 0.05]  # 5% ou mais
        
        print(f"   Campos com pelo menos 5% de preenchimento ({len(recommended)} propriedades):")
        for prop_name in recommended[:20]:  # Top 20
            count = len(properties_with_data[prop_name])
            percentage = (count / len(contacts)) * 100
            print(f"      ✅ {prop_name} ({percentage:.1f}%)")
        
        # Salvar lista de propriedades importantes
        with open('hubspot_propriedades_importantes.txt', 'w', encoding='utf-8') as f:
            f.write("# Propriedades HubSpot da Logcomex com dados\n")
            f.write(f"# Análise de {len(contacts)} contatos\n\n")
            
            for prop_name, values in sorted_props:
                percentage = (len(values) / len(contacts)) * 100
                if percentage >= 5:  # Pelo menos 5%
                    f.write(f"{prop_name}  # {len(values)} contatos ({percentage:.1f}%)\n")
        
        print(f"\n💾 Lista salva em: hubspot_propriedades_importantes.txt")
        print(f"🎉 Análise rápida concluída!")
        
    except Exception as e:
        print(f"❌ Erro na análise: {e}")

if __name__ == "__main__":
    quick_sample_analysis()
