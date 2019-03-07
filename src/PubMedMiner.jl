"""
    PubMedMiner

Utilities to mine results from a PubMed/Medline search
Authors: Isabel Restrepo, Mary McGrath
BCBI - Brown University
"""
module PubMedMiner

using MySQL
using DataFrames

export get_occurrences_df,
    comorbidity_stats
include("Stats.jl")
include("MySQL_DB.jl")

# include("API_DF.jl")
include("Plotting.jl")

end #PubMedMiner
