from cohortextractor import (
    StudyDefinition,
    codelist,
    codelist_from_csv,
    combine_codelists,
    filter_codes_by_category,
    patients
)


start_date = '2020-01-24'
end_date = '2022-10-19'
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

def get_ethnicity(name):
    return{
        name : patients.with_an_ons_cis_record(
            returning='ethnicity',
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "category": {"ratios": {"White-British": 0.49, 
                                        "Any other ethnic group": 0.51}},
                "incidence": 1,
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

def get_region(name):
    return{
        name : patients.with_an_ons_cis_record(
            returning='gor9d',
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "category": {"ratios": {"E12000001": 0.1,
                                        "E12000002": 0.1,
                                        "E12000003": 0.1,
                                        "E12000004": 0.1,
                                        "E12000005": 0.1,
                                        "E12000006": 0.1,
                                        "E12000007": 0.15,
                                        "E12000008": 0.15,
                                        "E12000009": 0.1}},
                    "incidence": 1,
            }
        )}

def get_hhsize(name):
    return{
        name: patients.with_an_ons_cis_record(
            returning ='hhsize',
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "category": {"ratios":{"1": 0.2,
                                       "2": 0.2,
                                       "3": 0.2,
                                       "4": 0.2,
                                       "5+": 0.2}},
                "incidence": 1,
            }
        )}

def get_work_status(name):
    return{
        name: patients.with_an_ons_cis_record(
            returning ='work_status',
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "category": {"ratios":{"Employed": 0.2,
                                       "Self-employed": 0.2,
                                       "Furloughed (temporarily not working)": 0.2,
                                       "Not working (unemployed, retired, long-term sick etc.)": 0.2,
                                       "Student": 0.2}},
                "incidence": 1,
            }
        )}

def get_work_status_v1(name):
    return{
        name: patients.with_an_ons_cis_record(
            returning ='work_status_v1',
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "category": {"ratios":{"Employed and currently working": 0.1,
                                       "Employed and currently not working": 0.1,
                                       "Self-employed and currently working": 0.1,
                                       "Self-employed and currently not working": 0.1,
                                       "Looking for paid work and able to start": 0.1,
                                       "Not working and not looking for work": 0.1,
                                       "Retired": 0.1,
                                       "Child under 5y not attending child care": 0.1,
                                       "Child under 5y attending child care": 0.1,
                                       "5y and older in full-time education": 0.1}},
                "incidence": 1,
            }
        )}

def get_self_isolating_v1(name):
    return{
        name: patients.with_an_ons_cis_record(
            returning ='self_isolating_v1',
            between=[start_date, end_date],
            find_last_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date',
            return_expectations={
                "category": {"ratios":{"No": 0.25,
                                       "Yes, you have/have had symptoms": 0.25,
                                       "Yes, someone you live with had symptoms": 0.25,
                                       "Yes, forother reasons (e.g. going into hospital, quarantining)": 0.25}},
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
            # get ethnicity
            variables.update(get_ethnicity('ethnicity'))
            #get region
            variables.update(get_region('gor9d'))
            #get hhsize
            variables.update(get_hhsize('hhsize'))
            # get work_status and work_status_v1
            variables.update(get_work_status('work_status'))
            variables.update(get_work_status_v1('work_status_v1'))
            #get self_isolating
            variables.update(get_self_isolating_v1('self_isolating_v1'))

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
