const UMLS2MESHTable = Dict("Disease or Syndrome" => "MESH_T047",
                        "Mental or Behavioral Dysfunction" =>"MESH_T048",
                        "Neoplastic Process" => "MESH_T191")

function umls_occurrance_query(pmid, umls_table, results_table; dbname="pubmed_comorbidities" )
    
    host = ENV["PUBMEDMINER_DB_HOST"]
    username = ENV["PUBMEDMINER_DB_USER"]
    password = ENV["PUBMEDMINER_DB_PSSWD"]
    
    try
        
        
        db = MySQL.connect(host, username, password, dbname)
        
        query_string = "INSERT INTO $results_table (pmid, descriptor)
                        SELECT pmid, descriptor
                        FROM medline.mesh
                        JOIN $umls_table ON $(umls_table).STR = descriptor
                        WHERE pmid = $pmid;"

        MySQL.execute!(db, query_string)

        MySQL.disconnect(db)
    catch
        error("Failed to process PMDI $pmid - could be a connection error")
    end
end
    
"""
    save_semantic_occurrences(mesh::String, umls_concepts::String...; overwrite=true)

For all pmids tagged with MeSH descriptor in the MEDLINE database, save to the input database 
all other associated MeSH descriptors of the given umls semantic type.

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
function save_semantic_occurrences(mesh::String, umls_concepts::String...; overwrite=false)
    
    db = DatabaseConnection().con

    query_string = """ SELECT pmid
                            FROM medline.mesh
                        WHERE descriptor = '$mesh' """;

    articles_df = MySQL.execute!(db, query_string)
    total_articles = length(articles_df[:pmid])
    info("$(length(articles_df[:pmid])) Articles related to MH:$mesh")
    
    info("----------------------------------------")
    info("Start all articles")

    
    for concept in umls_concepts

        umls_table = ""
        if !haskey(UMLS2MESHTable, concept)
            warn("Concept ($concept) not available for filtering. Contact Admin. Skipping")
            continue
        end

        umls_table = UMLS2MESHTable[concept]
        info("Using concept table: ", umls_table )            
        results_table = lowercase(string(mesh, "_" ,umls_table))
        results_table = replace(results_table, " ", "_")      
        info("Using results table: ", results_table )            

        #does table exist?
        query_string = "SHOW TABLES LIKE '$(results_table)' "
        sel = MySQL.execute!(db, query_string)
        table_exists = size(sel,1) == 1 ? true:false

        if table_exists           
            if overwrite
                info("Overwriting table")
                query_string = "TRUNCATE TABLE $(results_table);"
                MySQL.execute!(db, query_string)
                pmap((pmid)->umls_occurrance_query(pmid, umls_table, results_table), articles_df[:pmid])      
            else
                info("Table exists and will remain unchanged")
            end
        else
            info("Table doesn't exist, create")            
            query_string = "CREATE TABLE $(results_table)(
                                    `pmid` INT(11),
                                    `descriptor` varchar(255),
                                    KEY `pmid` (`pmid`),
                                    KEY `descriptor` (`descriptor`),
                                    KEY `pmid_descriptor_index` (`descriptor`,`pmid`)
                                    )ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
        
            MySQL.execute!(db, query_string)
            pmap((pmid)->umls_occurrance_query(pmid, umls_table, results_table), articles_df[:pmid])
        end
    end

    MySQL.disconnect(db)              
end

function get_semantic_occurrences_df(mesh::String, umls_concepts::String...)

    db = DatabaseConnection().con

    results_df = DataFrame()
    
    for concept in umls_concepts
        umls_table = UMLS2MESHTable[concept]
        info("Using concept table: ", umls_table )            
        results_table = lowercase(string(mesh, "_" ,umls_table))
        results_table = replace(results_table, " ", "_")      
        info("Using results table: ", results_table )   
        
        query_string = "SELECT *
                        FROM $results_table;"
        
        results_df = [results_df; MySQL.execute!(db, query_string)]
    end

    MySQL.disconnect(db)
    results_df

end