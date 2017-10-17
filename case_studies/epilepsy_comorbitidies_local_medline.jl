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
    epilepsy_comorbidities(;    results_dir = "results/",
                                max_articles = typemax(Int64),
                                run_pubmed_search_and_save = true,
                                run_mesh2umls_map = true,
                                filter_semantic_occurrences  = true,
                                comorbidity_concept = "Disease or Syndrome")

PuMed/Medline comorbidities for Epilepsy

Code by: Isabel Restrepo
BCBI - Brown University
Version: Julia 0.6

Before running, configure your MySQL onnection by adding to ~/.juliarc.jl
the following variables:

ENV["PUBMEDMINER_DB_HOST"]="db_host"
ENV["PUBMEDMINER_DB_USER"]="your_user"
ENV["PUBMEDMINER_DB_PSSWD"]="your_password"

You alseo need to configure the email addess associated with you NCBI account,
and USER and PASSWD associated with your UMLS/UTS account.
"""
function epilepsy_comorbidities(; results_dir = "results/",
                                  max_articles = typemax(Int64),
                                  run_pubmed_search_and_save = true,
                                  run_mesh2umls_map = false,
                                  filter_semantic_occurrences  = false,
                                  comorbidity_concept = "Disease or Syndrome",
                                  verbose = false, overwrite=true)

    # Settings
    db = DatabaseConnection()
    mh = "Epilepsy"
    concept = "Disease or Syndrome"

    info("----------------Start: umls_semantic_occurrences")             
    occur_data = umls_semantic_occurrences(mh, concept)

    # if !isdir(results_dir)
    #     mkdir(results_dir)
    # end

    # occur_path = results_dir*"/$(mh)_occurrence.jdl"
    # jldopen(occur_path, "w") do file
    #     write(file, "occur", occur)
    # end
    # info("----------------Done: umls_semantic_occurrences")          
    


end


# epilepsy_comorbidities(results_dir = "/Users/isa/dropbox_brown/results/epilepsy_pubmed_comorbidities",
# max_articles = 5, run_pubmed_search_and_save = false)
epilepsy_comorbidities(results_dir = "/Users/isa/dropbox_brown/results/epilepsy_pubmed_comorbidities",
max_articles = 5)


#---------------times:

