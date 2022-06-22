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

def get_visit_date(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_format='YYYY-MM-DD',
            date_filter_column='visit_date')
            }

def get_result_mk(name, col, date):
    return {
        name : patients.with_an_ons_cis_record(
            returning=col,
            on_or_after=date,
            find_first_match_in_period=True,
            date_filter_column='visit_date',
            return_expectations={
                'category': {
                    'ratios': {0: 0.8, 1: 0.2}
                    }
                })
            }


def cis_earliest_positive(start_date, n):

    visit_date = 'visit_date'
    result_mk = 'result_mk'
    
    # get 1st visit date
    variables = get_visit_date(f'{visit_date}_1', visit_date, start_date)
    
    # get corresponding result_mk
    variables.update(get_result_mk(f'{result_mk}_1', result_mk, f'{visit_date}_1'))
        
    for i in range(2, n+1):
        variables.update(get_visit_date(f'{visit_date}_{i}',
                                        visit_date,
                                        f'{visit_date}_{i-1} + 1 days'))
        
        variables.update(get_result_mk(f'{result_mk}_{i}', 
                                       result_mk, 
                                       f'{visit_date}_{i}'))
    
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

