drop materialized view if exists assistance_award_matview;

create materialized view assistance_award_matview as (
(select
    generated_unique_award_id,
    type,
    type_description,
    fabs_fain_uniq_awards.agency_id as agency_id,
    referenced_idv_agency_iden,
    piid,
    parent_award_piid,
    fain,
    uri,
    total_obligation,
    total_subsidy_cost,
    total_outlay,
    awarding_sub_tier_agency_c,
    funding_sub_tier_agency_co,
    data_source,
    action_date,
    date_signed,
    description,
    period_of_performance_start_date,
    period_of_performance_current_end_date,
    potential_total_value_of_award,
    base_and_all_options_value,
    last_modified_date,
    certified_date,
    record_type,
    latest_transaction_unique_id,
    total_subaward_amount,
    subaward_count,
    pulled_from,
    product_or_service_code,
    product_or_service_co_desc,
    extent_competed,
    extent_compete_description,
    type_of_contract_pricing,
    naics,
    naics_description,
    idv_type,
    idv_type_description,
    type_set_aside,
    type_set_aside_description,
    assistance_type,
    business_funds_indicator,
    business_types,
    cfda_number,
    cfda_title,

    -- recipient data
    recipient_unique_id, -- DUNS
    recipient_name,

    -- executive compensation data
    officer_1_name,
    officer_1_amount,
    officer_2_name,
    officer_2_amount,
    officer_3_name,
    officer_3_amount,
    officer_4_name,
    officer_4_amount,
    officer_5_name,
    officer_5_amount,

    -- business categories
    recipient_location_address_line1,
    recipient_location_address_line2,
    recipient_location_address_line3,

    -- foreign province
    recipient_location_foreign_province,

    -- country
    recipient_location_country_code,
    recipient_location_country_name,

    -- state
    recipient_location_state_code,
    recipient_location_state_name,

    -- county (NONE FOR FPDS)
    recipient_location_county_code,
    recipient_location_county_name,

    -- city
    recipient_location_city_name,

    -- zip
    recipient_location_zip5,

    -- congressional disctrict
    recipient_location_congressional_code,

    -- ppop data

    -- foreign
    pop_foreign_province,

    -- country
    pop_country_code,
    pop_country_name,

    -- state
    pop_state_code,
    pop_state_name,

    -- county
    pop_county_code,
    pop_county_name,

    -- city
    pop_city_name,

    -- zip
    pop_zip5,
    -- pop_zip4,

    -- congressional disctrict
    pop_congressional_code,

    ac.type_name as category,
    awarding_agency.agency_id as awarding_agency_id,
    funding_agency.agency_id as funding_agency_id,
    fy(action_date) as fiscal_year
from
    dblink ('broker_server', 'select
    distinct on (pafa.fain, pafa.awarding_sub_tier_agency_c)
    ''asst_aw_'' ||
        coalesce(pafa.awarding_sub_tier_agency_c,''-none-'') || ''_'' ||
        coalesce(pafa.fain, ''-none-'') || ''_'' ||
        ''-none-'' as generated_unique_award_id,
    pafa.assistance_type as type,
    case
        when pafa.assistance_type = ''02'' then ''Block Grant''
        when pafa.assistance_type = ''03'' then ''Formula Grant''
        when pafa.assistance_type = ''04'' then ''Project Grant''
        when pafa.assistance_type = ''05'' then ''Cooperative Agreement''
        when pafa.assistance_type = ''06'' then ''Direct Payment for Specified Use''
        when pafa.assistance_type = ''07'' then ''Direct Loan''
        when pafa.assistance_type = ''08'' then ''Guaranteed/Insured Loan''
        when pafa.assistance_type = ''09'' then ''Insurance''
        when pafa.assistance_type = ''10'' then ''Direct Payment with Unrestricted Use''
        when pafa.assistance_type = ''11'' then ''Other Financial Assistance''
    end as type_description,
    null::text as agency_id,
    null::text as referenced_idv_agency_iden,
    null::text as piid,
    null::text as parent_award_piid,
    pafa.fain as fain,
    null::text as uri,
    sum(coalesce(pafa.federal_action_obligation::double precision, 0::double precision)) over w as total_obligation,
    sum(coalesce(pafa.original_loan_subsidy_cost::double precision, 0::double precision)) over w as total_subsidy_cost,
    null::float as total_outlay,
    pafa.awarding_sub_tier_agency_c as awarding_sub_tier_agency_c,
    pafa.funding_sub_tier_agency_co as funding_sub_tier_agency_co,
    ''DBR''::text as data_source,
    pafa.action_date::date as action_date,
    min(pafa.action_date) over w as date_signed,
    pafa.award_description as description,
    min(pafa.period_of_performance_star::date) over w as period_of_performance_start_date,
    max(pafa.period_of_performance_curr::date) over w as period_of_performance_current_end_date,
    null::float as potential_total_value_of_award,
    null::float as base_and_all_options_value,
    pafa.modified_at::date as last_modified_date,
    max(pafa.action_date) over w as certified_date,
    pafa.record_type as record_type,
    ''asst_tx_'' || pafa.afa_generated_unique as latest_transaction_unique_id,
    0 as total_subaward_amount,
    0 as subaward_count,
    null::text as pulled_from,
    null::text as product_or_service_code,
    null::text as product_or_service_co_desc,
    null::text as extent_competed,
    null::text as extent_compete_description,
    null::text as type_of_contract_pricing,
    null::text as naics,
    null::text as naics_description,
    null::text as idv_type,
    null::text as idv_type_description,
    null::text as type_set_aside,
    null::text as type_set_aside_description,
    pafa.assistance_type as assistance_type,
    pafa.business_funds_indicator as business_funds_indicator,
    pafa.business_types as business_types,
    pafa.cfda_number as cfda_number,
    pafa.cfda_title as cfda_title,

    -- recipient data
    pafa.awardee_or_recipient_uniqu as recipient_unique_id,
    pafa.awardee_or_recipient_legal as recipient_name,

    -- executive compensation data
    exec_comp.high_comp_officer1_full_na as officer_1_name,
    exec_comp.high_comp_officer1_amount as officer_1_amount,
    exec_comp.high_comp_officer2_full_na as officer_2_name,
    exec_comp.high_comp_officer2_amount as officer_2_amount,
    exec_comp.high_comp_officer3_full_na as officer_3_name,
    exec_comp.high_comp_officer3_amount as officer_3_amount,
    exec_comp.high_comp_officer4_full_na as officer_4_name,
    exec_comp.high_comp_officer4_amount as officer_4_amount,
    exec_comp.high_comp_officer5_full_na as officer_5_name,
    exec_comp.high_comp_officer5_amount as officer_5_amount,

    -- business categories
    pafa.legal_entity_address_line1 as recipient_location_address_line1,
    pafa.legal_entity_address_line2 as recipient_location_address_line2,
    pafa.legal_entity_address_line3 as recipient_location_address_line3,

    -- foreign province
    pafa.legal_entity_foreign_provi as recipient_location_foreign_province,

    -- country
    pafa.legal_entity_country_code as recipient_location_country_code,
    pafa.legal_entity_country_name as recipient_location_country_name,

    -- state
    pafa.legal_entity_state_code as recipient_location_state_code,
    pafa.legal_entity_state_name as recipient_location_state_name,

    -- county
    pafa.legal_entity_county_code as recipient_location_county_code,
    pafa.legal_entity_county_name as recipient_location_county_name,

    -- city
    pafa.legal_entity_city_name as recipient_location_city_name,

    -- zip
    pafa.legal_entity_zip5 as recipient_location_zip5,

    -- congressional disctrict
    pafa.legal_entity_congressional as recipient_location_congressional_code,

    -- ppop data

    -- foreign
    null::text as pop_foreign_province,

    -- country
    pafa.place_of_perform_country_c as pop_country_code,
    pafa.place_of_perform_country_n as pop_country_name,

    -- state
    null::text as pop_state_code,
    pafa.place_of_perform_state_nam as pop_state_name,

    -- county
    pafa.place_of_perform_county_co as pop_county_code,
    pafa.place_of_perform_county_na as pop_county_name,

    -- city
    pafa.place_of_performance_city as pop_city_name,

    -- zip
    null::text as pop_zip5,
    -- pafa.place_of_performance_zip4a as pop_zip4,

    -- congressional disctrict
    pafa.place_of_performance_congr as pop_congressional_code
    
from published_award_financial_assistance as pafa
    left outer join
    exec_comp_lookup as exec_comp on exec_comp.awardee_or_recipient_uniqu = pafa.awardee_or_recipient_uniqu
where pafa.record_type = ''2'' and is_active=TRUE
window w as (partition by pafa.fain, pafa.awarding_sub_tier_agency_c)
order by
    pafa.fain,
    pafa.awarding_sub_tier_agency_c,
    pafa.action_date desc,
    pafa.award_modification_amendme desc
;') as fabs_fain_uniq_awards
    (
        generated_unique_award_id text,
        type text,
        type_description text,
        agency_id text,
        referenced_idv_agency_iden text,
        piid text,
        parent_award_piid text,
        fain text,
        uri text,
        total_obligation float(2),
        total_subsidy_cost float(2),
        total_outlay float(2),
        awarding_sub_tier_agency_c text,
        funding_sub_tier_agency_co text,
        data_source text,
        action_date date,
        date_signed date,
        description text,
        period_of_performance_start_date date,
        period_of_performance_current_end_date date,
        potential_total_value_of_award float(2),
        base_and_all_options_value float(2),
        last_modified_date date,
        certified_date date,
        record_type int,
        latest_transaction_unique_id text,
        total_subaward_amount float(2),
        subaward_count int,
        pulled_from text,
        product_or_service_code text,
        product_or_service_co_desc text,
        extent_competed text,
        extent_compete_description text,
        type_of_contract_pricing text,
        naics text,
        naics_description text,
        idv_type text,
        idv_type_description text,
        type_set_aside text,
        type_set_aside_description text,
        assistance_type text,
        business_funds_indicator text,
        business_types text,
        cfda_number text,
        cfda_title text,

        -- recipient data
        recipient_unique_id text, -- DUNS
        recipient_name text,

        -- executive compensation data
        officer_1_name text,
        officer_1_amount text,
        officer_2_name text,
        officer_2_amount text,
        officer_3_name text,
        officer_3_amount text,
        officer_4_name text,
        officer_4_amount text,
        officer_5_name text,
        officer_5_amount text,

        -- business categories
        recipient_location_address_line1 text,
        recipient_location_address_line2 text,
        recipient_location_address_line3 text,

        -- foreign province
        recipient_location_foreign_province text,

        -- country
        recipient_location_country_code text,
        recipient_location_country_name text,

        -- state
        recipient_location_state_code text,
        recipient_location_state_name text,

        -- county (NONE FOR FPDS)
        recipient_location_county_code text,
        recipient_location_county_name text,

        -- city
        recipient_location_city_name text,

        -- zip
        recipient_location_zip5 text,

        -- congressional disctrict
        recipient_location_congressional_code text,

        -- ppop data

        -- foreign
        pop_foreign_province text,

        -- country
        pop_country_code text,
        pop_country_name text,

        -- state
        pop_state_code text,
        pop_state_name text,

        -- county
        pop_county_code text,
        pop_county_name text,

        -- city
        pop_city_name text,

        -- zip
        pop_zip5 text,
        -- pop_zip4 text,

        -- congressional disctrict
        pop_congressional_code text
    )
    inner join
    award_category as ac on ac.type_code = type
    inner join
    agency_lookup as awarding_agency on awarding_agency.subtier_code = awarding_sub_tier_agency_c
    left outer join
    agency_lookup as funding_agency on funding_agency.subtier_code = funding_sub_tier_agency_co)

union all

(select
    generated_unique_award_id,
    type,
    type_description,
    fabs_uri_uniq_awards.agency_id as agency_id,
    referenced_idv_agency_iden,
    piid,
    parent_award_piid,
    fain,
    uri,
    total_obligation,
    total_subsidy_cost,
    total_outlay,
    awarding_sub_tier_agency_c,
    funding_sub_tier_agency_co,
    data_source,
    action_date,
    date_signed,
    description,
    period_of_performance_start_date,
    period_of_performance_current_end_date,
    potential_total_value_of_award,
    base_and_all_options_value,
    last_modified_date,
    certified_date,
    record_type,
    latest_transaction_unique_id,
    total_subaward_amount,
    subaward_count,
    pulled_from,
    product_or_service_code,
    product_or_service_co_desc,
    extent_competed,
    extent_compete_description,
    type_of_contract_pricing,
    naics,
    naics_description,
    idv_type,
    idv_type_description,
    type_set_aside,
    type_set_aside_description,
    assistance_type,
    business_funds_indicator,
    business_types,
    cfda_number,
    cfda_title,

    -- recipient data
    recipient_unique_id, -- DUNS
    recipient_name,

    -- executive compensation data
    officer_1_name,
    officer_1_amount,
    officer_2_name,
    officer_2_amount,
    officer_3_name,
    officer_3_amount,
    officer_4_name,
    officer_4_amount,
    officer_5_name,
    officer_5_amount,

    -- business categories
    recipient_location_address_line1,
    recipient_location_address_line2,
    recipient_location_address_line3,

    -- foreign province
    recipient_location_foreign_province,

    -- country
    recipient_location_country_code,
    recipient_location_country_name,

    -- state
    recipient_location_state_code,
    recipient_location_state_name,

    -- county (NONE FOR FPDS)
    recipient_location_county_code,
    recipient_location_county_name,

    -- city
    recipient_location_city_name,

    -- zip
    recipient_location_zip5,

    -- congressional disctrict
    recipient_location_congressional_code,

    -- ppop data

    -- foreign
    pop_foreign_province,

    -- country
    pop_country_code,
    pop_country_name,

    -- state
    pop_state_code,
    pop_state_name,

    -- county
    pop_county_code,
    pop_county_name,

    -- city
    pop_city_name,

    -- zip
    pop_zip5,
    -- pop_zip4,

    -- congressional disctrict
    pop_congressional_code,

    ac.type_name as category,
    awarding_agency.agency_id as awarding_agency_id,
    funding_agency.agency_id as funding_agency_id,
    fy(action_date) as fiscal_year
from
    dblink ('broker_server', 'select
    distinct on (pafa.uri, pafa.awarding_sub_tier_agency_c)
    ''asst_aw_'' ||
        coalesce(pafa.awarding_sub_tier_agency_c,''-none-'') || ''_'' ||
        ''-none-'' || ''_'' ||
        coalesce(pafa.uri, ''-none-'') as generated_unique_award_id,
    pafa.assistance_type as type,
    case
        when pafa.assistance_type = ''02'' then ''Block Grant''
        when pafa.assistance_type = ''03'' then ''Formula Grant''
        when pafa.assistance_type = ''04'' then ''Project Grant''
        when pafa.assistance_type = ''05'' then ''Cooperative Agreement''
        when pafa.assistance_type = ''06'' then ''Direct Payment for Specified Use''
        when pafa.assistance_type = ''07'' then ''Direct Loan''
        when pafa.assistance_type = ''08'' then ''Guaranteed/Insured Loan''
        when pafa.assistance_type = ''09'' then ''Insurance''
        when pafa.assistance_type = ''10'' then ''Direct Payment with Unrestricted Use''
        when pafa.assistance_type = ''11'' then ''Other Financial Assistance''
    end as type_description,
    null::text as agency_id,
    null::text as referenced_idv_agency_iden,
    null::text as piid,
    null::text as parent_award_piid,
    null::text as fain,
    pafa.uri as uri,
    sum(coalesce(pafa.federal_action_obligation::double precision, 0::double precision)) over w as total_obligation,
    sum(coalesce(pafa.original_loan_subsidy_cost::double precision, 0::double precision)) over w as total_subsidy_cost,
    null::float as total_outlay,
    pafa.awarding_sub_tier_agency_c as awarding_sub_tier_agency_c,
    pafa.funding_sub_tier_agency_co as funding_sub_tier_agency_co,
    ''DBR''::text as data_source,
    pafa.action_date::date as action_date,
    min(pafa.action_date) over w as date_signed,
    pafa.award_description as description,
    min(pafa.period_of_performance_star::date) over w as period_of_performance_start_date,
    max(pafa.period_of_performance_curr::date) over w as period_of_performance_current_end_date,
    null::float as potential_total_value_of_award,
    null::float as base_and_all_options_value,
    pafa.modified_at::date as last_modified_date,
    max(pafa.action_date) over w as certified_date,
    pafa.record_type as record_type,
    ''asst_tx_'' || pafa.afa_generated_unique as latest_transaction_unique_id,
    0 as total_subaward_amount,
    0 as subaward_count,
    null::text as pulled_from,
    null::text as product_or_service_code,
    null::text as product_or_service_co_desc,
    null::text as extent_competed,
    null::text as extent_compete_description,
    null::text as type_of_contract_pricing,
    null::text as naics,
    null::text as naics_description,
    null::text as idv_type,
    null::text as idv_type_description,
    null::text as type_set_aside,
    null::text as type_set_aside_description,
    pafa.assistance_type as assistance_type,
    pafa.business_funds_indicator as business_funds_indicator,
    pafa.business_types as business_types,
    pafa.cfda_number as cfda_number,
    pafa.cfda_title as cfda_title,

    -- recipient data
    pafa.awardee_or_recipient_uniqu as recipient_unique_id,
    pafa.awardee_or_recipient_legal as recipient_name,

    -- executive compensation data
    exec_comp.high_comp_officer1_full_na as officer_1_name,
    exec_comp.high_comp_officer1_amount as officer_1_amount,
    exec_comp.high_comp_officer2_full_na as officer_2_name,
    exec_comp.high_comp_officer2_amount as officer_2_amount,
    exec_comp.high_comp_officer3_full_na as officer_3_name,
    exec_comp.high_comp_officer3_amount as officer_3_amount,
    exec_comp.high_comp_officer4_full_na as officer_4_name,
    exec_comp.high_comp_officer4_amount as officer_4_amount,
    exec_comp.high_comp_officer5_full_na as officer_5_name,
    exec_comp.high_comp_officer5_amount as officer_5_amount,

    -- business categories
    pafa.legal_entity_address_line1 as recipient_location_address_line1,
    pafa.legal_entity_address_line2 as recipient_location_address_line2,
    pafa.legal_entity_address_line3 as recipient_location_address_line3,

    -- foreign province
    pafa.legal_entity_foreign_provi as recipient_location_foreign_province,

    -- country
    pafa.legal_entity_country_code as recipient_location_country_code,
    pafa.legal_entity_country_name as recipient_location_country_name,

    -- state
    pafa.legal_entity_state_code as recipient_location_state_code,
    pafa.legal_entity_state_name as recipient_location_state_name,

    -- county
    pafa.legal_entity_county_code as recipient_location_county_code,
    pafa.legal_entity_county_name as recipient_location_county_name,

    -- city
    pafa.legal_entity_city_name as recipient_location_city_name,

    -- zip
    pafa.legal_entity_zip5 as recipient_location_zip5,

    -- congressional disctrict
    pafa.legal_entity_congressional as recipient_location_congressional_code,

    -- ppop data

    -- foreign
    null::text as pop_foreign_province,

    -- country
    pafa.place_of_perform_country_c as pop_country_code,
    pafa.place_of_perform_country_n as pop_country_name,

    -- state
    null::text as pop_state_code,
    pafa.place_of_perform_state_nam as pop_state_name,

    -- county
    pafa.place_of_perform_county_co as pop_county_code,
    pafa.place_of_perform_county_na as pop_county_name,

    -- city
    pafa.place_of_performance_city as pop_city_name,

    -- zip
    null::text as pop_zip5,
    -- pafa.place_of_performance_zip4a as pop_zip4,

    -- congressional disctrict
    pafa.place_of_performance_congr as pop_congressional_code
    
from published_award_financial_assistance as pafa
    left outer join
    exec_comp_lookup as exec_comp on exec_comp.awardee_or_recipient_uniqu = pafa.awardee_or_recipient_uniqu
where pafa.record_type = ''1'' and is_active=TRUE
window w as (partition by pafa.uri, pafa.awarding_sub_tier_agency_c)
order by
    pafa.uri,
    pafa.awarding_sub_tier_agency_c,
    pafa.action_date desc,
    pafa.award_modification_amendme desc') as fabs_uri_uniq_awards
    (
        generated_unique_award_id text,
        type text,
        type_description text,
        agency_id text,
        referenced_idv_agency_iden text,
        piid text,
        parent_award_piid text,
        fain text,
        uri text,
        total_obligation float(2),
        total_subsidy_cost float(2),
        total_outlay float(2),
        awarding_sub_tier_agency_c text,
        funding_sub_tier_agency_co text,
        data_source text,
        action_date date,
        date_signed date,
        description text,
        period_of_performance_start_date date,
        period_of_performance_current_end_date date,
        potential_total_value_of_award float(2),
        base_and_all_options_value float(2),
        last_modified_date date,
        certified_date date,
        record_type int,
        latest_transaction_unique_id text,
        total_subaward_amount float(2),
        subaward_count int,
        pulled_from text,
        product_or_service_code text,
        product_or_service_co_desc text,
        extent_competed text,
        extent_compete_description text,
        type_of_contract_pricing text,
        naics text,
        naics_description text,
        idv_type text,
        idv_type_description text,
        type_set_aside text,
        type_set_aside_description text,
        assistance_type text,
        business_funds_indicator text,
        business_types text,
        cfda_number text,
        cfda_title text,
        
        -- recipient data
        recipient_unique_id text, -- DUNS
        recipient_name text,

        -- executive compensation data
        officer_1_name text,
        officer_1_amount text,
        officer_2_name text,
        officer_2_amount text,
        officer_3_name text,
        officer_3_amount text,
        officer_4_name text,
        officer_4_amount text,
        officer_5_name text,
        officer_5_amount text,

        -- business categories
        recipient_location_address_line1 text,
        recipient_location_address_line2 text,
        recipient_location_address_line3 text,
        
        -- foreign province
        recipient_location_foreign_province text,
        
        -- country
        recipient_location_country_code text,
        recipient_location_country_name text,
        
        -- state
        recipient_location_state_code text,
        recipient_location_state_name text,
        
        -- county (NONE FOR FPDS)
        recipient_location_county_code text,
        recipient_location_county_name text,
        
        -- city
        recipient_location_city_name text,
        
        -- zip
        recipient_location_zip5 text,
        
        -- congressional disctrict
        recipient_location_congressional_code text,
        
        -- ppop data
        
        -- foreign
        pop_foreign_province text,
        
        -- country
        pop_country_code text,
        pop_country_name text,
        
        -- state
        pop_state_code text,
        pop_state_name text,
        
        -- county
        pop_county_code text,
        pop_county_name text,
        
        -- city
        pop_city_name text,
        
        -- zip
        pop_zip5 text,
        -- pop_zip4 text,
        
        -- congressional disctrict
        pop_congressional_code text
    )
    inner join
    award_category as ac on ac.type_code = type
    inner join
    agency_lookup as awarding_agency on awarding_agency.subtier_code = awarding_sub_tier_agency_c 
    left outer join
    agency_lookup as funding_agency on funding_agency.subtier_code = funding_sub_tier_agency_co)
);