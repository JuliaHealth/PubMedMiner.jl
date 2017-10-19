"""
    PubMedMiner
    
Utilities to mine results from a PubMed/Medline search
Authors: Isabel Restrepo
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
export save_semantic_occurrences,
       get_semantic_occurrences_df
include("ServerDB.jl")

# end #ServerDB



end #PubMedMiner
