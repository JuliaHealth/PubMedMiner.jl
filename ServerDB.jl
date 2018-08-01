using HTTP
using PubMedMiner
using MySQL
using DataFrames
using JSON

const host = ENV["PUBMEDMINER_DB_HOST"]
const username = ENV["PUBMEDMINER_DB_USER"]
const password = ENV["PUBMEDMINER_DB_PSSWD"]

opts = Dict(MySQL.API.MYSQL_ENABLE_CLEARTEXT_PLUGIN => 1, MySQL.API.MYSQL_OPT_RECONNECT => 1)
conn = MySQL.connect(host, username, password, opts=opts)

all_mesh = MySQL.query(conn, """select uid, str from pubmed_comorbidities.ALL_MESH""", DataFrame)
all_concepts = MySQL.query(conn, """select distinct tui, sty from umls_meta.MRSTY""", DataFrame)

function to_json(stats::T) where T<:PubMedMiner.Stats

    json_dict = Dict{String,Any}()

    for field in fieldnames(T)
        json_dict[String(field)] = getfield(stats, field)
    end

    # return JSON.print(io, json_dict)
    return JSON.json(json_dict)

end

function to_json(df::DataFrame)

    pairs = []

    for i = 1:size(df)[1]
        obj_dict = Dict{String,Any}()
        for col in df.colindex.names
            obj_dict[String(col)] = df[i, col]
        end
        push!(pairs, JSON.json(obj_dict))
    end

    return pairs

end

function get_body(mesh_uid::String, concept_tui::String)

    mesh_int = parse(Int, mesh_uid)

    mesh_name = all_mesh[find(all_mesh[:uid] .== mesh_int), 2][1]

    concept_tuis = String.(split(concept_tui, ","))
    sort!(concept_tuis)

    concept_str = join(concept_tuis," | ")

    res = MySQL.query(conn, "select body from pubmed_comorbidities.query_cache where mesh_uid=$mesh_int and concepts='$concept_str'", DataFrame)

    if size(res) == (0,1)

        concepts = []

        for tui in concept_tuis
            push!(concepts, all_concepts[find(all_concepts[:tui] .== tui), :sty][1])
        end

        df = get_semantic_occurrences_df(conn, mesh_name, concepts...)
        stats = mesh_stats(df, 50)

        ret = to_json(stats)

        MySQL.execute!(conn, "insert into pubmed_comorbidities.query_cache (mesh_uid,concepts,body) VALUES ($mesh_int,'$concept_str','$ret')")

        return ret
    else
        return res[1,1]
    end

end

function run_server()

    query_dict = Dict()

    HTTP.listen("0.0.0.0", 8091, reauseaddr=true) do request::HTTP.Request

        println("******************")
        @show request
        println("******************")

        uri = parse(HTTP.URI, request.target)

        headers = Dict{AbstractString,AbstractString}(
            "Server"            => "Julia/$VERSION",
            "Content-Type"      => "text/html; charset=utf-8",
            "Content-Language"  => "en",
            "Date"              => Dates.format(now(Dates.UTC), Dates.RFC1123Format),
            "Access-Control-Allow-Origin" => "*" )

        if uri.path == "/"
            query_dict = HTTP.queryparams(uri)
            return HTTP.Response(200, HTTP.Headers(collect(headers)), body = get_body(query_dict["uid"], query_dict["tui"]))
        elseif uri.path == "/all_mesh"
            return HTTP.Response(200, HTTP.Headers(collect(headers)), body = to_json(all_mesh))
        elseif uri.path == "/all_concepts"
            return HTTP.Response(200, HTTP.Headers(collect(headers)), body = to_json(all_concepts))
        else
            return HTTP.Response(400, HTTP.Headers(collect(headers)), body = "unknown request")
        end

    end
end

run_server()
#why the double requests (one with query, one without) - ASK FERNANDO FOR ADVICE
