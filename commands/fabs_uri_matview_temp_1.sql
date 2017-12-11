create materialized view fabs_uri_matview_temp_1 as
(
select
    'asst_aw_' ||
        coalesce(tf.awarding_sub_tier_agency_c,'-none-') || '_' ||
        '-none-' || '_' ||
        coalesce(tf.uri, '-none-') as generated_unique_award_id,
    tf.assistance_type as type,
    case
        when tf.assistance_type = '02' then 'Block Grant'
        when tf.assistance_type = '03' then 'Formula Grant'
        when tf.assistance_type = '04' then 'Project Grant'
        when tf.assistance_type = '05' then 'Cooperative Agreement'
        when tf.assistance_type = '06' then 'Direct Payment for Specified Use'
        when tf.assistance_type = '07' then 'Direct Loan'
        when tf.assistance_type = '08' then 'Guaranteed/Insured Loan'
        when tf.assistance_type = '09' then 'Insurance'
        when tf.assistance_type = '10' then 'Direct Payment with Unrestricted Use'
        when tf.assistance_type = '11' then 'Other Financial Assistance'
    end as type_description,
    ac.type_name as category,
    null::text as piid,
    null::text as fain,
    tf.uri as uri,
    uniq_award.total_obligation as total_obligation,
    null::float as total_outlay,
    awarding_agency.agency_id as awarding_agency_id,
    tf.awarding_sub_tier_agency_c as awarding_sub_tier_agency_c,
    funding_agency.agency_id as funding_agency_id,
    tf.funding_sub_tier_agency_co as funding_sub_tier_agency_co,
    'DBR'::text as data_source,
    uniq_award.signed_date as date_signed,
    tf.award_description as description,
    uniq_award.period_of_performance_start_date as period_of_performance_start_date,
    uniq_award.period_of_performance_current_end_date as period_of_performance_current_end_date,
    null::float as potential_total_value_of_award,
    null::float as base_and_all_options_value,
    tf.modified_at as last_modified_date,   
    uniq_award.certified_date as certified_date,
    tf.transaction_id as latest_transaction_id,
    tf.record_type as record_type,
    'asst_tx_' || tf.afa_generated_unique as latest_transaction_unique,
    0 as total_subaward_amount,
    0 as subaward_count,
    
    -- recipient data
    tf.awardee_or_recipient_uniqu as recipient_unique_id,
    tf.awardee_or_recipient_legal as recipient_name,

	-- executive compensation data
	exec_comp.officer_1_name as officer_1_name,
	exec_comp.officer_1_amount as officer_1_amount,
	exec_comp.officer_2_name as officer_2_name,
	exec_comp.officer_2_amount as officer_2_amount,
	exec_comp.officer_3_name as officer_3_name,
	exec_comp.officer_3_amount as officer_3_amount,
	exec_comp.officer_4_name as officer_4_name,
	exec_comp.officer_4_amount as officer_4_amount,
	exec_comp.officer_5_name as officer_5_name,
	exec_comp.officer_5_amount as officer_5_amount,

    -- business categories
    tf.legal_entity_address_line1 as recipient_location_address_line1,
    tf.legal_entity_address_line2 as recipient_location_address_line2,
    tf.legal_entity_address_line3 as recipient_location_address_line3,
    
    -- foreign province
    tf.legal_entity_foreign_provi as recipient_location_foreign_province,
    
    -- country
    tf.legal_entity_country_code as recipient_location_country_code,
    tf.legal_entity_country_name as recipient_location_country_name,
     
    -- state
	tf.legal_entity_state_code as recipient_location_state_code,
    tf.legal_entity_state_name as recipient_location_state_name,
    
    -- county
    tf.legal_entity_county_code as recipient_location_county_code,
    tf.legal_entity_county_name as recipient_location_county_name,
    
    -- city
    tf.legal_entity_city_name as recipient_location_city_name,
    
    -- zip
    tf.legal_entity_zip5 as recipient_location_zip5,
    
    -- congressional disctrict
    tf.legal_entity_congressional as recipient_location_congressional_code,
    
    -- ppop data
    
    -- foreign
    null::text as pop_foreign_province,
    
    -- country
	tf.place_of_perform_country_c as pop_country_code,
    tf.place_of_perform_country_n as pop_country_name,
    
    -- state
    null::text as pop_state_code,
    tf.place_of_perform_state_nam as pop_state_name,
    
    -- county
    tf.place_of_perform_county_co as pop_county_code,
    tf.place_of_perform_county_na as pop_county_name,
    
    -- city
    tf.place_of_performance_city as pop_city_name,
    
    -- zip
    null::text as pop_zip5,
    tf.place_of_performance_zip4a as pop_zip4,
    
    -- congressional disctrict
    tf.place_of_performance_congr as pop_congressional_code
from
    transaction_fabs as tf -- aka latest transaction
    inner join 
    (
        select
            distinct on (transaction_fabs.uri, transaction_fabs.awarding_sub_tier_agency_c)
            transaction_fabs.uri,
            transaction_fabs.awarding_sub_tier_agency_c,
            transaction_fabs.action_date,
            transaction_fabs.award_modification_amendme,
            transaction_fabs.afa_generated_unique,
            count(transaction_fabs.uri) over w as sumuri,
            max(transaction_fabs.action_date) over w as certified_date,
            min(transaction_fabs.action_date) over w as signed_date,
            min(transaction_fabs.period_of_performance_star::date) over w as period_of_performance_start_date,
            max(transaction_fabs.period_of_performance_curr::date) over w as period_of_performance_current_end_date,
            null as base_and_all_options_value,
            sum(coalesce(transaction_fabs.federal_action_obligation::double precision, 0::double precision)) over w as total_obligation
        from transaction_fabs
        where transaction_fabs.record_type = '1'
        window w as (partition by transaction_fabs.uri, transaction_fabs.awarding_sub_tier_agency_c)
        order by 
            transaction_fabs.uri, 
            transaction_fabs.awarding_sub_tier_agency_c,  
            transaction_fabs.action_date desc, 
            transaction_fabs.award_modification_amendme desc
    ) as uniq_award on uniq_award.afa_generated_unique = tf.afa_generated_unique
	inner join
	award_category as ac on ac.type_code = tf.assistance_type
	inner join
	agency_lookup as awarding_agency on awarding_agency.subtier_code = tf.awarding_sub_tier_agency_c 
	left outer join
	agency_lookup as funding_agency on funding_agency.subtier_code = tf.funding_sub_tier_agency_co
    inner join
    subtier_agency as awarding_subtier on awarding_subtier.subtier_code = tf.awarding_sub_tier_agency_c
	left outer join
	exec_comp_lookup as exec_comp on exec_comp.duns = tf.awardee_or_recipient_uniqu
); 
