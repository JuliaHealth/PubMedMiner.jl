# Utilities to mine results from a PubMed/Medline search
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5
module PubMedMiner

export pubmed_search, occurance_matrix, map_mesh_to_umls!

using BioMedQuery.Entrez
using BioMedQuery.Entrez.DB
using BioMedQuery.UMLS
using BioMedQuery.DBUtils

using SQLite
using DataStreams, DataFrames

using LightXML

using XMLconvert

function clean_db(db_path)
    if isfile(db_path)
        rm(db_path)
    end
end

"""
    pubmed_search(email, search_term, article_max::Int64=typemax(Int64),
                       db_path="./pubmed_search.sqlite", verbose=false)
###Arguments

* email: valid email address (otherwise pubmed will block you)
* search_term : search string to submit to PubMed
    e.g (asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication])
    see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string
* article_max : maximum number of articles to return. Defaults to 600,000
* db_path: path to output database
* verbose: of true, the NCBI xml response files are saved to current directory
"""
function pubmed_search(email, search_term, article_max,
                       save_efetch_func, db_config, verbose=false)

    retstart = 0
    retmax = 10000
    db = Nullable{SQLite.DB}()
    article_max = article_max

    if article_max < retmax
        retmax = article_max
    end

    article_total = 0

    for rs=retstart:retmax:(article_max- 1)

        rm = rs + retmax
        if rm > article_max
            retmax = article_max - rs
        end

        println("Fetching ", retmax, " articles, starting at index ", rs)

        #1. Formulate PubMed/MEDLINE search for articles between 2000 and 201
        #with obesity indicated as the major MeSH descriptor.
        println("------Searching Entrez--------")
        search_dic = Dict("db"=>"pubmed","term" => search_term,
        "retstart" => rs, "retmax"=>retmax, "tool" =>"BioJulia",
        "email" => email)
        esearch_response = esearch(search_dic)

        if verbose
            xmlASCII2file(esearch_response, "./esearch.xml")
        end

        #convert xml to dictionary
        esearch_dict = eparse(esearch_response)

        #2. Obtain PubMed/MEDLINE records (in MEDLINE or XML format) for
        #formulated search using NCBI E-Utilities.
        println("------Fetching Entrez--------")
        fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email,
                         "retmode" => "xml", "rettype"=>"null")
        #get the list of ids and perfom a fetch
        if !haskey(esearch_dict, "IdList")
            println("Error with esearch_dict:")
            println(esearch_dict)
            error("Response esearch_dict does not contain IdList")
        end

        ids = []
        for id_node in esearch_dict["IdList"][1]["Id"]
            push!(ids, id_node)
        end

        efetch_response = efetch(fetch_dic, ids)

        if verbose
            xmlASCII2file(efetch_response, "./efetch.xml")
        end

        efetch_dict = eparse(efetch_response)

        #save the results of an entrez fetch to a sqlite database
        println("------Saving to database--------")
        db = save_efetch_func(efetch_dict, db_config)

        article_total+=length(ids)

        if (length(ids) < retmax)
            break
        end

    end

    println("Finished, total number of articles: ", article_total)
    return db
end

