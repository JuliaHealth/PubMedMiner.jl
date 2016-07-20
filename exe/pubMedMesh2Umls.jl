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
        "--db_path"
            help = "Path to database file to store results"
            arg_type = ASCIIString
            required = true
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
    end

    parsed_args = parse_args(s)
    println("-------------------------------------------------------------")
    println(s.description)
    println("Parsed args:")
    for (key,val) in parsed_args
        println("  $key  =>  $(repr(val))")
    end
    println("-------------------------------------------------------------")

    db_path  = parsed_args["db_path"]

    @time begin
        db = SQLite.DB(db_path)
        user = parsed_args["umls_username"]
        psswd = parsed_args["umls_password"]
        append = parsed_args["append_results"]

        credentials = Credentials(user, psswd)
        PubMedMiner.map_mesh_to_umls!(db, credentials; append_results=append)
    end
    println("-------------------------------------------------------------")
    println("Done Mapping Mesh to UMLS")
    println("-------------------------------------------------------------")

end

main(ARGS)
