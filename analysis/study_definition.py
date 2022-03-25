# import required functions from cohortextractor package
from cohortextractor import StudyDefinition, patients, codelist, codelist_from_csv  
     

from codelists import *


study = StudyDefinition(
    default_expectations={
        # apply to all subsequently defined variables; override in return_expectations in var extractor function when necessary
        # yet more comment
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.5,
    },
    population=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
    ),

     age=patients.age_as_of(
        "2019-09-01",
        return_expectations={
             # every var needs return_expectations argument (except population), defining distribution, more comment
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
)