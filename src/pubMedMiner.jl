"""
    PubMedMiner
    
Utilities to mine results from a PubMed/Medline search
Authors: Isabel Restrepo
BCBI - Brown University
"""
module PubMedMiner

using MySQL
# using Base.Threads

export DatabaseConnection
include("common.jl")

export umls_semantic_occurrences


function sample_query(pmid)
    pmid+1

    host = "pbcbicit.services.brown.edu"
    username = "mrestrep"
    password = ENV["PUBMEDMINER_DB_PSSWD"]
    dbname="pubmed_comorbidities"    
    db = mysql_connect(host, username, password, dbname)
    
    
    query_string = "INSERT INTO results_epilepsy (pmid, descriptor)
                    SELECT pmid, descriptor
                    FROM medline.mesh
                    JOIN MESH_T047 ON MESH_T047.STR = descriptor
                    WHERE pmid = 20070;"

    mysql_execute(db, query_string)

    mysql_disconnect(db)
end

"""
umls_semantic_occurrences(db, umls_semantic_type)

Return a sparse matrix indicating the presence of MESH descriptors associated
with a given umls semantic type in all articles that are related to the specified mesh

### Inputs:
db::MySQL.MySQLHandle: Database Connection 
mesh::Search only pubmed articles associated with this mesh-heading
umls_concepts...::Lists 
###Output

* `des_ind_dict`: Dictionary matching row number to descriptor names
* `disease_occurances` : Sparse matrix. The columns correspond to a feature
vector, where each row is a MESH descriptor. There are as many
columns as articles. The occurance/abscense of a descriptor is labeled as 1/0
"""
function umls_semantic_occurrences(mesh::String, umls_concepts::String...)
   
    db = DatabaseConnection().con
    
    concept_tables = Vector{String}(length(umls_concepts))

    for (ci, concept) in enumerate(umls_concepts)
        concept_tables[ci] = UMLS2Table[concept]
    end

    info("Concept tables to use: ", concept_tables )

    query_string = """ SELECT pmid
                         FROM medline.mesh
                        WHERE descriptor = '$mesh' """;

    articles_df = mysql_execute(db, query_string)
    total_articles = length(articles_df[:pmid])
    info("$(length(articles_df[:pmid])) Articles related to MH:$mesh")

    #Can this process be more efficient using database join/select?
    narticle = 0

    #Lookups for MeSH 
    MeSH2idx = Dict{String, Int}()
    idx2MeSH = Dict{Int, String}()
    
    mesh_global_idx = 1 

    Ik = Vector{Int}()
    Jk = Vector{Int}()

    info("----------------------------------------")
    info("Start all articles")

    query_string = "DROP TABLE IF EXISTS results_$mesh;

                    CREATE TABLE results_$mesh(
                        `pmid` INT(11),
                        `descriptor` varchar(255),
                        KEY `pmid` (`pmid`),
                        KEY `descriptor` (`descriptor`),
                        KEY `pmid_descriptor_index` (`descriptor`,`pmid`)
                        )ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"

    mysql_execute(db, query_string)
    mysql_disconnect(db)
    
    pmap((pmid)->sample_query(pmid), [1])
    
    #Vectors to hold mesh/article indeces to form sparse matrix
    # batch_size = 1000
    # for batch=1:batch_size:total_articles

    #     end_loop=batch+batch_size
    #     if end_loop > total_articles
    #         end_loop = total_articles
    #     end
    #     println("Batch: $batch")
        
    #     @time @sync for i=batch:end_loop
                   
    # for i=1:1
    # @async begin
        # pmid = articles_df[:pmid][i]
        # for table in concept_tables
            # print(".")
            # pmid = 20070
            # query_string = "INSERT INTO results_$mesh (pmid, descriptor)
            #                     SELECT pmid, descriptor
            #                     FROM medline.mesh
            #                     JOIN $table ON $table.STR = descriptor
            #                     WHERE pmid = $pmid;"

            # db2 = DatabaseConnection().con
            
            # query_string = "INSERT INTO results_epilepsy (pmid, descriptor)
            #                     SELECT pmid, descriptor
            #                     FROM medline.mesh
            #                     JOIN MESH_T047 ON MESH_T047.STR = descriptor
            #                     WHERE pmid = 20070;"

            # mysql_execute(db2, query_string)

            # mysql_disconnect(db2)
                    
            # query_string = "SELECT descriptor
            #                 FROM medline.mesh
            #                 JOIN $table ON $table.STR = descriptor
            #                 WHERE pmid = $pmid;"
        
        
            # #not all mesh are of the desired semantic type
            # @time article_filtered_mesh = mysql_execute(db, query_string).columns[1]
            
            # #skip if empty
            # if isempty(article_filtered_mesh)
            #     continue
            # end

            # #otherwise form feature vector for this article
            # indices = zeros(Int, size(article_filtered_mesh,1))
            # di  = 1
            # for d in article_filtered_mesh
            #     try
            #         mesh_index_from_dict =  MeSH2idx[d]
            #     catch
            #         MeSH2idx[d] = mesh_global_idx
            #         idx2MeSH[mesh_global_idx] = d
            #         mesh_global_idx+=1
            #     end
            #    push!(Ik, MeSH2idx[d])
            #    push!(Jk, article_idx)

            # end

        # end

        # narticle+=1
    # end

    # println(".")

    # println("-------------------------------------------------------------")
    # println("Found ", narticle, " articles with valid descriptors")
    # println("-------------------------------------------------------------")

    #create the data-matrix
    # Vk = ones(Float64, length(I_k))
    # m = length(keys(MeSH2idx))
    # n = length(articles_df[:pmid])
    # occur_mat = sparse(Ik, Jk, Vk, m, n, *)

    # return OccurrenceData(occur_mat, MeshLookup(idx2MeSH, MeSH2idx))

end


end #Module
