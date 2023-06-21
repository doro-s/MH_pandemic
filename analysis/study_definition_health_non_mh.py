from cohortextractor import (
    StudyDefinition,
    codelist_from_csv,
    patients
)

import pprint as pp


start_date = '2020-01-24'
end_date = '2022-10-19'
n_visits = 25
n_years_back = 5

def get_visit_date(name, col, date):
    """
    This function should return first match/event in the study period, returning column name for
    patients with a record on the Covid Infection Survey. 
    """   
    return {name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date'
            )}

def get_alcohol(name, date):
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for alcohol. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for obesity. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-obese-bmi-30.csv',
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
    """
    This function returns most recent BMI and a column name to identfy a patient. 
    It looks back 5 years and returns most recent.
    """
    return {name : patients.most_recent_bmi(
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        return_expectations={
            'float' : {'distribution': 'normal', 'mean': 28, 'stddev': 8},
            'incidence' : 0.9
        }
    )}

def get_cancer(name, date):
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for cancer. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for CVD (ctv3). It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """ 
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for CVD (snomed). It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """ 
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for digestive disorder. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for HIV. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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

def get_metabolic_disorder(name, date):
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for metabolic disorder. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for musculoskeletal disorder (ctv3). It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for musculoskeletal disorder (snomed). It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for neurological disorder (ctv3). It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patient who has a clinical 
    record for neurological disorder (snomed). It looks at the last match (most recent) 
    match in the reporting period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patients who have a clinical 
    record for kidney disorder. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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
    """
    This function returns binary flag and a col name for a patients who have a clinical 
    record for respiratory disorder. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years.  
    """
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

def get_mental_behavioural_disorder(name, date):
    """
    This function returns binary flag and a col name for a patients who have a clinical 
    record for mental and behavioural disorder. It looks at the last match (most recent) 
    match in the reporting period or in the previous 5 years.  
    """
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-mental-and-behavioural-disorders.csv',
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



def cis_earliest_positive(start_date, n):
    
    for i in range(n+1):
        
        if i == 0:
            # get 1st visit date based on study start date
            variables = get_visit_date(f'visit_date_{i}', 'visit_date', start_date)
        else:
            # get nth visit date
            variables.update(get_visit_date(f'visit_date_{i}', 'visit_date', f'visit_date_{i-1} + 1 days'))
        
        
        # get health history
        variables.update(get_alcohol(f'alcohol_{i}', f'visit_date_{i}'))
        variables.update(get_obesity(f'obesity_{i}', f'visit_date_{i}'))
        variables.update(get_bmi(f'bmi_{i}', f'visit_date_{i}'))
        variables.update(get_cancer(f'cancer_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_ctv3(f'CVD_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_CVD_snomed(f'CVD_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_digestive_disorder(f'digestive_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_hiv_aids(f'hiv_aids_{i}', f'visit_date_{i}'))
        variables.update(get_mental_behavioural_disorder(f'mental_behavioural_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_metabolic_disorder(f'metabolic_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_musculoskeletal_ctv3(f'musculoskeletal_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_musculoskeletal_snomed(f'musculoskeletal_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_neurological_ctv3(f'neurological_ctv3_{i}', f'visit_date_{i}'))
        variables.update(get_neurological_snomed(f'neurological_snomed_{i}', f'visit_date_{i}'))
        variables.update(get_kidney_disorder(f'kidney_disorder_{i}', f'visit_date_{i}'))
        variables.update(get_respiratory_disorder(f'respiratory_disorder_{i}', f'visit_date_{i}'))

    
    return variables
    

study = StudyDefinition(

#filter the study population so that we only get people who are in Covid Infection Survey
#  
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