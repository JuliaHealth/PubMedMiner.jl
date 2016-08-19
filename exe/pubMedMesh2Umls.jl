# Executable to map MESH descriptors to UMLS concepts. Descriptors are
# assumed to be stored in a SQLite database containing table "mesh_descriptor"
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using PubMedMiner
using SQLite
import BioMedQuery.UMLS:Credentials


function main(args)

    # initialize the settings (the description is for the help screen)
    s = ArgParseSettings()
    s.description = "This is pubMedMiner.jl - main script"
    s.version = "1.0"

    @add_arg_table s begin
        "--append_results"
            help = "Flag to indicate not to clear the results TABLE:umls2mesh"
            action = :store_true
        "--umls_username"
            help = "UMLS-NLM username"
            arg_type = ASCIIString
            required = true
        "--umls_password"
            help = "UMLS-NLM password"
            arg_type = ASCIIString
            required = true
        "mysql"
            help = "Use MySQL backend"
            action = :command
        "sqlite"
             help = "Use SQLite backend"
             action = :command
    end

    @add_arg_table s["mysql"] begin
     "--host"
         help = "Host where you database lives"
         arg_type = ASCIIString
         default = "localhost"
     "--dbname"
         help = "Database name"
         arg_type = ASCIIString
         required = true
     "--username"
         help = "MySQL username"
         arg_type = ASCIIString
         default = "root"
     "--password"
         help = "MySQL password"
         arg_type = ASCIIString
         default = ""
    end

     @add_arg_table s["sqlite"] begin
     "--db_path"
          help = "Path to SQLite database file to store results"
          arg_type = ASCIIString
          required = true
     end


    parsed_args = parse_args(s)
    println("-------------------------------------------------------------")
    println(s.description)
    println("Parsed args:")
    for (key,val) in parsed_args
        println("  $key   =   $(repr(val))")
    end
    println("-------------------------------------------------------------")


    user = parsed_args["umls_username"]
    psswd = parsed_args["umls_password"]
    credentials = Credentials(user, psswd)
    append = parsed_args["append_results"]
    db = nothing

    if haskey(parsed_args, "sqlite")
        db_path  = parsed_args["sqlite"]["db_path"]
        db = SQLite.DB(db_path)
        @time begin
            PubMedMiner.map_mesh_to_umls_sqlite!(db, credentials; append_results=append)
        end
    elseif haskey(parsed_args, "mysql")
        host = parsed_args["mysql"]["host"]
        dbname = parsed_args["mysql"]["dbname"]
        username = parsed_args["mysql"]["username"]
        pswd = parsed_args["mysql"]["password"]
        db = mysql_connect(host, username, pswd, dbname)
        println("MySQL map_mesh_to_umls not implemented yet")
    else
        error("Unsupported database backend")
    end



    println("-------------------------------------------------------------")
    println("Done Mapping Mesh to UMLS")
    println("-------------------------------------------------------------")

end

main(ARGS)
