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
n_visits = 20


def cis_visit_level(name, start_date, n):
    
    def var_signature(name, on_or_after):
        return {
            name : patients.with_an_ons_cis_record(
                returning='visit_date',
                on_or_after=on_or_after,
                find_first_match_in_period=True,
                date_format='YYYY-MM-DD',
                date_filter_column='visit_date')
            }
    
    variables = var_signature(f"{name}_1_date", start_date)
    
    for i in range(2, n+1):
        variables.update(var_signature(
          f"{name}_{i}_date", 
          f"{name}_{i-1}_date + 1 days"))
    
    return variables
    

study = StudyDefinition(
    
    population=patients.all(),

    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 1
    },

    # Return visit level CIS data
    **cis_visit_level('cis_visit_date', '2020-01-24', 5)
    

)
