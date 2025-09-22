#!/usr/bin/env python3
"""
Script para analisar propriedades dos contatos do HubSpot
Descobrir nomes internos das propriedades para replicar no PostgreSQL
"""

import os
import requests
import json
from dotenv import load_dotenv
from collections import defaultdict
import psycopg2
from datetime import datetime

# Carregar variáveis do .env
load_dotenv()

# Configurações do HubSpot
HUBSPOT_TOKEN = os.getenv('HUBSPOT_PRIVATE_APP_TOKEN')
HUBSPOT_BASE_URL = 'https://api.hubapi.com'

# Configurações do PostgreSQL (banco hubspot-sync)
PG_HOST = os.getenv('PG_HOST')
PG_PORT = os.getenv('PG_PORT')
PG_DATABASE = os.getenv('PG_DATABASE')  # hubspot-sync
PG_USER = os.getenv('PG_USER')
PG_PASSWORD = os.getenv('PG_PASSWORD')

def test_hubspot_connection():
    """Testa conexão com HubSpot"""
    print("🔍 Testando conexão com HubSpot...")
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    try:
        # Teste de conexão básico
        response = requests.get(
            f'{HUBSPOT_BASE_URL}/crm/v3/objects/contacts?limit=1',
            headers=headers
        )
        
        if response.status_code == 200:
            print("✅ Conexão com HubSpot: SUCESSO")
            return True
        else:
            print(f"❌ Erro na conexão HubSpot: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro na conexão HubSpot: {str(e)}")
        return False

def get_hubspot_contact_properties():
    """Busca todas as propriedades disponíveis para contatos"""
    print("\n📋 Buscando propriedades disponíveis no HubSpot...")
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    try:
        # Buscar definições de propriedades
        response = requests.get(
            f'{HUBSPOT_BASE_URL}/crm/v3/properties/contacts',
            headers=headers
        )
        
        if response.status_code == 200:
            properties = response.json()['results']
            print(f"✅ Encontradas {len(properties)} propriedades disponíveis")
            
            # Organizar propriedades por tipo
            prop_analysis = {
                'string': [],
                'number': [],
                'datetime': [],
                'enumeration': [],
                'bool': [],
                'other': []
            }
            
            for prop in properties:
                prop_type = prop.get('type', 'other')
                prop_name = prop.get('name', '')
                prop_label = prop.get('label', '')
                
                prop_info = {
                    'name': prop_name,
                    'label': prop_label,
                    'type': prop_type,
                    'description': prop.get('description', ''),
                    'calculated': prop.get('calculated', False)
                }
                
                if prop_type in prop_analysis:
                    prop_analysis[prop_type].append(prop_info)
                else:
                    prop_analysis['other'].append(prop_info)
            
            return prop_analysis
            
        else:
            print(f"❌ Erro ao buscar propriedades: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Erro ao buscar propriedades: {str(e)}")
        return None

