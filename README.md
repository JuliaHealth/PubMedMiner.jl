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

###Main.sh

The shell script main.sh can be used to run one or more of the steps explained below. You will need to
set up paths, credentials and indicate the steps to run by uncommenting the boolean
flags. The follwoing snippet shows the related code

```
search=false
mesh_umls_map=false
occur=false

#UNCOMMENT ONE OR MORE TO RUN
# search=true
# mesh_umls_map=true
# occur=true

#****GLOBALS******

path_to_scripts="pathto/PubMedMiner.jl/exe"

#if using MYSQL these settings are needed
using_mysql=true
host="localhost"
username="root"
password=""
dbname="test_obesity"

#if using SQLite, these settings are needed
using_sqlite=false
db_path="./test_obesity.sqlite.db"
```

After configuring simply type `./main.sh` within the terminal. The steps preformed
by the script are explained below.

#### Database backend
All scripts accept either the *sqlite* or *mysql* command followed by corresponding configuration arguments:

`sqlite --db_path "$db_path"`

`mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"`

### Search PubMed

 Search PubMed for articles to a related term. 

```
entrez_email="my_email@my_client"

entrez_search_term="(obesity[MeSH Major Topic]) AND ("2010"[Date - Publication] : "2012"[Date - Publication])"

if $using_sqlite; then
    julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --email  "$entrez_email" --search_term "$entrez_search_term" --max_article 10 sqlite --db_path "$db_path"
fi
if $using_mysql; then
    julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --email  "$entrez_email" --search_term "$entrez_search_term" --max_article 10 mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"

fi
```

**Note**
* email: valid email address (otherwise pubmed will block you)
* search_term : search string to submit to PubMed
    e.g asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication]
    see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string
* article_max : Flag. If present it limits the maximum number of articles to return.
If flag is removed, defaults to maximum Int64
* verbose: Flag - If present, the NCBI xml response files are saved to current directory


### Build a MESH-descriptors to UMLS-concept MAP

The previous search saves all MESH descriptors associated with a single article.
`pubMedMesh2Umls.jl` looks up the UMLS semantic type associated with each of the MESH
descriptors in the database


```
umls_username="username"
umls_password="password"

if $using_sqlite; then
    julia "$path_to_scripts"/pubMedMesh2Umls.jl --umls_username "$umls_username" --umls_password "$umls_password" sqlite --db_path "$db_path"
fi

if $using_mysql; then
    julia "$path_to_scripts"/pubMedMesh2Umls.jl --umls_username "$umls_username" --umls_password "$umls_password" mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"
fi
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
umls_concept="Disease or Syndrome"
results_dir="./pubmed_miner_results"

if $using_sqlite; then
    julia "$path_to_scripts"/pubMedOccur.jl --umls_concept "$umls_concept" --results_dir "$results_dir" sqlite --db_path "$db_path"
fi

if $using_mysql; then
    julia "$path_to_scripts"/pubMedOccur.jl --umls_concept "$umls_concept" --results_dir "$results_dir" mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"

fi
```
