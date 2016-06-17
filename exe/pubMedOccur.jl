# Obtain the occurrance matrix associated with a UMLS concept in a previously
# obtained pubmed/medline search
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using pubMedMiner
using SQLite
using NLM.UMLS:Credentials
using JLD


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
    "occur"
        help = "Build an occurrance matrix for a given UMLS concept"
        action = :command
   end


   @add_arg_table s["occur"] begin
       "--umls_concept"
            help = "UMLS concept for occurrance analysis"
            arg_type = ASCIIString
            default = "Disease or Syndrome"
        "--results_dir"
             help = "Path to store the results"
             arg_type = ASCIIString
             required = true
   end


   parsed_args = parse_args(s) # the result is a Dict{String,Any}
   println("Parsed args:")
   for (key,val) in parsed_args
       println("  $key  =>  $(repr(val))")
   end

   db_path  = parsed_args["db_path"]
   if haskey(parsed_args, "occur")
       results_dir = parsed_args["occur"]["results_dir"]
    #    ext = splitext(occur_path)[2]
    #    if  !isequal(ext,".jdl")
    #        println("Error: results_file must have a .jdl extension")
    #        exit(-1)
    #    end
        if !isdir(results_dir)
            mkdir(results_dir)
        end
        occur_path = results_dir*"/occur_sp.jdl"
        mesh2ind_path = results_dir*"/mesh2ind.jdl"

       @time begin
            db = SQLite.DB(db_path)
            umls_concept = parsed_args["occur"]["umls_concept"]
            mesh2ind, occur = pubMedMiner.occurance_matrix(db, umls_concept)
            display(occur)
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
   end


end

main(ARGS)
