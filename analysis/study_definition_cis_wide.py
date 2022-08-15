from cohortextractor import (
    StudyDefinition,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
    patients
)


start_date = '2020-01-24'
end_date = '2021-09-30'
n_visits = 25
n_years_back = 5

def get_visit_date(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date'
            )}

def get_visit_number(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_filter_column='visit_date',
            return_expectations={
                'category': {'ratios': {0: 0.95,
                                        1: 0.05}}
                }
            )}

def get_result_mk(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_filter_column='visit_date',
            return_expectations={
                'category': {'ratios': {'Negative': 0.94,
                                        'Positive': 0.05,
                                        'Void' : 0.01}}
                }
            )}

def get_result_combined(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_before=date,
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                'category': {'ratios': {'Negative': 0.89, 
                                        'Positive': 0.1,
                                        'Void' : 0.01}}
            }
        )}

def get_first_swab_date(name, col):
    # User reported
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            between=[start_date, end_date],
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "incidence": 0.1
            }
        )}

def get_first_blood_date(name, col):
    # User reported
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            between=[start_date, end_date],
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "incidence": 0.1
            }
        )}

def get_tt_positive(name):
    return{
        name : patients.with_test_result_in_sgss(
            pathogen='SARS-CoV-2',
            test_result='positive',
            between=[start_date, end_date],
            returning='date',
            date_format='YYYY-MM-DD',
            restrict_to_earliest_specimen_date=True,
            return_expectations={
                "incidence": 0.1
            }
        )}

def get_hes_admission(name):
    return{
        name : patients.admitted_to_hospital(
            between=[start_date, end_date],
            returning='date_admitted',
            date_format='YYYY-MM-DD',
            find_first_match_in_period=True,
            with_these_primary_diagnoses=codelist_from_csv(
                'codelists/opensafely-covid-identification.csv',
                system='icd10',
                column='icd10_code'
            ),
            return_expectations={
                "incidence": 0.05
            }
        )}

def get_date_of_death(name):
    return{
        name : patients.died_from_any_cause(
            between=[start_date, end_date],
            returning='date_of_death',
            date_format='YYYY-MM-DD',
            return_expectations={
                "incidence": 0.05
            }
        )}

def get_covid_vaccine(name):
    return{
        name : patients.with_tpp_vaccination_record(
            target_disease_matches="SARS-2 CORONAVIRUS",
            between=[start_date, end_date],
            returning='date',
            date_format='YYYY-MM-DD',
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.8
            }
        )}

def get_last_linkage_date(name, col):
    return{
        name : patients.with_an_ons_cis_record(
            returning=col,
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                
            }
        )}

def get_nhs_data_share(name, col):
    return{
        name : patients.with_an_ons_cis_record(
            returning=col,
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                'category': {'ratios': {0: 0.98, 1: 0.02}}
            }
        )}

def get_sex(name):
    return{
        name : patients.sex(
            return_expectations={
                "category": {"ratios": {"M": 0.49, "F": 0.51}},
                "incidence": 1,
            }
        )}

def get_age(name, date):
    return{
        name: patients.age_as_of(
            reference_date=date,
            return_expectations={
                "rate" : "universal",
                "int" : {"distribution" : "population_ages"}
            }
        )}

