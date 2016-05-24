# Utilities to mine results from a PubMed/Medline search
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

module pubMedMiner

# using NLM
using NLM.Entrez
using NLM.UMLS

using SQLite
using DataStreams


function clean_db(db_path)
    println("Cleaning DB")

    if isfile(db_path)
        rm(db_path)
    end
end

function pubmed_search_term(email, article_max, term, db_path)

    retstart = 0
    retmax = 10000
    db = Nullable{SQLite.DB}()
    article_max = article_max

    if article_max < retmax
        retmax = article_max
    end

    for rs=retstart:retmax:(article_max- 1)

        rm = rs + retmax
        if rm > article_max
            retmax = article_max - rs
        end

        println("Fetching ", retmax, " articles, starting at index ", rs)

        #1. Formulate PubMed/MEDLINE search for articles between 2000 and 201
        #with obesity indicated as the major MeSH descriptor.
        println("------Searching Entrez--------")
        search_dic = Dict("db"=>"pubmed","term" => term,
        "retstart" => rs, "retmax"=>retmax, "tool" =>"BioJulia",
        "email" => email, "mindate"=>"2000","maxdate"=>"2012" )
        esearch_response = esearch(search_dic)
        #convert xml to dictionary
        esearch_dict = eparse(esearch_response)

        #2. Obtain PubMed/MEDLINE records (in MEDLINE or XML format) for
        #formulated search using NCBI E-Utilities.
        println("------Fetching Entrez--------")
        fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email,
                         "retmode" => "xml", "rettype"=>"null")
        #get the list of ids and perfom a fetch
        if !haskey(esearch_dict, "IdList")
            error("Error: IdList not found")
        end

        ids = []
        for id_node in esearch_dict["IdList"][1]["Id"]
            push!(ids, id_node)
        end

        efetch_response = efetch(fetch_dic, ids)
        efetch_dict = eparse(efetch_response)
        # println("______________________________________________________________")
        # display(efetch_dict["PubmedArticleSet"][1]["MedlineCitation"]["Article"])

        #save the results of an entrez fetch to a sqlite database
        println("------Saving to database--------")
        db = save_efetch(efetch_dict, db_path)
    end


    return db
end

# form the data matrix for all articles.
# The columns coresponds to a feature vector. Therefore there are as many
# columns as articles. The feature vector corresponds to the
# vector of diseases . The occurance/abscense of a disease is labeled as 1 or 0
function occurance_matrix(db, umls_concept)

    #retrieve a list of disease
    diseases = Set(filter_mesh_by_concept(db, umls_concept))

    #create a map of diesease name to index - guarantee order
    dis_ind_dict = Dict()

    for (i,d) in enumerate(diseases)
        if !d.isnull
            dis_ind_dict[d]= i
        end
    end

    articles = Entrez.DB.all_pmids(db)

    #create the data-matrix
    disease_occurances = spzeros(length(diseases), length(articles))

    for (i, pmid) in enumerate(articles)
        #get all mesh descriptors associated with give article
        article_mesh = Set(Entrez.DB.get_article_mesh(db, pmid))
        #not all mesh are of the desired concept (e.g disease)
        article_disease = intersect(article_mesh, diseases)
        #form feature vector for this article
        indices = []
        for d in article_disease
            push!(indices, dis_ind_dict[d])
        end
        #TO DO: Not sure about the type. Should we choose bool to save space
        # or float to support opperations
        article_dis_feature  = zeros(Int, (length(diseases),1))
        article_dis_feature[indices] = 1

        #append to data matrix
        disease_occurances[:, i] = article_dis_feature
    end

    return disease_occurances

end


# Builds a map from MESH descriptors to UMLS Semantic Concepts
# Input: db - database containing the MESH descriptors to map
# For each of the descriptors it searches and inserts the associated semantic
# concepts into a new table: mesh2umls, of the input datbase
function map_mesh_to_umls(db, c::Credentials)
  # #Create database file
  # path = "/Users/isa/Dropbox/BrownAgain/Projects/BCBI/BioJuliaAlpha/efetch_test.db"
  # db = SQLite.DB(path)

  #if the mesh - umls relationship table doesn't esxist, create it
  SQLite.query(db, "CREATE table IF NOT EXISTS
                    mesh2umls (mesh TEXT, umls TEXT,
                    FOREIGN KEY(mesh) REFERENCES mesh(name),
                    PRIMARY KEY(mesh, umls) )")

  #clear the relationship table
  SQLite.query(db, "DELETE FROM mesh2umls")

  #select all entries
  so = SQLite.Source(db,"SELECT name FROM mesh;")
  ds = DataStreams.Data.stream!(so, DataStreams.Data.Table)

  #get the array of terms - is there a better way?
  mesh_terms =ds.data[1]



  for mt in mesh_terms
    #submit umls query
    term = SQLite.get(mt)
    query = Dict("string"=>term, "searchType"=>"exact" )
    # println("term: ", term)

    all_results= search_umls(c, query)

    if length(all_results) > 0

      cui = best_match_cui(all_results, term)
    #   println("Cui: ", cui)
      if cui == ""
        println("Nothing!")
        println(all_results)
      end
      all_concepts = get_concepts(c, cui)

      for concept in all_concepts
      # insert "semantic concept" into database
        SQLite.query(db, "INSERT INTO mesh2umls VALUES  (@mesh, @umls)",
                     Dict(:mesh=> term, :umls=> concept))

        # println(concept)
      end

    end
  end

end

# Retrieve all mesh descriptors associated with the given umls_concept
function filter_mesh_by_concept(db, umls_concept)

    query  = SQLite.query(db, "SELECT mesh FROM mesh2umls
    WHERE umls LIKE ? ", [umls_concept])

    #return data array
    return query.data[1]

end


end
