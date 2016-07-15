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


function main(args)

    # initialize the settings (the description is for the help screen)
   s = ArgParseSettings()
   s.description = "This is pubMedOccur"
   s.version = "1.0"

   @add_arg_table s begin
    "--db_path"
        help = "Path to database file to store results"
        arg_type = ASCIIString
        required = true
    "--umls_concept"
        help = "UMLS concept for occurrance analysis"
        arg_type = ASCIIString
        required = true
    "--results_dir"
         help = "Path to store the results"
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


   db_path  = parsed_args["db_path"]

   results_dir = parsed_args["results_dir"]

    if !isdir(results_dir)
        mkdir(results_dir)
    end

    occur_path = results_dir*"/occur_sp.jdl"
    mesh2ind_path = results_dir*"/mesh2ind.jdl"

   @time begin
        db = SQLite.DB(db_path)
        umls_concept = parsed_args["umls_concept"]
        mesh2ind, occur = PubMedMiner.occurance_matrix(db, umls_concept)
        println("-------------------------------------------------------------")
        println("Output Data Matrix")
        println(occur)
        println("-------------------------------------------------------------")

        # save(occur_path, "occur", occur)
        jldopen(occur_path, "w") do file
            write(file, "occur", occur)
        end
        jldopen(mesh2ind_path, "w") do file
            write(file, "mesh2ind", mesh2ind)
        end


        # file  = jldopen(occur_path, "r")
        # obj2 = read(file, "occur")
        # display(obj2)
    end

    println("-------------------------------------------------------------")
    println("Done computing and saving occurance info to disk")
    println("-------------------------------------------------------------")


end

main(ARGS)
