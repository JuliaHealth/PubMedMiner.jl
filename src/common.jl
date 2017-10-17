const UMLS2Table = Dict("Disease or Syndrome" => "MESH_T047")

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
        con = mysql_connect(ds.host, ds.username, ds.password, ds.dbname)
        this = new(con)
    end


    function DatabaseConnection()
        ds = DatabaseSettings()
        con = mysql_connect(ds.host, ds.username, ds.password, ds.dbname)
        this = new(con)
    end

    function DatabaseConnection(host::String, username::String, password::String, dbname::String)
        con = mysql_connect(host, username, password, dbname)
        this = new(con)
    end
end


"""
MeshLookup

Reversible lookup dictionary from mesh terms to matrix index
"""
type MeshLookup
    idx2MeSH::Dict{Int, String}
    MeSH2idx::Dict{String, Int}

    MeshLookup() = new()
    MeshLookup(idx2MeSH::Dict{Int, String}, MeSH2idx::Dict{String, Int}) = new(idx2MeSH, MeSH2idx)
end

"""
PaperLookup

Reversible lookup dictionary from paper id to matrix index
"""
type PaperLookup
    idx2pmid::Dict{Int, Int}
    pmid2idx::Dict{Int, Int}
end

"""
AbtractsData

Hold data matrices and lookup dictionaries related to the abstracts data matrix
"""
type OccurrenceData
    
    occurrence_data_matrix::SparseMatrixCSC{Float64,Int64}
    paper_lookup::PaperLookup
    mesh_lookup::MeshLookup

    OccurrenceData() = new()
    OccurrenceData(occurrence_data_matrix::SparseMatrixCSC{Float64,Int64},
                   mesh_lookup::MeshLookup) = new(occurrence_data_matrix, mesh_lookup)

end