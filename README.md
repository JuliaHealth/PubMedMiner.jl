<!--
@Author: isa
@Date:   2016-05-12T16:51:24-04:00
@Last modified by:   isa
@Last modified time: 2016-05-13T17:14:23-04:00
-->



# PubMedMiner.jl

This package provides a set of tools and executables to run and analyze a
PubMed/Medline search using MESH descriptors and their corresponding UMLS concept

### Installation
```{Julia}
Pkg.clone("https://github.com/bcbi/PubMedMiner.jl.git")
```

### Examples
**Search PubMed**

 To search 100  articles related to *obesity* published between *2000-2002*, you can evoke from terminal:

`julia ./exe/pubMedSearch.jl --clean_db --db_path "./test_db.sqlite" search --email  "email@domain.com" --max_articles 100 --search_term "obesity" --start_date "2000" --end_date "2002" `

*The results are stored in a Sqlite database

*Make sure to specify your real email address as NLM  requires it


**Map MESH Descriptors to UMLS concept**

The previous search saves all MESH descriptors associated with a single article.
`pubMedMesh2Umls.jl` looks up the UMLS concept associated with each of the MESH
descriptors


`julia ./exe/pubMedMesh2Umls.jl --db_path "path_to_database" umls_map --umls_username "umls_user" --umls_password "umls_password"`


**Retrieve an occurance matrix for a UMLS concept**

E.g For umls concept "Disease or Syndrome", `pubMedOccur.jl` ouputs matrix of ones and zeros, where
each column corresponds to an article and each row corresponds to a disease.

`julia ./exe/pubMedOccur.jl --db_path "path_to_database" occur --umls_concept "Disease or Syndrome --results_file "./occur.jdl""`


**Run all steps**
`julia ./exe/pubMedMain.jl --clean_db --db_path "./test_db.sqlite" all --email  "email@domain.com" --max_articles 100 --search_term "obesity" --start_date "2000" --end_date "2002" --umls_username "umls_user" --umls_password "umls_password" --umls_concept "Disease or Syndrome" --results_file "./occur.jdl"`
