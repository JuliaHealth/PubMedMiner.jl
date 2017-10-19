const UMLS2Table = Dict("Disease or Syndrome" => "MESH_T047")

function umls_occurrance_query(pmid, umls_table, results_table; dbname="pubmed_comorbidities" )
    
    host = ENV["PUBMEDMINER_DB_HOST"]
    username = ENV["PUBMEDMINER_DB_USER"]
    password = ENV["PUBMEDMINER_DB_PSSWD"]
    
    db = mysql_connect(host, username, password, dbname)
       
    query_string = "INSERT INTO $results_table (pmid, descriptor)
                    SELECT pmid, descriptor
                    FROM medline.mesh
                    JOIN $umls_table ON $(umls_table).STR = descriptor
                    WHERE pmid = $pmid;"

    mysql_execute(db, query_string)

    mysql_disconnect(db)
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
function save_semantic_occurrences(mesh::String, umls_concepts::String...; overwrite=true)
    
    db = DatabaseConnection().con
    
    concept_tables = Vector{String}(length(umls_concepts))

    for (ci, concept) in enumerate(umls_concepts)
        concept_tables[ci] = UMLS2Table[concept]
    end


    query_string = """ SELECT pmid
                            FROM medline.mesh
                        WHERE descriptor = '$mesh' """;

    articles_df = mysql_execute(db, query_string)
    total_articles = length(articles_df[:pmid])
    info("$(length(articles_df[:pmid])) Articles related to MH:$mesh")

    
    info("----------------------------------------")
    info("Start all articles")


    
    for concept in umls_concepts

        umls_table = UMLS2Table[concept]
        info("Using concept table: ", umls_table )            
        results_table = lowercase(string(mesh, "_" ,umls_table))       

        if overwrite
            query_string = "DROP TABLE IF EXISTS $(results_table);
    
                            CREATE TABLE $(results_table)(
                                `pmid` INT(11),
                                `descriptor` varchar(255),
                                KEY `pmid` (`pmid`),
                                KEY `descriptor` (`descriptor`),
                                KEY `pmid_descriptor_index` (`descriptor`,`pmid`)
                                )ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
    
            mysql_execute(db, query_string)
        end
 
        # umls_occurrance_query(articles_df[:pmid][1], umls_table, results_table) 
        pmap((pmid)->umls_occurrance_query(pmid, umls_table, results_table), articles_df[:pmid])
    end

    mysql_disconnect(db)

end

function get_semantic_occurrences_df(mesh::String, umls_concepts::String...)

    db = DatabaseConnection().con

    results_df = DataFrame()
    
    for concept in umls_concepts
        umls_table = UMLS2Table[concept]
        info("Using concept table: ", umls_table )            
        results_table = lowercase(string(mesh, "_" ,umls_table)) 
        
        query_string = "SELECT *
                        FROM $results_table;"
        
        results_df = [results_df; mysql_execute(db, query_string)]
    end

    mysql_disconnect(db)
    results_df

end