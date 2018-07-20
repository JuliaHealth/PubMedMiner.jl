"""
    PubMedMiner

Utilities to mine results from a PubMed/Medline search
Authors: Isabel Restrepo, Mary McGrath
BCBI - Brown University
"""
module PubMedMiner

using MySQL
using DataFrames

export DatabaseConnection
include("common.jl")

# """
# ServerDB modules includes all functions that assume as Database Server with access MySQL databases for MEDLINE,
# UMLS Metathesaurus and precomputed PuBMedMiner - more information on the schema to come.
# """
# module ServerDB
export get_semantic_occurrences_df,
    get_plotting_inputs
include("ServerDB.jl")

# end #ServerDB



end #PubMedMiner
