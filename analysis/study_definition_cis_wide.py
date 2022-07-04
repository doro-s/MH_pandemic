from cohortextractor import (
    StudyDefinition,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
    patients
)

from codelists import *

start_date = '2020-01-24'
end_date = '2021-09-30'
n_visits = 10
n_years = 5

def get_visit_date(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date'
            )}

def get_result_mk(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_filter_column='visit_date',
            return_expectations={
                'category': {'ratios': {0: 0.8, 1: 0.2}}
                }
            )}

def get_tt_positive(name, date):
    return{
        name : patients.with_test_result_in_sgss(
            pathogen='SARS-CoV-2',
            test_result='positive',
            on_or_before=date,
            returning='binary_flag',
            restrict_to_earliest_specimen_date=True,
            return_expectations={
                "incidence": 0.1
            }
        )}

def get_hes_admission(name, date):
    return{
        name : patients.admitted_to_hospital(
            on_or_before=date,
            returning='binary_flag',
            find_first_match_in_period=True,
            with_these_primary_diagnoses=codelist_from_csv(
                'codelists/opensafely-covid-identification.csv',
                system='icd10',
                column='icd10_code'
            ),
            return_expectations={
                "incidence": 0.1
            }
        )}

def get_covid_vaccine(name, date):
    return{
        name : patients.with_tpp_vaccination_record(
            target_disease_matches="SARS-2 CORONAVIRUS",
            on_or_before=date,
            returning='binary_flag',
            find_first_match_in_period=True,
            return_expectations={
                "incidence": 0.1
            }
        )}

def get_alcohol(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/opensafely-hazardous-alcohol-drinking.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            'incidence' : 0.1
        }
    )}

def get_cancer(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/user-jkua-cancer.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}

def get_mental_disorder(name, date):
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-mental-and-behavioural-disorders.csv',
            system='ctv3',
            column='code'
        ),
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
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
        between=[max(f'{date} - {n_years} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.1
        }
    )}






def cis_earliest_positive(start_date, n):
    i = 1
    
    # get 1st visit date
    variables = get_visit_date(f'visit_date_{i}', 'visit_date', start_date)
    
    # get corresponding result_mk
    variables.update(get_result_mk(f'result_mk_{i}', 'result_mk', f'visit_date_{i}'))
    
    # get evidence of covid infection history
    variables.update(get_hes_admission(f'covid_hes_{i}', f'visit_date_{i}'))
    variables.update(get_tt_positive(f'covid_tt_{i}', f'visit_date_{i}'))
    variables.update(get_covid_vaccine(f'covid_vaccine_{i}', f'visit_date_{i}'))
    
    # get health history
    variables.update(get_alcohol(f'alcohol_{i}', f'visit_date_{i}'))
    variables.update(get_cancer(f'cancer_{i}', f'visit_date_{i}'))
    variables.update(get_CVD_ctv3(f'CVD_ctv3_{i}', f'visit_date_{i}'))
    variables.update(get_CVD_snomed(f'CVD_snomed_{i}', f'visit_date_{i}'))
    variables.update(get_digestive_disorder(f'digestive_disorder_{i}', f'visit_date_{i}'))
    variables.update(get_hiv_aids(f'hiv_aids_{i}', f'visit_date_{i}'))
    variables.update(get_mental_disorder(f'mental_disorder_{i}', f'visit_date_{i}'))
    variables.update(get_metabolic_disorder(f'metabolic_disorder_{i}', f'visit_date_{i}'))
    variables.update(get_musculoskeletal_ctv3(f'musculoskeletal_ctv3_{i}', f'visit_date_{i}'))
    variables.update(get_musculoskeletal_snomed(f'musculoskeletal_snomed_{i}', f'visit_date_{i}'))
    variables.update(get_neurological_ctv3(f'neurological_ctv3_{i}', f'visit_date_{i}'))
    variables.update(get_neurological_snomed(f'neurological_snomed_{i}', f'visit_date_{i}'))
    variables.update(get_kidney_disorder(f'kidney_disorder_{i}', f'visit_date_{i}'))
    variables.update(get_respiratory_disorder(f'respiratory_disorder_{i}', f'visit_date_{i}'))    
    
    for i in range(2, n+1):
        variables.update(get_visit_date(f'visit_date_{i}', 'visit_date', f'visit_date_{i-1} + 1 days'))
        
        variables.update(get_result_mk(f'result_mk_{i}', 'result_mk', f'visit_date_{i}'))
        
        variables.update(get_alcohol(f'alcohol_{i}', f'visit_date_{i}'))
        variables.update(get_cancer(f'cancer_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_ctv3(f'CVD_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_snomed(f'CVD_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_digestive_disorder(f'digestive_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_snomed(f'hiv_aids_{i}', f'visit_date_{i}'))
        variables.update(get_digestive_disorder(f'digestive_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_hiv_aids(f'hiv_aids_{i}', f'visit_date_{i}'))
        variables.update(get_mental_disorder(f'mental_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_metabolic_disorder(f'metabolic_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_musculoskeletal_ctv3(f'musculoskeletal_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_musculoskeletal_snomed(f'musculoskeletal_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_neurological_ctv3(f'neurological_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_neurological_snomed(f'neurological_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_kidney_disorder(f'kidney_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_respiratory_disorder(f'respiratory_disorder_{i}', f'visit_date_{i}'))  
        
        variables.update(get_hes_admission(f'covid_hes_{i}', f'visit_date_{i}'))
        variables.update(get_tt_positive(f'covid_tt_{i}', f'visit_date_{i}'))
        variables.update(get_covid_vaccine(f'covid_vaccine_{i}', f'visit_date_{i}'))
        
    return variables
    

study = StudyDefinition(
    
    population=patients.all(),

    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "uniform",
        "incidence": 1
    },

    # Return visit level CIS data
    **cis_earliest_positive(start_date=start_date, n=n_visits)
    
)

