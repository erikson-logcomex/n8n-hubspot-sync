-- DROP SCHEMA public;

CREATE SCHEMA public AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public IS 'standard public schema';

-- DROP SEQUENCE public.hubspot_properties_id_seq;

CREATE SEQUENCE public.hubspot_properties_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE public.sync_status_id_seq;

CREATE SEQUENCE public.sync_status_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 2147483647
	START 1
	CACHE 1
	NO CYCLE;-- public.association_company_contact definição

-- Drop table

-- DROP TABLE public.association_company_contact;

CREATE TABLE public.association_company_contact (
	company_id int8 NOT NULL,
	contact_id int8 NOT NULL,
	"label" text NULL,
	row_updatedat timestamp DEFAULT now() NULL,
	CONSTRAINT association_company_contact_pkey UNIQUE (company_id, contact_id)
);


-- public.association_company_deal definição

-- Drop table

-- DROP TABLE public.association_company_deal;

CREATE TABLE public.association_company_deal (
	company_id int8 NOT NULL,
	deal_id int8 NOT NULL,
	row_updatedat timestamp DEFAULT now() NOT NULL,
	"label" text NULL,
	CONSTRAINT association_company_deal_pkey UNIQUE (company_id, deal_id)
);


-- public.companies definição

-- Drop table

-- DROP TABLE public.companies;

CREATE TABLE public.companies (
	hs_object_id int8 NOT NULL,
	"name" text NULL,
	"domain" text NULL,
	cnpj text NULL,
	createdate timestamptz NULL,
	hs_lastmodifieddate timestamptz NULL,
	notes_last_updated timestamptz NULL,
	data_do_ultimo_periodo date NULL,
	segmento_1 text NULL,
	segmento_2 text NULL,
	segmento_3 text NULL,
	country text NULL,
	phone text NULL,
	lifecyclestage text NULL,
	status_da_empresa text NULL,
	faturamento_anual_ic text NULL,
	cnpj_situacao_cadastral_ic text NULL,
	cnae_id text NULL,
	cnae text NULL,
	score_de_credito_categoria text NULL,
	score_de_credito_detalhes text NULL,
	score_de_credito_ultima_atualizacao timestamptz NULL,
	fob_anual_ic numeric(18, 2) NULL,
	num_associated_contacts int4 NULL,
	num_associated_deals int4 NULL,
	hs_num_open_deals int4 NULL,
	CONSTRAINT companies_pkey PRIMARY KEY (hs_object_id)
);


-- public.contacts definição

-- Drop table

-- DROP TABLE public.contacts;

CREATE TABLE public.contacts (
	hs_object_id text NOT NULL,
	firstname text NULL,
	lastname text NULL,
	email text NULL,
	full_name text NULL,
	jobtitle text NULL,
	phone text NULL,
	mobilephone text NULL,
	govcs_i_phone_number text NULL,
	city text NULL,
	country text NULL,
	createdate timestamp NULL,
	lastmodifieddate timestamp NULL,
	hubspot_owner_id text NULL,
	cargo_ text NULL,
	departamento text NULL,
	classificacao_ravena text NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	updated_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	sync_status text DEFAULT 'active'::character varying NULL,
	hubspot_raw_data jsonb NULL,
	tipo_de_contato text NULL,
	link_do_linkedin text NULL,
	guardiao__cs_ text NULL,
	cs__contatou_novo_contato_ text NULL,
	canal_de_aquisicao_do_contato text NULL,
	sales__feedback_do_contat text NULL,
	hs_whatsapp_phone_number text NULL,
	cs_suporte_premium text NULL,
	notes_last_contacted timestamp NULL,
	CONSTRAINT contacts_pkey PRIMARY KEY (hs_object_id),
	CONSTRAINT contacts_sync_status_check CHECK ((sync_status = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text, ('error'::character varying)::text, ('syncing'::character varying)::text])))
);
CREATE INDEX idx_contacts_createdate ON public.contacts USING btree (createdate);
CREATE INDEX idx_contacts_email ON public.contacts USING btree (email) WHERE (email IS NOT NULL);
CREATE INDEX idx_contacts_govcs_phone ON public.contacts USING btree (govcs_i_phone_number) WHERE (govcs_i_phone_number IS NOT NULL);
CREATE INDEX idx_contacts_lastmodified ON public.contacts USING btree (lastmodifieddate);
CREATE INDEX idx_contacts_phone ON public.contacts USING btree (phone) WHERE (phone IS NOT NULL);
CREATE INDEX idx_contacts_sync ON public.contacts USING btree (lastmodifieddate, sync_status);

-- Table Triggers

create trigger trg_update_contact_updated_at before
update
    on
    public.contacts for each row execute function update_contact_updated_at();


-- public.deal_stages_pipelines definição

-- Drop table

-- DROP TABLE public.deal_stages_pipelines;

