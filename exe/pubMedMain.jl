# Executable all pipeline functionality of PubMedMiner
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
   "--clean_db"
        help = "Flag indicating wether to empty database"
        action = :store_true
   "--db_path"
        help = "Path to database file to store results"
        arg_type = ASCIIString
    "all"
            help = "Run all commands"
            action = :command
   end



   @add_arg_table s["all"] begin
       "--email"
            help = "your email address - required by NCBI"
            arg_type = ASCIIString
            required = true
       "--max_articles"
            help = "Maximum number of articles"
            arg_type = Int
            default = 10
       "--search_term"
            help = "Term to search"
            default = "obesity"
        "--start_date"
            help = "Start (year) of date range to use for search"
            default = "2014"
            arg_type = ASCIIString
        "--end_date"
            help = "End (year) of the date range to use for search"
            default = "2015"
        "--umls_username"
             help = "UMLS-NLM username"
             arg_type = ASCIIString
             required = true
        "--umls_password"
             help = "UMLS-NLM password"
             arg_type = ASCIIString
             required = true
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

   if haskey(parsed_args, "all")
       #Safety only clean before searching
       if ( parsed_args["clean_db"])
           println("Cleanning Database")
           pubMedMiner.clean_db(db_path)
       end
       @time begin
           db = pubMedMiner.pubmed_search_term(parsed_args["all"]["email"],
           parsed_args["all"]["max_articles"], parsed_args["all"]["search_term"],
           db_path)
       end
       @time begin
           isdefined(:db) || (db = SQLite.DB(db_path))
           user = parsed_args["all"]["umls_username"]
           psswd = parsed_args["all"]["umls_password"]
           credentials = Credentials(user, psswd)
           pubMedMiner.map_mesh_to_umls(db, credentials)
       end
       @time begin
            isdefined(:db) || (db = SQLite.DB(db_path))
            umls_concept = parsed_args["all"]["umls_concept"]
            occur = pubMedMiner.occurance_matrix(db, umls_concept)
            display(occur)
        end
   end


end

main(ARGS)
