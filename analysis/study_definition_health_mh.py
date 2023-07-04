from cohortextractor import (
    StudyDefinition,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
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
    We should get a new column for each visit date up to 25 visits. 
    Our output from this code & this variable should be columns names -> visit_date_0, visit_date_1, visit_date_2, .....
    """   
    return {name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date'
            )}

# Load and combine 2 snomed codes on Common Mental Disorders (CMD) into 1 code
get_cmd_h1 = codelist_from_csv('codelists/ons-historic-anxiety-and-depression-diagnosis-codes.csv', system='snomed', column='code')
get_cmd_h2 = codelist_from_csv('codelists/ons-depression-and-anxiety-diagnoses-and-symptoms-excluding-specific-anxieties.csv', system='snomed', column='code')

#combine the CMD code lists 
ons_cmd_codes = combine_codelists(get_cmd_h1, get_cmd_h2)

def get_CMD_history(name, date):
    """
    This code returns binary flag and a col name for a patients who have a clinical 
    record for Common Mental Disorder. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years. Patients with a code that matches codes in the CMD codelists will be assigned 1.
    """   
    return {name : patients.with_these_clinical_events(
        codelist=ons_cmd_codes,
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        }
    )}


def get_CMD_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients with a clinical record for Common Mental Disorder. The col name should be a date variable, 
    e.g., cmd_outcome_date_0, cmd_outcome_date_1, cmd_outcome_date_2, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.

    """   
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
            "incidence": 0.05
        }
    )}

def get_CMD_hospital_history(name, date):
    """
    This code returns binary flag and a col name for patients who have had a  
    hospital admission for Common Mental Disorder. It looks at the last match (most recent) 
    match in the reporting period or in the previous 5 years. Patients with a code that 
    matches codes in the CMD codelists will be assigned 1.
    """   
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses = codelist_from_csv(
            'codelists/ons-depression-and-anxiety-excluding-specific-anxieties.csv',
            system='icd10',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        }
    )}

def get_CMD_hospital_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients who have been admitted to a hospital for Common Mental Disorder. 
    The column should be a date variable, 
    e.g., cmd_outcome_date_hospital_0, cmd_outcome_date_hospital_1, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.
    """ 
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
            "incidence": 0.05
        }
    )}

# load 2 smi codes to combine (this was previously done in R)
get_smi_h1 = codelist_from_csv('codelists/ons-serious-mental-illness-schizophrenia-bipolar-disorder-psychosis.csv', system='snomed', column='code')
get_smi_h2 = codelist_from_csv('codelists/ons-historic-serious-mental-illness-diagnosis-codes.csv', system='snomed', column='code')

#combine the SMI code list 
ons_smi_codes = combine_codelists(get_smi_h1, get_smi_h2)

def get_SMI_history(name, date):
    """
    This code returns binary flag and a col name for a patients who have a clinical 
    record for Serious Mental Illness (SMI). It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years. Patients with a code that matches codes in the SMI codelists will be assigned 1.
    """   
    return {name : patients.with_these_clinical_events(
        codelist = ons_smi_codes,
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        }
    )}


def get_SMI_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients with a clinical record for Serious Mental Illness (SMI). The column should be a date variable, 
    e.g., smi_outcome_date_0, smi_outcome_date_1, smi_outcome_date_2, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.

    """ 
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
            "incidence": 0.05
        }
    )}

def get_SMI_hospital_history(name, date):
    """
    This code returns binary flag and a col name for patients who have had a  
    hospital admission for Serious Mental Illness (SMI). It looks at the last match (most recent) 
    match in the reporting period or in the previous 5 years. Patients with a code that 
    matches codes in the SMI codelists will be assigned 1.
    """  
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
            "incidence": 0.05
        }
    )}

def get_SMI_hospital_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients who have been admitted to a hospital for Serious Mental Illnes. 
    The column should be a date variable, 
    e.g., smi_outcome_date_hospital_0, smi_outcome_date_hospital_1, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.
    """ 
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
            "incidence": 0.05
        }
    )}


# load 2 self-harm codes to combine (previously in R)
get_self_harm_h1 = codelist_from_csv('codelists/ons-historic-self-harm-codes.csv', system='snomed', column='code')
get_self_harm_h2 = codelist_from_csv('codelists/ons-self-harm-intentional-and-undetermined-intent.csv', system='snomed', column='code')

#combine the self-harm code list 
ons_self_harm_codes = combine_codelists(get_self_harm_h1, get_self_harm_h2)

def get_self_harm_history(name, date):
    """
    This code returns binary flag and a col name for a patients who have a clinical 
    record for self-harm. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years. Patients with a code that matches codes in the self-harm codelists will be assigned 1.
    """   
    return {name : patients.with_these_clinical_events(
        codelist = ons_self_harm_codes,
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        }
    )}

def get_self_harm_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients with a clinical record for self-harm. The column should be a date variable, 
    e.g., self_harm_outcome_date_0, self_harm_outcome_date_1, self_harm_outcome_date_2, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.

    """ 
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
            "incidence": 0.05
        }
    )}