CREATE TABLE public.deal_stages_pipelines (
	stage_id int8 NOT NULL,
	stage_label text NULL,
	stage_displayorder int4 NULL,
	stage_createdat timestamp NULL,
	stage_updatedat timestamp NULL,
	stage_active bool NULL,
	deal_isclosed bool NULL,
	pipeline_label text NULL,
	pipeline_active bool NULL,
	pipeline_displayorder int4 NULL,
	pipeline_id int8 NULL,
	pipeline_createdat timestamp NULL,
	pipeline_updatedat timestamp NULL,
	row_updatedat timestamp NULL,
	CONSTRAINT hubspot_deal_stages_pkey PRIMARY KEY (stage_id)
);


-- public.deals definição

-- Drop table

-- DROP TABLE public.deals;

CREATE TABLE public.deals (
	hs_object_id text NOT NULL,
	dealname text NULL,
	pipeline text NULL,
	dealstage text NULL,
	tipo_de_receita text NULL,
	empresa_internacional text NULL,
	tipo_de_negociacao text NULL,
	produto_principal text NULL,
	ramo_de_atuacao_do_negocio text NULL,
	amount_in_home_currency numeric(18, 2) NULL,
	valor_de_implementacao_us numeric(18, 2) NULL,
	valor_ganho numeric(18, 2) NULL,
	valor_de_implementacao numeric(18, 2) NULL,
	canal_de_aquisicao text NULL,
	hubspot_owner_id text NULL,
	criado_por text NULL,
	pr_vendedor text NULL,
	analista_comercial text NULL,
	user_account_manager text NULL,
	createdate timestamp NULL,
	data_de_entrada_na_etapa_distribuicao_vendas_nmrr timestamp NULL,
	data_de_prospect timestamp NULL,
	etapa_data_de_tentando_contato timestamp NULL,
	data_de_qualificacao timestamp NULL,
	data_de_agendamento timestamp NULL,
	fase_data_de_no_show timestamp NULL,
	data_de_demonstracao timestamp NULL,
	data_de_onboarding_trial timestamp NULL,
	data_de_proposta timestamp NULL,
	etapa_data_de_entrada_em_fechamento timestamp NULL,
	sales_data_de_faturamento timestamp NULL,
	closedate timestamp NULL,
	notes_next_activity_date timestamp NULL,
	data_prevista_reuniao timestamp NULL,
	notes_last_updated timestamp NULL,
	hs_lastmodifieddate timestamp NULL,
	faturamento_anual_ic text NULL,
	fob_anual_ic text NULL,
	sales_sal_sales_accepted_lead text NULL,
	status_de_agendamento text NULL,
	ultima_etapa_antes_do_perdido text NULL,
	ops_id_negocio_de_origem text NULL,
	presales_temperatura_v2 text NULL,
	temperatura_do_deal text NULL,
	macro_segmento_oficial text NULL,
	etapa_data_do_reagendamento text NULL,
	deal_cycle text NULL,
	coordenador text NULL,
	motivo_de_perda_n1 text NULL,
	campanha text NULL,
	fin_erro_de_dados_para_faturamento text NULL,
	tag_ops text NULL,
	closed_lost_reason text NULL,
	motivo_de_perda_n2 text NULL,
	sales_a_empresa_estava_no_timing_para_uma_contratacao text NULL,
	sales_a_reuniao_foi_realizada_com_uma_persona_adequada text NULL,
	sales_a_qualificacao_snippet_esta_preenchida_e_de_forma_clara text NULL,
	sales_a_dor_mapeada_pelo_pre_vendedor text NULL,
	score_de_credito_categoria text NULL,
	sales_percentual_de_desconto_clonado text NULL,
	sales_tem_uma_pessoa_ou_time_dedicado_para_analise_de_dados text NULL,
	sales_usa_dados_para_as_tomadas_de_decisoes_na_empresa text NULL,
	closed_won_reason text NULL,
	produto_intencao text NULL,
	produto_do_agendamento text NULL,
	sales_produtos_apresentados_na_demo text NULL,
	bu_business_unit text NULL,
	sales_business_unit text NULL,
	sales_business_unit_de_intencao text NULL,
	sales_business_unit_do_agendamento text NULL,
	sales_business_unit_da_demonstracao text NULL,
	sales_quais_as_principais_dores_e_impacto_de_nao_resolver text NULL,
	como_esse_lead_foi_aquecido_para_chegar_no_agendamento_primeiro text NULL,
	sales_principal_meio_de_comunicacao_utilizado_para_realizar_o_a text NULL,
	o_decisor_participou_da_reuniao text NULL,
	sales_de_chance_de_fechamento text NULL,
	sales_feedback_do_produto text NULL,
	sales_quando_pretende_ter_essa_dor_resolvida text NULL,
	amount numeric(18, 2) NULL,
	sales_budget_existe_orcamento_mapeado_para_sanar_essa_dor text NULL,
	sales_processo_de_adesao_proximos_passos_pessoas_a_serem_envolv text NULL,
	sales_proximos_passos text NULL,
	motivo_de_ganho text NULL,
	"json" jsonb NULL,
	CONSTRAINT deals_pkey PRIMARY KEY (hs_object_id)
);


-- public.hubspot_properties definição

-- Drop table

