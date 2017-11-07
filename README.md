<!--
@Author: isa
@Date:   2016-05-12T16:51:24-04:00
@Last modified by:   isa
@Last modified time: 2016-05-13T17:14:23-04:00
-->



# PubMedMiner.jl

<!-- [![Build Status](https://travis-ci.org/bcbi/PubMedMiner.jl.svg?branch=master)](https://travis-ci.org/bcbi/PubMedMiner.jl) -->

This package provides a set of tools and examples to study co-occurrences/comorbidities in PubMed/Medline articles based on MeSH descriptors and UMLS concepts

## Installation
```{Julia}
Pkg.clone("https://github.com/bcbi/PubMedMiner.jl.git")
```

## Dependencies

PubMedMiner depends on MySQL.jl and DataFrames.jl which should be installed automatially by the package manager when clonning this reposity (via Julia). However, many of the examples provided have additional dependencies that will be described accordingly.


## Tools and Examples:

* [Comorbidity Studies](https://github.com/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/README.md)
* [Convinience Executable Files](https://github.com/bcbi/PubMedMiner.jl/tree/master/exe/README.md)
