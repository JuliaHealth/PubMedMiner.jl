#!/bin/bash
# @Author: Isabel Restrepo
# @Date:   2016-05-06T16:16:43-04:00
# @Last modified by:   isa
# @Last modified time: 2016-05-13T16:50:43-04:00


search=false
mesh_umls_map=false
occur=false

#UNCOMMENT ONE OR MORE TO RUN
# search=true
# mesh_umls_map=true
occur=true

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

if $search; then
    echo "Running: search"

    entrez_email="my_email@my_client"

    # search_term : search string to submit to PubMed
    #     e.g (asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication])
    #     see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string

    entrez_search_term="(obesity[MeSH Major Topic]) AND ("2010"[Date - Publication] : "2012"[Date - Publication])"

    if $using_sqlite; then
        julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --email  "$entrez_email" --search_term "$entrez_search_term" --max_article 10 sqlite --db_path "$db_path"
    fi
    if $using_mysql; then
        julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --email  "$entrez_email" --search_term "$entrez_search_term" --max_article 10 mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"

    fi
    #Note: Removing --max_articles, gets all available articles
    # --verbose: saves NCBI xml responses to local directory, to skip, remove this flag

fi

if $mesh_umls_map; then
    echo "Running: mesh_umls_map"

    umls_username="username"
    umls_password="password"

    if $using_sqlite; then
        julia "$path_to_scripts"/pubMedMesh2Umls.jl --umls_username "$umls_username" --umls_password "$umls_password" sqlite --db_path "$db_path"
    fi

    if $using_mysql; then
        julia "$path_to_scripts"/pubMedMesh2Umls.jl --umls_username "$umls_username" --umls_password "$umls_password" mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"
    fi
fi

if $occur; then
    echo "Running: occur"

    # umls_concept="Mental or Behavioral Dysfunction"
    umls_concept="Disease or Syndrome"
    results_dir="./pubmed_miner_results"

    if $using_sqlite; then
        julia "$path_to_scripts"/pubMedOccur.jl --umls_concept "$umls_concept" --results_dir "$results_dir" sqlite --db_path "$db_path"
    fi

    if $using_mysql; then
        julia "$path_to_scripts"/pubMedOccur.jl --umls_concept "$umls_concept" --results_dir "$results_dir" mysql --host "$host" --username "$username" --password "$password" --dbname "$dbname"

    fi

fi
