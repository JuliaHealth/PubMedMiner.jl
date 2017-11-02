# using BioMedQuery.Processes
# using BioMedQuery.Entrez
# using BioMedQuery.UMLS
# using JLD
# using MySQL
# using BCBIVizUtils
# using Colors
using JLD
using PubMedMiner


"""
    epilepsy_comorbidities(;overwrite = true)

PuMed/Medline comorbidities for Epilepsy

Code by: Isabel Restrepo
BCBI - Brown University
Version: Julia 0.6

Before running, configure your MySQL onnection by adding to ~/.juliarc.jl
the following variables:

@everywhere ENV["PUBMEDMINER_DB_HOST"]="db_host"
@everywhere ENV["PUBMEDMINER_DB_USER"]="your_user"
@everywhere ENV["PUBMEDMINER_DB_PSSWD"]="your_password"

You alseo need to configure the email addess associated with you NCBI account,
and USER and PASSWD associated with your UMLS/UTS account.
"""
function epilepsy_semantic_occurrences(;overwrite=true)

    # Settings
    mh = "Epilepsy"
    concept = "Disease or Syndrome"

    info("----------------Start: umls_semantic_occurrences")             
    save_semantic_occurrences(mh, concept; overwrite = overwrite)     
end

# julia> @time epilepsy_semantic_occurrences(overwrite=true)
# INFO: ----------------Start: umls_semantic_occurrences
# INFO: 66720 Articles related to MH:Epilepsy
# INFO: ----------------------------------------
# INFO: Start all articles
# INFO: Using concept table: MESH_T047
# 211.869394 seconds (8.32 M allocations: 281.440 MiB, 0.04% gc time)


"""
epilepsy_comorbidities(;overwrite = true)

PuMed/Medline comorbidities for Epilepsy

Code by: Isabel Restrepo
BCBI - Brown University
Version: Julia 0.6

Before running, configure your MySQL onnection by adding to ~/.juliarc.jl
the following variables:

@everywhere ENV["PUBMEDMINER_DB_HOST"]="db_host"
@everywhere ENV["PUBMEDMINER_DB_USER"]="your_user"
@everywhere ENV["PUBMEDMINER_DB_PSSWD"]="your_password"

You alseo need to configure the email addess associated with you NCBI account,
and USER and PASSWD associated with your UMLS/UTS account.
"""
function colonic_neoplasms_semantic_occurrences(;overwrite=true)

    # Settings
    mh = "Colonic Neoplasms"
    concepts = ("Disease or Syndrome", "Mental or Behavioral Dysfunction", "Neoplastic Process");
    info("----------------Start: umls_semantic_occurrences")             
    save_semantic_occurrences(mh, concepts...; overwrite = overwrite)     
end

# @time colonic_neoplasms_semantic_occurrences(;overwrite=true)
# julia -p 2 comorbitidies_local_medline.jl 
# INFO: ----------------Start: umls_semantic_occurrences
# INFO: 63304 Articles related to MH:Colonic Neoplasms
# INFO: ----------------------------------------
# INFO: Start all articles
# INFO: Using concept table: MESH_T047
# Disease or Syndrome: 271.139750 seconds (7.96 M allocations: 271.182 MiB, 0.03% gc time)
# Mental or Behavioral Dysfunction: Short...
# Neoplastic Process: 1120.822182 seconds (8.06 M allocations: 275.496 MiB, 0.01% gc time)
