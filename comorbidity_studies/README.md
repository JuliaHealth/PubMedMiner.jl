# Sample (PubMed) Comorbidity Studies

This repository contains Jupyter notebooks that use tools and pipelines developed in Julia at The Brown's Center for BioMedical Informatics to explore comorbidities in PubMed Articles


## Brown Databases

If you are a Brown reaseracher, the studies can be run faster by accessing Brown's databases. You will need to have select access to the following schemas on BCBI's database server:
* medline
* umls_meta
* pubmed_miner

For more information or help setting up your user, contact us.

Three examples of comorbitidy studies are presented via Jupyter notebooks and included in the subdirectory comorbidity_studies. For reproducing the results, please clone this repository. To view the studies, use the following links (nbviewer - github does does noot render the plots)

| [Epilepsy](http://nbviewer.jupyter.org/github/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/brown_databases/epilepsy_comorbidities_server_db.ipynb)   |      [Suicide](http://nbviewer.jupyter.org/github/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/brown_databases/suicide_comorbidities_server_db.ipynb)      |  [Colonic Neoplasmas](http://nbviewer.jupyter.org/github/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/brown_databases/colonic_neoplasms_comorbidities_server_db.ipynb) |
|:----------:|:-------------:|:------:|
| [<img src="./figures/cocurrence_graph_epilepsy.png" alt="Drawing" style="width: 200px;"/>](http://nbviewer.jupyter.org/github/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/brown_databases/epilepsy_comorbidities_server_db.ipynb)|  [<img src="./figures/cocurrence_graph_suicide.png" alt="Drawing" style="width: 200px;"/>](http://nbviewer.jupyter.org/github/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/brown_databases/suicide_comorbidities_server_db.ipynb) | [<img src="./figures/cocurrence_graph_colonic_neoplasmas.png" alt="Drawing" style="width: 200px;"/>](http://nbviewer.jupyter.org/github/bcbi/PubMedMiner.jl/blob/master/comorbidity_studies/brown_databases/colonic_neoplasms_comorbidities_server_db.ipynb) |
   

## Local Resources

The studies can also be run on your local workstationg by querying the ENTERZ and UMLS APIs and using related Julia packages such us BioMedQuery. Basic Julia scripts are provided under local_databases directory. Related Jupyter Notebooks are coming soon