-- DROP TABLE public.hubspot_properties;

CREATE TABLE public.hubspot_properties (
	id serial4 NOT NULL,
	hs_object varchar(50) NOT NULL,
	hs_name varchar(100) NOT NULL,
	hs_internal_name varchar(100) NOT NULL,
	column_db varchar(100) NOT NULL,
	table_db varchar(100) NOT NULL,
	data_type varchar(20) DEFAULT 'text'::character varying NOT NULL,
	sync_enabled bool DEFAULT true NOT NULL,
	description text NULL,
	created_at timestamptz DEFAULT now() NULL,
	updated_at timestamptz DEFAULT now() NULL,
	created_by varchar(100) NULL,
	CONSTRAINT hubspot_properties_pkey PRIMARY KEY (id)
);


-- public.line_items definição

-- Drop table

-- DROP TABLE public.line_items;

CREATE TABLE public.line_items (
	hs_object_id text NOT NULL,
	"name" text NULL,
	codigo_de_produto_omie text NULL,
	hs_sku text NULL,
	price numeric(18, 2) NULL,
	sales_bu text NULL,
	produto_principal text NULL,
	in_produto_esta_nesta_negociacao text NULL,
	hs_margin_mrr numeric(18, 2) NULL,
	description text NULL,
	adds_on text NULL,
	amount numeric(18, 2) NULL,
	discount numeric(18, 2) NULL,
	recurringbillingfrequency text NULL,
	createdate timestamp NULL,
	row_updated timestamp NULL,
	archived bool NULL,
	deal_id text NULL,
	hs_lastmodifieddate timestamp NULL,
	CONSTRAINT line_items_pkey PRIMARY KEY (hs_object_id)
);
CREATE INDEX idx_hli_deal_id ON public.line_items USING btree (deal_id);


-- public.owners definição

-- Drop table

-- DROP TABLE public.owners;

CREATE TABLE public.owners (
	userid int8 NULL,
	id varchar NOT NULL,
	email varchar NULL,
	firstname varchar NULL,
	lastname varchar NULL,
	fullname varchar NULL,
	teams jsonb NULL,
	createdat varchar NULL,
	archived varchar NULL,
	useridincludinginactive int8 NULL,
	"type" varchar NULL,
	updatedat varchar NULL,
	CONSTRAINT owners_pkey PRIMARY KEY (id)
);


-- public.sync_status definição

-- Drop table

-- DROP TABLE public.sync_status;

CREATE TABLE public.sync_status (
	id serial4 NOT NULL, -- ID único do registro
	object_type varchar(50) NOT NULL, -- Tipo de objeto (contacts, deals, companies, etc.)
	last_sync_after varchar(100) DEFAULT ''::character varying NULL, -- Cursor para paginação da API HubSpot
	total_processed int4 DEFAULT 0 NULL, -- Total de registros processados na última sincronização
	sync_date timestamp DEFAULT now() NULL, -- Data e hora da última sincronização
	status varchar(20) DEFAULT 'pending'::character varying NULL, -- Status da sincronização (pending, running, completed, error)
	created_at timestamp DEFAULT now() NULL, -- Data de criação do registro
	updated_at timestamp DEFAULT now() NULL, -- Data da última atualização
	sync_start_time timestamp NULL,
	sync_end_time timestamp NULL,
	sync_duration_seconds int4 NULL,
	properties_synced int4 DEFAULT 0 NULL,
	columns_created int4 DEFAULT 0 NULL,
	error_message text NULL,
	hubspot_cursor varchar(100) NULL,
	CONSTRAINT sync_status_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.sync_status IS 'Controle de sincronização de objetos do HubSpot';

-- Column comments

COMMENT ON COLUMN public.sync_status.id IS 'ID único do registro';
COMMENT ON COLUMN public.sync_status.object_type IS 'Tipo de objeto (contacts, deals, companies, etc.)';
COMMENT ON COLUMN public.sync_status.last_sync_after IS 'Cursor para paginação da API HubSpot';
COMMENT ON COLUMN public.sync_status.total_processed IS 'Total de registros processados na última sincronização';
COMMENT ON COLUMN public.sync_status.sync_date IS 'Data e hora da última sincronização';
COMMENT ON COLUMN public.sync_status.status IS 'Status da sincronização (pending, running, completed, error)';
COMMENT ON COLUMN public.sync_status.created_at IS 'Data de criação do registro';
COMMENT ON COLUMN public.sync_status.updated_at IS 'Data da última atualização';

-- Table Triggers

create trigger trg_update_sync_status_updated_at before
update
    on
    public.sync_status for each row execute function update_sync_status_updated_at();



-- DROP FUNCTION public.update_contact_sync_timestamp();

CREATE OR REPLACE FUNCTION public.update_contact_sync_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.last_sync_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

-- DROP FUNCTION public.update_contact_updated_at();

CREATE OR REPLACE FUNCTION public.update_contact_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
;

-- DROP FUNCTION public.update_sync_status_updated_at();

CREATE OR REPLACE FUNCTION public.update_sync_status_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;