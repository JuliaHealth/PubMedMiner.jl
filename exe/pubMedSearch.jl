# Executable to search PubMed for articles to a related term
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using PubMedMiner
using SQLite
using BioMedQuery.UMLS: Credentials
using BioMedQuery.Entrez


function main(args)

    # initialize the settings (the description is for the help screen)
   s = ArgParseSettings()
   s.description = "This is pubMedSearch.jl"
   s.version = "1.0"

   @add_arg_table s begin
    "--clean_db"
        help = "Flag indicating wether to empty database"
        action = :store_true
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


   parsed_args = parse_args(s) # the result is a Dict{String,Any}
   println("-------------------------------------------------------------")
   println(s.description)
   println("Parsed args:")
   for (key,val) in parsed_args
       println("  $key  =>  $(repr(val))")
   end
   println("-------------------------------------------------------------")

   email = parsed_args["email"]
   search_term = parsed_args["search_term"]
   max_articles = parsed_args["max_articles"]
   verbose= parsed_args["verbose"]
   db_config = Dict()
   save_func = nothing

   if haskey(parsed_args, "mysql")
       db_config = Dict(:host=>parsed_args["mysql"]["host"],
                        :dbname=>parsed_args["mysql"]["dbname"],
                        :username=>parsed_args["mysql"]["username"],
                        :pswd=>parsed_args["mysql"]["password"],
                        :overwrite=>parsed_args["clean_db"])
       save_func = save_efetch_mysql
   elseif haskey(parsed_args, "sqlite")
      db_config = Dict(:db_path=>parsed_args["sqlite"]["db_path"],
                       :overwrite=>parsed_args["clean_db"])
      save_func = save_efetch_sqlite
    else
      error("Unsupported database backend")
  end


   @time begin
       db = PubMedMiner.pubmed_search(email, search_term, max_articles,
       save_func, db_config, parsed_args["verbose"])
   end


end

main(ARGS)
