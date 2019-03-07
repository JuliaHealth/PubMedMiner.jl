using BCBIStats
using StatsBase
using FreqTables
using ARules
using SparseArrays

mutable struct Stats{T}
    unit_count::Int

    codes::Vector{T}

    topn_codes::Vector{T}
    topn_counts::Vector{Integer}

    pmi_sp::SparseMatrixCSC{Float64, Integer}
    top_coo_sp::SparseMatrixCSC{Int64, Int64}
    corrcoef::Array{Float64}

    rules_unit_count::Int
    rules_df::DataFrame

end

Stats() = Stats(0, [], [], [], Array{Any,2}(undef, 0, 0), Array{Any,2}(undef, 0, 0), [], 0, DataFrame(lhs = [], rhs = [], supp = [], conf = [], lift = []))


"""
    comorbidity_stats(df, topn)

Given a dataframe with IDs (e.g. PMID) and Terms/Codes (e.g. Mesh), returns various statistics for plotting
"""
function comorbidity_stats(df::DataFrame, topn::Int=50)

    # convert dataframe to frequency table
    frequencies = freqtable(df[:id], df[:code])

    # total number of ids
    id_count = length(unique(df[:id]))

    # find the counts by term, find the top terms
    counts = vec(sum(frequencies, dims=1))
    count_perm = sortperm(counts, rev=true)
    names = collect(keys(frequencies.dicts[2]))

    # check if there are topn frequencies, if not use length
    topn = min(topn, length(names))

    #RETURN LABELS FOR ALL CHARTS
    topn_terms = names[count_perm[1:topn]]

    #RETURN FOR BAR CHART
    topn_counts = counts[count_perm[1:topn]]

    #co-occurrance matrix - only for top MeSH
    top_occ = frequencies.array[:, count_perm[1:topn]]
    top_occ_sp = sparse(top_occ)
    top_coo_sp = top_occ_sp' * top_occ_sp

    # RETURN FOR PLOT MATRICES
    #Point Mutual Information
    pmi_sp = BCBIStats.COOccur.pmi_mat(top_coo_sp, id_count)
    #chi2
    # top_chi2= BCBIStats.COOccur.chi2_mat(top_occ, min_freq=0) NOT USED RIGHT NOW
    #correlation
    corrcoef = BCBIStats.COOccur.corrcoef(top_occ);

    # convert to BitArray
    # term_occ = convert(BitArray{2}, frequencies.array)

    # ARules
    top_term_df = filter(row -> row[:code] in topn_terms, df)

    fsets = Array{Array{String,1},1}()
    idx = Dict{Int,Int}()

    for i = 1:size(top_term_df)[1]
      if haskey(idx, top_term_df[i,:id])
        push!(fsets[idx[top_term_df[i,:id]]], string(top_term_df[i,:code]))
      else
        push!(fsets, [string(top_term_df[i,:code])])
        idx[top_term_df[i,:id]] = length(fsets)
      end
    end

    rules_id_count = idx.count

    # find ARules - not actually used in plots?
    rules = apriori(fsets, supp = 0.2, conf = 0, maxlen = 9)


    return PubMedMiner.Stats{typeof(df[1,:code])}(
        id_count,
        names,
        topn_terms,
        topn_counts,
        pmi_sp,
        top_coo_sp,
        corrcoef,
        rules_id_count,
        rules
    )

end
