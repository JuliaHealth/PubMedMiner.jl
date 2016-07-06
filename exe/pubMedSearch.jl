# Executable to search PubMed for articles to a related term
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using pubMedMiner
using SQLite
using NLM.UMLS: Credentials


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
            default = typemax(Int64)
       "--search_term"
            help = "Term to search"
            default = "obesity"
       "--verbose"
            help = "Verbose. Store temp files with server response"
            action = :store_true
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
           db = pubMedMiner.pubmed_search(parsed_args["search"]["email"],
           parsed_args["search"]["search_term"], parsed_args["search"]["max_articles"],
           db_path, parsed_args["search"]["verbose"])
       end
   end

end

main(ARGS)
