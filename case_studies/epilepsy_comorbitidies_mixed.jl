using BioMedQuery.Processes
using BioMedQuery.Entrez
using BioMedQuery.UMLS
using JLD
using MySQL
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

    # 1. Database configuration
    db_host = ENV["PUBMEDMINER_DB_HOST"]
    mysql_usr=ENV["PUBMEDMINER_DB_USER"]
    mysql_pswd=ENV["PUBMEDMINER_DB_PSSWD"]
    dbname="pubmed_comorbidities"
    db = nothing

    db_config = Dict(:host=>db_host,
                  :dbname=>dbname,
                  :username=>mysql_usr,
                  :pswd=>mysql_pswd,
                  :overwrite=>overwrite,
                  :tablename=>"article_epilepsy")


    # 2. PubMed Search
    info("----------------Start: pubmed_search_and_save")    
    @time if run_pubmed_search_and_save
        email= ENV["NCBI_EMAIL"]
        search_term="epilepsy[mh]"

        db = pubmed_pmid_search_and_save(email, search_term, max_articles,
        save_pmid_mysql, db_config, verbose)
    end
    info("----------------Done: pubmed_search_and_save")

    # #3. MAP all MeSH to UMLS concepts
    # info("----------------Start: run_mesh2umls_map")       
    # @time if run_mesh2umls_map

    #     if db == nothing
    #         db = mysql_connect(db_host, mysql_usr, mysql_pswd, dbname)
    #     end
    #     user = ENV["UMLS_USER"]
    #     psswd = ENV["UMLS_PSSWD"]
    #     credentials = Credentials(user, psswd)
    #     append = false

    #     map_mesh_to_umls_async!(db, credentials; append_results=append)
    # end
    # info("----------------Done: run_mesh2umls_map")       
    

    #4. Filter those that are only Psychiatric Mental Disorders
    info("----------------Start: filter_semantic_occurrences")          
    @time if filter_semantic_occurrences

        if db == nothing
            db = mysql_connect(db_host, mysql_usr, mysql_pswd, dbname)
        end

        if !isdir(results_dir)
            mkdir(results_dir)
        end

        occur_path = results_dir*"/occur_sp.jdl"
        labels2ind_path = results_dir*"/labels2ind.jdl"

        labels2ind, occur = umls_semantic_occurrences(db, comorbidity_concept)

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
    info("----------------Done: filter_semantic_occurrences")          
    


    #5. Plot comorbidities graph

end


# epilepsy_comorbidities(results_dir = "/Users/isa/dropbox_brown/results/epilepsy_pubmed_comorbidities",
# max_articles = 5, run_pubmed_search_and_save = false)
epilepsy_comorbidities(results_dir = "/Users/isa/dropbox_brown/results/epilepsy_pubmed_comorbidities")


#---------------times:

# INFO: ----------------Done: pubmed_search_and_save
# 52.191503 seconds (1.56 M allocations: 98.617 MiB, 0.06% gc time)
#Maybe this time can be improved by saving all ids at once. 

# INFO: ----------------Done: run_mesh2umls_map

# INFO: ----------------Done: filter_semantic_occurrences