def get_self_harm_hospital_history(name, date):
    """
    This code returns binary flag and a col name for patients who have had a  
    hospital admission for self-harm. It looks at the last match (most recent) 
    match in the reporting period or in the previous 5 years. Patients with a code that 
    matches codes in the self-harm codelists will be assigned 1.
    """  
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
            "incidence": 0.05
        }
    )}

def get_self_harm_hospital_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients who have been admitted to a hospital for Self-harm. 
    The column should be a date variable, 
    e.g., self_harm_outcome_date_0, self_harm_outcome_date_1, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.
    """ 
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
            "incidence": 0.05
        }
    )}

def get_other_mood_disorder_hospital_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients who have been admitted to a hospital for other mood disorder. 
    The column should be a date variable, 
    e.g., other_mood_disorder_hospital_outcome_date_0, other_mood_disorder_hospital_outcome_date_1, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.
    """ 
    return {name : patients.admitted_to_hospital(
        with_these_primary_diagnoses=codelist_from_csv(
            'codelists/ons-unspecified-mood-disorders.csv',
            system='icd10',
            column='code'
        ),
        between=[date, end_date],
        returning='date_admitted',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        }
    )}

def get_other_mood_disorder_diagnosis_outcome(name, date):
    """
    This code should return first match in the study period, returning column name for
    patients with a clinical record for other mood disorder. The column should be a date variable, 
    e.g., other_mood_disorder_diagnosis_outcome_date_0, other_mood_disorder_diagnosis_outcome_date_1, ...... 

    The match should be within the reporting period but more specifically between the visit_date & end_date.
    """ 
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-mood-disorder.csv',
            system='snomed',
            column='code'
        ),
        between=[date, end_date],
        returning='date',
        date_format='YYYY-MM-DD',
        find_first_match_in_period=True,
        return_expectations={
            "incidence": 0.05
        }
    )}   

def get_other_mood_disorder_hospital_history(name, date):
    """
    This code returns binary flag and a col name for patients who have had a  
    hospital admission for Other Mood Disorder. It looks at the last match (most recent) 
    match in the reporting period or in the previous 5 years. Patients with a code that 
    matches codes in the Other Mood Disorder codelists will be assigned 1.
    """  
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
            "incidence": 0.05
        }
    )}

def get_other_mood_disorder_diagnosis_history(name, date):
    """
    This code returns binary flag and a col name for a patients who have a clinical 
    record for Other Mood Disorder. It looks at the last match (most recent) match in the reporting 
    period or in the previous 5 years. Patients with a code that matches codes in the Other Mood Disorder 
    codelists will be assigned 1.
    """   
    return {name : patients.with_these_clinical_events(
        codelist=codelist_from_csv(
            'codelists/ons-mood-disorder.csv',
            system='snomed',
            column='code'
        ),
        between=[max(f'{date} - {n_years_back} years', '2016-01-01'), date],
        returning='binary_flag',
        find_last_match_in_period=True,
        return_expectations={
            "incidence": 0.05
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


        # mental health history
        variables.update(get_CMD_history(f'cmd_history_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_history(f'smi_history_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_history(f'self_harm_history_{i}', f'visit_date_{i}'))
        variables.update(get_CMD_hospital_history(f'cmd_history_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_hospital_history(f'smi_history_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_hospital_history(f'self_harm_history_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_other_mood_disorder_hospital_history(f'other_mood_disorder_hospital_history_{i}', f'visit_date_{i}'))
        variables.update(get_other_mood_disorder_diagnosis_history(f'other_mood_disorder_diagnosis_history_{i}', f'visit_date_{i}'))
        
        # get mental health outcomes
        variables.update(get_CMD_outcome(f'cmd_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_outcome(f'smi_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_outcome(f'self_harm_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_CMD_hospital_outcome(f'cmd_outcome_date_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_SMI_hospital_outcome(f'smi_outcome_date_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_self_harm_hospital_outcome(f'self_harm_outcome_date_hospital_{i}', f'visit_date_{i}'))
        variables.update(get_other_mood_disorder_hospital_outcome(f'other_mood_disorder_hospital_outcome_date_{i}', f'visit_date_{i}'))
        variables.update(get_other_mood_disorder_diagnosis_outcome(f'other_mood_disorder_diagnosis_outcome_date_{i}', f'visit_date_{i}'))
    
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