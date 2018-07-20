using MySQL
using DataFrames

"""
DatabaseSettings

Database Settings for Brown University Host
"""

struct DatabaseSettings
    host::String
    username::String
    password::String
    dbname::String

    function DatabaseSettings(dbname::String)
        host = ""
        username = ""
        password = ""
        try
            host = ENV["PUBMEDMINER_DB_HOST"]
            username = ENV["PUBMEDMINER_DB_USER"]
            password = ENV["PUBMEDMINER_DB_PSSWD"]
        catch
            error("""DatabaseSettings constructor requiers:
            ENV["PUBMEDMINER_DB_HOST"], ENV["PUBMEDMINER_DB_USER"] and ENV["PUBMEDMINER_DB_PSSWD"]""")
        end

        ds = new(host, username, password, dbname)
    end


    function DatabaseSettings()
        host = ""
        username = ""
        password = ""
        dbname="pubmed_comorbidities"
        try
            host = ENV["PUBMEDMINER_DB_HOST"]
            username = ENV["PUBMEDMINER_DB_USER"]
            password = ENV["PUBMEDMINER_DB_PSSWD"]
        catch
            error("""DatabaseSettings constructor requiers:
            ENV["PUBMEDMINER_DB_HOST"], ENV["PUBMEDMINER_DB_USER"] and ENV["PUBMEDMINER_DB_PSSWD"]""")
        end

        ds = new(host, username, password, dbname)
    end

    DatabaseSettings(host::String, username::String,
                    password::String, dbname::String) = new(host, username, password, dbname)
end

"""
DatabaseConnection

Database connection for Brown University Host
"""

struct DatabaseConnection
    con::MySQL.MySQLHandle

    function DatabaseConnection(dbname::String)
        ds = DatabaseSettings(dbname)
        con = MySQL.connect(ds.host, ds.username, ds.password, db = ds.dbname)
        this = new(con)
    end


    function DatabaseConnection()
        ds = DatabaseSettings()
        con = MySQL.connect(ds.host, ds.username, ds.password, db = ds.dbname)
        this = new(con)
    end

    function DatabaseConnection(host::String, username::String, password::String, dbname::String)
        con = MySQL.connect(host, username, password, dbname)
        this = new(con)
    end
end


"""
    get_semantic_occurrences_df(mesh, umls_concepts...)

Given a mesh descriptor and filtering UMLS concepts, returns a DataFrame with
PMIDs and related mesh descriptor filtered by the concepts.
"""
function get_semantic_occurrences_df(mesh::String, umls_concepts::String...)

    db = PubMedMiner.DatabaseConnection().con

    concept_string = "'"*join(umls_concepts,"','")*"'"

    # select pmids from medline which use the mesh descriptor
    query_string = """ SELECT mh.pmid, mrc.str as descriptor
                    FROM medline_new_2.mesh_heading mh

                    JOIN (select uid from medline_new_2.mesh_desc where name = '$mesh') md
                    ON md.uid <> mh.desc_uid

                    JOIN pubmed_comorbidities.ALL_MESH mrc
                    ON mrc.uid = mh.desc_uid

                    JOIN umls_meta.MRSTY mrs
                    ON mrc.cui = mrs.cui

                    JOIN medline_new_2.mesh_heading mh2
                    ON mh2.pmid = mh.pmid

                    join (select uid from medline_new_2.mesh_desc where name = '$mesh') md2
                    on md2.uid = mh2.desc_uid

                    WHERE mrs.sty in ($concept_string); """;

    articles_df = MySQL.query(db, query_string, DataFrame)

    MySQL.disconnect(db)

    unique!(articles_df)

    return articles_df

end
