# Executable to search PubMed for articles to a related term
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
        required = true
   "search"
        help = "Run a search"
        action = :command
   end


   @add_arg_table s["search"] begin
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
   end



   parsed_args = parse_args(s) # the result is a Dict{String,Any}
   println("Parsed args:")
   for (key,val) in parsed_args
       println("  $key  =>  $(repr(val))")
   end

   db_path  = parsed_args["db_path"]

   if haskey(parsed_args, "search")
       #Safety only clean before searching
       if ( parsed_args["clean_db"])
           println("Cleanning Database")
           pubMedMiner.clean_db(db_path)
       end
       @time begin
           db = pubMedMiner.pubmed_search_term(parsed_args["search"]["email"],
           parsed_args["search"]["max_articles"], parsed_args["search"]["search_term"],
           db_path)
       end
   end

end

main(ARGS)
