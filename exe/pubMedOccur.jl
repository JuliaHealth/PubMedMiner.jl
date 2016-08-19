# Obtain the occurrance matrix associated with a UMLS concept in a previously
# obtained pubmed/medline search
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using PubMedMiner
using SQLite
using BioMedQuery.UMLS:Credentials
using JLD
using MySQL


function main(args)

    # initialize the settings (the description is for the help screen)
   s = ArgParseSettings()
   s.description = "This is pubMedOccur"
   s.version = "1.0"

   @add_arg_table s begin
    "--umls_concept"
        help = "UMLS concept for occurrance analysis"
        arg_type = ASCIIString
        required = true
    "--results_dir"
         help = "Path to store the results"
         arg_type = ASCIIString
         required = true
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



   parsed_args = parse_args(s) # the result is a Dict{String,Any}
   println("-------------------------------------------------------------")
   println(s.description)
   println("Parsed args:")
   for (key,val) in parsed_args
       println("  $key  =>  $(repr(val))")
   end
   println("-------------------------------------------------------------")


   results_dir = parsed_args["results_dir"]

    if !isdir(results_dir)
        mkdir(results_dir)
    end

    occur_path = results_dir*"/occur_sp.jdl"
    labels2ind_path = results_dir*"/labels2ind.jdl"

    umls_concept = parsed_args["umls_concept"]


    if haskey(parsed_args, "sqlite")
        db_path  = parsed_args["sqlite"]["db_path"]
        db = SQLite.DB(db_path)
        @time begin
            labels2ind, occur = PubMedMiner.occurance_matrix(db, umls_concept)
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
    println("Output Data Matrix")
    println(occur)
    println("-------------------------------------------------------------")

    # save(occur_path, "occur", occur)
    jldopen(occur_path, "w") do file
        write(file, "occur", occur)
    end
    jldopen(labels2ind_path, "w") do file
        write(file, "labels2ind", labels2ind)
    end


    # file  = jldopen(occur_path, "r")
    # obj2 = read(file, "occur")
    # display(obj2)


    println("-------------------------------------------------------------")
    println("Done computing and saving occurance info to disk")
    println("-------------------------------------------------------------")


end

main(ARGS)
