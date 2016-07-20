#!/bin/bash
# @Author: isa
# @Date:   2016-05-06T16:16:43-04:00
# @Last modified by:   isa
# @Last modified time: 2016-05-13T16:50:43-04:00


search=false
mesh_umls_map=false
occur=false

#UNCOMMENT ONE OR MORE TO RUN
# search=true
# mesh_umls_map=true
# occur=true

#****GLOBALS******
db_path="./apnea.db"
#path to pubMedSearch.jl, pubMedMesh2Umls.jl and pubMedOccur.jl
path_to_scripts="."

if $search; then
    echo "Running: search"

    entrez_email="myemail@myclient.com"
    entrez_search_term="obstructive sleep apnea[MeSH Major Topic]"

    julia "$path_to_scripts"/pubMedSearch.jl   --clean_db --db_path "$db_path"  search --email  "$entrez_email" --search_term "$entrez_search_term" --max_articles 50 --verbose

    #Note: Removing --max_articles, gets all available articles
    # --verbose: saves NCBI xml responses to local directory, to skip, remove this flag

fi

if $mesh_umls_map; then
    echo "Running: mesh_umls_map"

    umls_username="umls_user"
    umls_password="umls_password"

    julia "$path_to_scripts"/pubMedMesh2Umls.jl --db_path "$db_path" --umls_username "$umls_username" --umls_password "$umls_password"
fi

if $occur; then
    echo "Running: occur"

    umls_concept="Mental or Behavioral Dysfunction"
    results_dir="./test"

    echo $umls_concept
    julia "$path_to_scripts"/pubMedOccur.jl --db_path "$db_path" --umls_concept "$umls_concept" --results_dir "$results_dir"

fi
