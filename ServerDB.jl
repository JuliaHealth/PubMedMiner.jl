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

using HTTP
using PubMedMiner
using MySQL

function run_server()

    query_dict = Dict()

    HTTP.listen("0.0.0.0", 8091, reauseaddr=true) do request::HTTP.Request

        println("******************")
        @show request
        println("******************")

        uri = parse(HTTP.URI, request.target)
        query_dict = HTTP.queryparams(uri)

        headers = Dict{AbstractString,AbstractString}(
            "Server"            => "Julia/$VERSION",
            "Content-Type"      => "text/html; charset=utf-8",
            "Content-Language"  => "en",
            "Date"              => Dates.format(now(Dates.UTC), Dates.RFC1123Format),
            "Access-Control-Allow-Origin" => "*" )

        return HTTP.Response(200, HTTP.Headers(collect(headers)), body = join([String(k)*" - "*String(v) for (k,v) in query_dict],'\n'))

    end
end

run_server()
