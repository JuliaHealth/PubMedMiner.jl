using BioMedQuery.Processes
using BioMedQuery.Entrez
using BioMedQuery.UMLS
using JLD
using MySQL


"""
    function osa_pychiatric_comorbidities()
PuMed/Medline comorbidities explained in the following paper
Identifying Psychiatric Comorbidities for Obstructive Sleep Apnea in
the Biomedical Literature and Electronic Health Record
Haddad and Chen. Brown University. 2016

Code by: Isabel Restrepo
BCBI - Brown University
Version: Julia 0.5

Before running, configure your MySQL onnection by adding to ~/.juliarc.jl
the following variables:

ENV["OSA_DB_HOST"]="db_host"
ENV["OSA_DB_USER"]="your_user"
ENV["OSA_DB_PSSWD"]="your_password"

You alseo need to configure the email addess associated with you NCBI account,
and USER and PASSWD associated with your UMLS/UTS account.
"""

using BCBIVizUtils
using Colors
using JLD

function load_occurrance_file(; results_dir = "results/",)
    file  = jldopen(results_dir* "/occur_sp.jdl", "r")
    occur = read(file, "occur")
    # display(occur)
    file  = jldopen(results_dir* "/mesh2ind.jdl", "r")
    mesh2ind = read(file, "mesh2ind")

    # display(mesh2ind)
    #invert map
    ind2label = Dict()
    for key  in keys(mesh2ind)
        val = mesh2ind[key]
        ind2label[val] = key
    end
    labels = Array{ASCIIString}(length(ind2label))
    for i in range(1,length(ind2label))
        labels[i] = ind2label[i]
    end

    coo = occur* occur.'

    graph = BCBIVizUtils.coo2graph(coo)
    colors = distinguishable_colors(length(ind2label), RGB(1,0,0))

    return graph, labels, colors
end


function plot3D()
    graph, labels, colors = init()
    BCBIVizUtils.graph2plotlyjs3D(graph, labels, colors)
end


function osa_pychiatric_comorbidities(; results_dir = "results/",
                                        max_articles = typemax(Int64),
                                        run_pubmed_search_and_save = true,
                                        run_mesh2umls_map = true,
                                        filter_semantic_occurrences  = true,)

    # 1. Database configuration
    db_host = ENV["OSA_DB_HOST"]
    mysql_usr=ENV["OSA_DB_USER"]
    mysql_pswd=ENV["OSA_DB_PSSWD"]
    dbname="osa_pychiatric_comorbidities"
    overwrite=true
    db = nothing

    db_config = Dict(:host=>db_host,
                  :dbname=>dbname,
                  :username=>mysql_usr,
                  :pswd=>mysql_pswd,
                  :overwrite=>overwrite)


    # 2. PubMed Search
    if run_pubmed_search_and_save
        email= ENV["NCBI_EMAIL"]
        search_term="(sleep apnea, obstructive[MeSH Major Topic])"
        overwrite=true
        verbose = false

        db = pubmed_search_and_save(email, search_term, max_articles,
        save_efetch_mysql, db_config, verbose)
    end

    #3. MAP all MeSH to UMLS concepts
    if run_mesh2umls_map

        if db == nothing
            db = mysql_connect(db_host, mysql_usr, mysql_pswd, dbname)
        end
        user = ENV["UMLS_USER"]
        psswd = ENV["UMLS_PSSWD"]
        credentials = Credentials(user, psswd)
        append = false

        map_mesh_to_umls_async!(db, credentials; append_results=append)
    end

    #4. Filter those that are only Psychiatric Mental Disorders
    if filter_semantic_occurrences

        if db == nothing
            db = mysql_connect(db_host, mysql_usr, mysql_pswd, dbname)
        end

        umls_concept = "Mental or Behavioral Dysfunction"

        if !isdir(results_dir)
            mkdir(results_dir)
        end

        occur_path = results_dir*"/occur_sp.jdl"
        labels2ind_path = results_dir*"/labels2ind.jdl"

        labels2ind, occur = umls_semantic_occurrences(db, umls_concept)

        println("-------------------------------------------------------------")
        println("Output Descritor to Index Dictionary")
        println(labels2ind)
        println("-------------------------------------------------------------")

        println("-------------------------------------------------------------")
        println("Output Data Matrix")
        println(occur)
        println("-------------------------------------------------------------")

        # save(occur_path, "occur", occur)
        jldopen(occur_path, "w") do file
         write(file, "occur", occur)
        end
        jldopen(labels2ind_path, "w") do file
         write(file, "labels2ind", labels2ind)
        end
    end


    #5. Plot comorbidities graph

end


# osa_pychiatric_comorbidities(results_dir = "/Users/isa/dropbox_brown/results/osa_pychiatric_pubmed_comorbidities",
# max_articles = 5, run_pubmed_search_and_save = false)

osa_pychiatric_comorbidities(results_dir = "/Users/isa/dropbox_brown/results/osa_pychiatric_pubmed_comorbidities", run_pubmed_search_and_save = false)
