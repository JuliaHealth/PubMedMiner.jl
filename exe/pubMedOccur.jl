# Obtain the occurrance matrix associated with a UMLS concept in a previously
# obtained pubmed/medline search
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using pubMedMiner
using SQLite
import umls:Credentials


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
   end


   parsed_args = parse_args(s) # the result is a Dict{String,Any}
   println("Parsed args:")
   for (key,val) in parsed_args
       println("  $key  =>  $(repr(val))")
   end

   db_path  = parsed_args["db_path"]
   if haskey(parsed_args, "occur")
       @time begin
            db = SQLite.DB(db_path)
            umls_concept = parsed_args["occur"]["umls_concept"]
            occur = pubMedMiner.occurance_matrix(db, umls_concept)
            display(occur)
        end
   end


end

main(ARGS)