def get_sample_contacts():
    """Busca contatos de exemplo para analisar dados reais"""
    print("\n👥 Buscando contatos de exemplo (amostra grande)...")
    
    headers = {
        'Authorization': f'Bearer {HUBSPOT_TOKEN}',
        'Content-Type': 'application/json'
    }
    
    all_contacts = []
    properties_with_data = defaultdict(list)
    
    try:
        # Buscar múltiplas páginas para ter amostra maior
        limit = 100  # Máximo por request
        total_desired = 500  # Total desejado
        after = None
        
        while len(all_contacts) < total_desired:
            url = f'{HUBSPOT_BASE_URL}/crm/v3/objects/contacts?limit={limit}&archived=false'
            if after:
                url += f'&after={after}'
                
            print(f"   Buscando página... ({len(all_contacts)} contatos coletados)")
            
            response = requests.get(url, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                contacts = data.get('results', [])
                all_contacts.extend(contacts)
                
                # Analisar propriedades desta página
                for contact in contacts:
                    props = contact.get('properties', {})
                    for prop_name, prop_value in props.items():
                        if prop_value is not None and prop_value != '':
                            properties_with_data[prop_name].append(prop_value)
                
                # Verificar se há próxima página
                paging = data.get('paging', {})
                if 'next' in paging:
                    after = paging['next']['after']
                else:
                    break
            else:
                print(f"   Erro na página: {response.status_code}")
                break
        
        print(f"✅ Coletados {len(all_contacts)} contatos para análise")
        return all_contacts, properties_with_data
            
    except Exception as e:
        print(f"❌ Erro ao buscar contatos: {str(e)}")
        return None, None

def test_postgresql_connection():
    """Testa conexão com PostgreSQL"""
    print("\n🐘 Testando conexão com PostgreSQL...")
    
    try:
        conn = psycopg2.connect(
            host=PG_HOST,
            port=PG_PORT,
            database=PG_DATABASE,
            user=PG_USER,
            password=PG_PASSWORD
        )
        
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✅ Conexão PostgreSQL: SUCESSO")
        print(f"   Versão: {version}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Erro na conexão PostgreSQL: {str(e)}")
        return False

def analyze_data_types(properties_with_data):
    """Analisa tipos de dados baseado nos valores reais"""
    print("\n🔍 Analisando tipos de dados baseado em valores reais...")
    
    type_suggestions = {}
    
    for prop_name, values in properties_with_data.items():
        sample_values = values[:5]  # Primeiros 5 valores
        
        # Tentar determinar tipo baseado nos dados
        suggested_type = 'TEXT'
        max_length = 0
        
        for value in sample_values:
            str_value = str(value)
            max_length = max(max_length, len(str_value))
            
            # Verificar se é número
            try:
                if '.' in str_value:
                    float(str_value)
                    suggested_type = 'DECIMAL(15,2)'
                else:
                    int(str_value)
                    suggested_type = 'INTEGER'
                continue
            except ValueError:
                pass
            
            # Verificar se é data/timestamp
            if any(keyword in str_value.lower() for keyword in ['t', 'z', '-']) and len(str_value) > 10:
                try:
                    # Tentar parsear como timestamp
                    if str_value.isdigit() and len(str_value) >= 10:
                        # Timestamp em milissegundos
                        suggested_type = 'TIMESTAMP WITH TIME ZONE'
                    elif 'T' in str_value or '-' in str_value:
                        suggested_type = 'TIMESTAMP WITH TIME ZONE'
                except:
                    pass
            
            # Se chegou até aqui, provavelmente é texto
            if max_length > 255:
                suggested_type = 'TEXT'
            elif max_length > 100:
                suggested_type = 'VARCHAR(255)'
            else:
                suggested_type = f'VARCHAR({max(max_length * 2, 50)})'
        
        type_suggestions[prop_name] = {
            'suggested_type': suggested_type,
            'max_length': max_length,
            'sample_values': sample_values[:3],
            'total_samples': len(values)
        }
    
    return type_suggestions

def generate_table_sql(properties_analysis, type_suggestions):
    """Gera SQL para criar tabela baseada na análise"""
    print("\n📄 Gerando estrutura de tabela SQL...")
    
    # Propriedades essenciais que sempre incluir
    essential_props = [
        'id', 'email', 'firstname', 'lastname', 'phone', 'company',
        'createdate', 'lastmodifieddate', 'hs_object_id'
    ]
    
    sql_parts = []
    sql_parts.append("-- Tabela gerada automaticamente baseada na análise do HubSpot")
    sql_parts.append("CREATE TABLE IF NOT EXISTS hubspot_contacts_logcomex (")
    
    # ID sempre primeiro
    sql_parts.append("    id BIGINT PRIMARY KEY,")
    
    # Adicionar propriedades com dados
    added_props = set(['id'])
    
    for prop_name, analysis in type_suggestions.items():
        if prop_name not in added_props:
            pg_type = analysis['suggested_type']
            comment = f"-- Max length observed: {analysis['max_length']}, Samples: {analysis['total_samples']}"
            sql_parts.append(f"    {prop_name} {pg_type}, {comment}")
            added_props.add(prop_name)
    
    # Metadados de controle
    sql_parts.append("    ")
    sql_parts.append("    -- Metadados de sincronização")
    sql_parts.append("    last_sync_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,")
    sql_parts.append("    sync_status VARCHAR(20) DEFAULT 'active',")
    sql_parts.append("    hubspot_raw_data JSONB")
    
    sql_parts.append(");")
    
    # Índices
    sql_parts.append("")
    sql_parts.append("-- Índices para performance")
    sql_parts.append("CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_email ON hubspot_contacts_logcomex(email);")
    sql_parts.append("CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_company ON hubspot_contacts_logcomex(company);")
    sql_parts.append("CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_lastmodified ON hubspot_contacts_logcomex(lastmodifieddate);")
    sql_parts.append("CREATE INDEX IF NOT EXISTS idx_hubspot_contacts_sync_date ON hubspot_contacts_logcomex(last_sync_date);")
    
    return '\n'.join(sql_parts)

def save_analysis_report(properties_analysis, type_suggestions, contacts_sample):
    """Salva relatório completo da análise"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"hubspot_analysis_report_{timestamp}.json"
    
    report = {
        'timestamp': datetime.now().isoformat(),
        'hubspot_properties_count': sum(len(props) for props in properties_analysis.values()),
        'properties_with_data_count': len(type_suggestions),
        'contacts_analyzed': len(contacts_sample) if contacts_sample else 0,
        'properties_by_type': {
            prop_type: len(props) for prop_type, props in properties_analysis.items()
        },
        'properties_analysis': properties_analysis,
        'type_suggestions': type_suggestions,
        'sample_contacts': contacts_sample[:2] if contacts_sample else []  # Apenas 2 primeiros para exemplo
    }
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False, default=str)
    
    print(f"\n💾 Relatório salvo em: {filename}")
    return filename

def main():
    """Função principal"""
    print("🚀 ANÁLISE DE PROPRIEDADES HUBSPOT → POSTGRESQL")
    print("=" * 50)
    
    # 1. Testar conexões
    hubspot_ok = test_hubspot_connection()
    postgres_ok = test_postgresql_connection()
    
    if not hubspot_ok:
        print("\n❌ Conexão com HubSpot falhou. Verifique o token no .env")
        return
    
    if not postgres_ok:
        print("\n⚠️  Conexão com PostgreSQL falhou. Verifique as credenciais no .env")
        print("   (Continuando apenas com análise do HubSpot)")
    
    # 2. Buscar propriedades disponíveis
    properties_analysis = get_hubspot_contact_properties()
    if not properties_analysis:
        print("\n❌ Não foi possível buscar propriedades do HubSpot")
        return
    
    # 3. Buscar contatos de exemplo
    contacts_sample, properties_with_data = get_sample_contacts()
    if not contacts_sample:
        print("\n❌ Não foi possível buscar contatos de exemplo")
        return
    
    # 4. Analisar tipos de dados
    type_suggestions = analyze_data_types(properties_with_data)
    
    # 5. Gerar SQL da tabela
    table_sql = generate_table_sql(properties_analysis, type_suggestions)
    
    # 6. Salvar relatório
    report_file = save_analysis_report(properties_analysis, type_suggestions, contacts_sample)
    
    # 7. Salvar SQL gerado
    sql_filename = f"hubspot_contacts_table_logcomex_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
    with open(sql_filename, 'w', encoding='utf-8') as f:
        f.write(table_sql)
    
    # 8. Exibir resumo
    print("\n" + "=" * 50)
    print("📊 RESUMO DA ANÁLISE")
    print("=" * 50)
    print(f"✅ Propriedades totais no HubSpot: {sum(len(props) for props in properties_analysis.values())}")
    print(f"✅ Propriedades com dados reais: {len(properties_with_data)}")
    print(f"✅ Contatos analisados: {len(contacts_sample)}")
    print(f"\n📁 Arquivos gerados:")
    print(f"   • {report_file} (relatório completo)")
    print(f"   • {sql_filename} (estrutura da tabela)")
    
    print(f"\n🔝 TOP 20 PROPRIEDADES COM MAIS DADOS:")
    sorted_props = sorted(properties_with_data.items(), key=lambda x: len(x[1]), reverse=True)
    for prop_name, values in sorted_props[:20]:
        percentage = (len(values) / len(contacts_sample)) * 100 if contacts_sample else 0
        print(f"   • {prop_name}: {len(values)} contatos ({percentage:.1f}%)")
    
    print(f"\n💡 PRÓXIMOS PASSOS:")
    print(f"   1. Revisar arquivo SQL gerado: {sql_filename}")
    print(f"   2. Ajustar tipos de dados se necessário")
    print(f"   3. Executar SQL no PostgreSQL")
    print(f"   4. Configurar workflows n8n com as propriedades identificadas")
    
    print(f"\n🎉 Análise concluída com sucesso!")

if __name__ == "__main__":
    main()