def get_alcohol(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/opensafely-hazardous-alcohol-drinking.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_obesity(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-overweight-or-obese-bmi-25-or-over.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_bmi(name, date):
    return {name : patients.most_recent_bmi(
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        return_expectations={
            'float' : {'distribution': 'normal', 'mean': 28, 'stddev': 8},
            'incidence' : 0.9
        }
    )}

def get_cancer(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/user-jkua-cancer.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_CVD_ctv3(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-cardiovascular-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_CVD_snomed(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/nhsd-primary-care-domain-refsets-angina_cod.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_digestive_disorder(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-digestive-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_hiv_aids(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/opensafely-hiv-snomed.csv',
            system='snomed',
            column='id'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_other_mood_disorder_hospital_history(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-unspecified-mood-disorders.csv',
            system='icd10',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_CMD_history(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-cmd-codes.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_CMD_outcome(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-depression-and-anxiety-diagnoses-and-symptoms-excluding-specific-anxieties.csv',
            system='snomed',
            column='code'
        ),
        between=[date, end_date],
        returning='date',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_CMD_hospital_history(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-depression-and-anxiety-excluding-specific-anxieties.csv',
            system='icd10',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_CMD_hospital_outcome(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-depression-and-anxiety-excluding-specific-anxieties.csv',
            system='icd10',
            column='code'
        ),
        between=[date, end_date],
        returning='date_admitted',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_SMI_history(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-smi-codes.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_SMI_outcome(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-serious-mental-illness-schizophrenia-bipolar-disorder-psychosis.csv',
            system='snomed',
            column='code'
        ),
        between=[date, end_date],
        returning='date',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_SMI_hospital_history(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-serious-mental-illness.csv',
            system='icd10',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_SMI_hospital_outcome(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-serious-mental-illness.csv',
            system='icd10',
            column='code'
        ),
        between=[date, end_date],
        returning='date_admitted',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_self_harm_history(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-self-harm-codes.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_self_harm_outcome(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-self-harm-intentional-and-undetermined-intent.csv',
            system='snomed',
            column='code'
        ),
        between=[date, end_date],
        returning='date',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_self_harm_hospital_history(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-self-harm.csv',
            system='icd10',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_self_harm_hospital_outcome(name, date):
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-self-harm.csv',
            system='icd10',
            column='code'
        ),
        between=[date, end_date],
        returning='date_admitted',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}


def get_metabolic_disorder(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-metabolic-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_musculoskeletal_ctv3(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-musculoskeletal-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_musculoskeletal_snomed(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/nhsd-primary-care-domain-refsets-osteo_cod.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_neurological_ctv3(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/opensafely-multiple-sclerosis.csv',
            system='ctv3',
            column='CTV3ID'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_neurological_snomed(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-neurological-disorders.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_kidney_disorder(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-chronic-kidney-disease-stages-3-5.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_respiratory_disorder(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-respiratory-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}




def cis_earliest_positive(start_date, n):
    
    for i in range(n+1):
        
        if i == 0:
            # get 1st visit date based on study start date
            variables = get_visit_date(f'visit_date_{i}', 'visit_date', start_date)
            # get date of death
            variables.update(get_date_of_death('date_of_death'))
            # get evidence of covid infection history
            variables.update(get_hes_admission('covid_hes'))
            variables.update(get_tt_positive('covid_tt'))
            variables.update(get_covid_vaccine('covid_vaccine'))
            # get sex
            variables.update(get_sex('sex'))
        else:
            # get nth visit date
            variables.update(get_visit_date(f'visit_date_{i}', 'visit_date', f'visit_date_{i-1} + 1 days'))
        
        
        # get visit number
        # variables.update(get_visit_number(f'visit_number_{i}', 'visit_num', f'visit_date_{i}'))
    
        # get result combined and corresponding result_mk
        variables.update(get_result_mk(f'result_mk_{i}', 'result_mk', f'visit_date_{i}'))
        variables.update(get_result_combined(f'result_combined_{i}', 'result_combined', f'visit_date_{i}'))
        
        # get earliest positive user report swab and blood
        variables.update(get_first_swab_date('first_pos_swab', 'covid_test_swab_pos_first_date'))
        variables.update(get_first_blood_date('first_pos_blood', 'covid_test_blood_pos_first_date'))
        
        # get linkage permission variables
        # variables.update(get_last_linkage_date('last_linkage_date', 'Final_linkage_date'))
        # variables.update(get_nhs_data_share('nhs_data_share', 'cis_nhs_data_share'))
        
        # age
        variables.update(get_age(f'age_{i}', f'visit_date_{i}'))
        
        # get health history
        variables.update(get_alcohol(f'alcohol_{i}', f'visit_date_{i}'))
        variables.update(get_obesity(f'obesity_{i}', f'visit_date_{i}'))
        variables.update(get_bmi(f'bmi_{i}', f'visit_date_{i}'))
        variables.update(get_cancer(f'cancer_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_ctv3(f'CVD_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_snomed(f'CVD_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_digestive_disorder(f'digestive_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_hiv_aids(f'hiv_aids_{i}', f'visit_date_{i}'))
        variables.update(get_metabolic_disorder(f'metabolic_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_musculoskeletal_ctv3(f'musculoskeletal_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_musculoskeletal_snomed(f'musculoskeletal_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_neurological_ctv3(f'neurological_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_neurological_snomed(f'neurological_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_kidney_disorder(f'kidney_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_respiratory_disorder(f'respiratory_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_other_mood_disorder_hospital_history(f'other_mood_disorder_hospital_history_{i}', f'visit_date_{i}'))
        
        # mental health history
        variables.update(get_CMD_history(f'cmd_history_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_history(f'smi_history_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_history(f'self_harm_history_{i}', f'visit_date_{i}'))
        variables.update(get_CMD_hospital_history(f'cmd_history_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_hospital_history(f'smi_history_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_hospital_history(f'self_harm_history_hospital_{i}', f'visit_date_{i}'))
        
        
        # get mental health outcomes
        variables.update(get_CMD_outcome(f'cmd_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_outcome(f'smi_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_outcome(f'self_harm_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_CMD_hospital_outcome(f'cmd_outcome_date_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_hospital_outcome(f'smi_outcome_date_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_hospital_outcome(f'self_harm_outcome_date_hospital_{i}', f'visit_date_{i}'))
        
    
    return variables
    

study = StudyDefinition(
    
    population=patients.satisfying(
        'in_cis',
        in_cis = patients.with_an_ons_cis_record(
            returning='binary_flag',
            between=[start_date, end_date],
            date_filter_column='visit_date')
        ),

    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "uniform",
        "incidence": 0.99
    },

    # Return visit level CIS data
    **cis_earliest_positive(start_date=start_date, n=n_visits)
    
)

# no history (incidence) new onset

# history (prevalance)
# need to adjust for what they already have in the model
# (possibly single grouped binary outcome)

# cmd history -> smi or self-harm outcome (exacerbation)
# outcome of interest: SMI, self-harm, or ANY hospital admission 
# (possibly a single grouped binary outcome)
# remove anyone with the outcomes

