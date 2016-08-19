<!--
@Author: isa
@Date:   2016-05-12T16:51:24-04:00
@Last modified by:   isa
@Last modified time: 2016-05-13T17:14:23-04:00
-->



# PubMedMiner.jl

[![Build Status](https://travis-ci.org/bcbi/PubMedMiner.jl.svg?branch=master)](https://travis-ci.org/bcbi/PubMedMiner.jl)

This package provides a set of tools and executables to run and analyze a
PubMed/Medline search using MESH descriptors and their corresponding UMLS concept

## Installation
```{Julia}
Pkg.clone("https://github.com/bcbi/PubMedMiner.jl.git")
```

## Executables

### Search PubMed

 Search PubMed for articles to a related term. From the terminal...

```
db_path="./apnea.db"
path_to_scripts="."

entrez_email="myemail@myclient.com"
entrez_search_term="obstructive sleep apnea[MeSH Major Topic]"

julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --db_path "$db_path"  search --email  "$entrez_email" --search_term "$entrez_search_term" --max_articles 50 --verbose

```

**Note**
* email: valid email address (otherwise pubmed will block you)
* search_term : search string to submit to PubMed
    e.g asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication]
    see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string
* db_path: path to output database
* article_max : Flag. If present it limits the maximum number of articles to return.
If flag is removed, defaults to maximum Int64
* verbose: Flag - If present, the NCBI xml response files are saved to current directory


### Build a MESH-descriptors to UMLS-concept MAP

The previous search saves all MESH descriptors associated with a single article.
`pubMedMesh2Umls.jl` looks up the UMLS semantic type associated with each of the MESH
descriptors in the database


```
db_path="./apnea.db" #path to pubMedMesh2Umls.jl
path_to_scripts="."

umls_username="umls_user"
umls_password="umls_password"

julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --db_path "$db_path"  search --email  "$entrez_email" --search_term "$entrez_search_term" --max_articles 50 --verbose

```


### Retrieve an occurance matrix for a UMLS concept

Compute a sparse matrix indicating the presence of MESH descriptors associated
with a given semantic type in all articles of the input database. This executable
saves the following variables to the results directory.

**Output**

* `des_ind_dict`: Dictionary matching row number to descriptor names
* `disease_occurances` : Sparse matrix. The columns correspond to a feature
vector, where each row is a MESH descriptor. There are as many
columns as articles. The occurance/abscense of a descriptor is labeled as 1/0

```
db_path="./apnea.db"
path_to_scripts="." #path to pubMedOccur.jl

umls_concept="Mental or Behavioral Dysfunction"
results_dir="./test"

julia "$path_to_scripts"/pubMedOccur.jl --db_path "$db_path" --umls_concept "$umls_concept" --results_dir "$results_dir"
```


###Run all steps

Use main.sh to run one or more of the steps explained above. You will need to
set up paths, credentials and indicate the steps to run by uncommenting the boolean
flags:
```
search=true
mesh_umls_map=true
occur=true
```