"""
    occurance_matrix(db, umls_semantic_type)

Return a sparse matrix indicating the presence of MESH descriptors associated
with a given semantic type in all articles of the input database

###Output

* `des_ind_dict`: Dictionary matching row number to descriptor names
* `disease_occurances` : Sparse matrix. The columns correspond to a feature
vector, where each row is a MESH descriptor. There are as many
columns as articles. The occurance/abscense of a descriptor is labeled as 1/0
"""
function occurance_matrix(db, umls_semantic_type)

    #retrieve a list of filtered descriptors
    filtered_mesh = Set(filter_mesh_by_concept(db, umls_semantic_type))

    println("-------------------------------------------------------------")
    println("Found ", length(filtered_mesh), " MESH decriptor related to  ", umls_semantic_type)
    println(filtered_mesh)
    println("-------------------------------------------------------------")

    #create a map of filtered descriptor name to index to guarantee order
    des_ind_dict = Dict()

    for (i, fm) in enumerate(filtered_mesh)
        des_ind_dict[fm]= i
    end

    articles = Entrez.DB.all_pmids(db)

    #create the data-matrix
    disease_occurances = spzeros(length(filtered_mesh), length(articles))

    #Can this process be more efficient using database join/select?
    narticle = 0
    for (i, pmid) in enumerate(articles)

        #get all mesh descriptors associated with give article
        article_mesh = Set(Entrez.DB.get_article_mesh(db, pmid))

        #not all mesh are of the desired semantic type
        article_filtered_mesh = intersect(article_mesh, filtered_mesh)

        #skip if empty
        if isempty(article_filtered_mesh)
            continue
        end

        #otherwise form feature vector for this article
        indices = []
        for d in article_filtered_mesh
            push!(indices, des_ind_dict[d])
        end

        #TO DO: Not sure about the type. Should we choose bool to save space
        # or float to support opperations
        article_dis_feature  = zeros(Int, (length(filtered_mesh),1))
        article_dis_feature[indices] = 1

        #append to data matrix
        disease_occurances[:, i] = article_dis_feature
        narticle+=1
    end

    println("-------------------------------------------------------------")
    println("Found ", narticle, " articles with valid descriptors")
    println("-------------------------------------------------------------")
    return des_ind_dict, disease_occurances

end

"""
    map_mesh_to_umls!(db, c::Credentials)

Build and store in the given database a map from MESH descriptors to
UMLS Semantic Concepts

###Arguments

- `db`: Database. Must contain TABLE:mesh_descriptor. For each of the
descriptors in that table, search and insert the associated semantic
concepts into a new (cleared) TABLE:mesh2umls
- `c::Credentials`: UMLS username and password
"""
# @generated function map_mesh_to_umls(db, c::Credentials; append_results=false)
#     if typeof(db) == SQLite.DB
#         return :map_mesh_to_umls_sqlite(db, c::Credentials; append_results)
#     elseif typeof(db) == MySQL.MySQLHandle
#         return :map_mesh_to_umls_mysql(db, c::Credentials; append_results)
#     else
#         return :error("all_pmids: Invalid database backend")
#     end
# end


function map_mesh_to_umls!(db, c::Credentials; append_results=false)

  #if the mesh2umls relationship table doesn't esxist, create it
  db_query(db, "CREATE table IF NOT EXISTS mesh2umls (
                    mesh VARCHAR(255),
                    umls VARCHAR(255),
                    FOREIGN KEY(mesh) REFERENCES mesh_descriptor(name),
                    PRIMARY KEY(mesh, umls)
                )")

  #clear the relationship table
  if !append_results
      db_query(db, "DELETE FROM mesh2umls")
  end

  #select all mesh descriptors
  mq = db_query(db,"SELECT name FROM mesh_descriptor;")

  #get the array of terms
  mesh_terms =get_value(mq.columns[1])
  println("----------Matching MESH to UMLS-----------")
  for mt in mesh_terms
    #submit umls query
    term = mt
    query = Dict("string"=>term, "searchType"=>"exact" )
    # println("term: ", term)

    all_results= search_umls(c, query)

    if length(all_results) > 0

      cui = best_match_cui(all_results)
    #   println("Cui: ", cui)
      if cui == ""
        println("Nothing!")
        println(all_results)
      end
      all_concepts = get_semantic_type(c, cui)

      for concept in all_concepts
      # insert "semantic concept" into database
        insert_row!(db, "mesh2umls", Dict(:mesh=> term, :umls=> concept))
        # println(concept)
      end

    end
    print(".")
  end
  pritnln("--------------------------------------------------")
end

# Retrieve all mesh descriptors associated with the given umls_concept
function filter_mesh_by_concept(db, umls_concept)

    uc = string("'", replace(umls_concept, "'", "''") , "'")
    query  = db_query(db, "SELECT mesh FROM mesh2umls
    WHERE umls LIKE $uc ")

    #return data array
    return get_value(query.columns[1])

end


end
