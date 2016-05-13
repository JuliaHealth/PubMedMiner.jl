# Executable to map MESH descriptors to UMLS concepts. Descriptors are
# assumed to be stored in a SQLite database containing table "mesh"
# Date: May 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5


using ArgParse
using pubMedMiner
using SQLite
import NLM.umls:Credentials


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
    "umls_map"
        help = "Build a UMLS map for the resulting search"
        action = :command
   end


   @add_arg_table s["umls_map"] begin
       "--umls_username"
            help = "UMLS-NLM username"
            arg_type = ASCIIString
            required = true
       "--umls_password"
            help = "UMLS-NLM password"
            arg_type = ASCIIString
            required = true
   end

   parsed_args = parse_args(s) # the result is a Dict{String,Any}
   println("Parsed args:")
   for (key,val) in parsed_args
       println("  $key  =>  $(repr(val))")
   end

   db_path  = parsed_args["db_path"]


   if haskey(parsed_args, "umls_map")
       @time begin
           isdefined(:db) || (db = SQLite.DB(db_path))
           user = parsed_args["umls_map"]["umls_username"]
           psswd = parsed_args["umls_map"]["umls_password"]
           credentials = Credentials(user, psswd)
           pubMedMiner.map_mesh_to_umls(db, credentials)
       end
   end


end

main(ARGS)
