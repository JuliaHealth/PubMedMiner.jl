using BCBIStats
using StatsBase
using FreqTables
using ARules
using SparseArrays

mutable struct Stats
    pmid_count::Int

    mesh_names::Vector{String}

    topn_mesh_labels::Vector{String}
    topn_mesh_counts::Vector{Integer}

    pmi_sp::SparseMatrixCSC{Float64,Integer}
    top_coo_sp::SparseMatrixCSC{Int64, Int64}
    corrcoef::Array{Float64}

    mh_rules_pmid_count::Int
    mh_rules_df::DataFrame

end

Stats() = Stats(0, [], [], [], Array{Any,2}(undef, 0, 0), Array{Any,2}(undef, 0, 0), [], 0, DataFrame(lhs = [], rhs = [], supp = [], conf = [], lift = []))


"""
    get_plotting_inputs(mesh_df, topn)

Given a dataframe with PMIDs and Mesh Terms, returns various statistics for plotting
"""
function mesh_stats(mesh_df::DataFrame, topn::Int=50)

    # convert dataframe to frequency table
    mesh_frequencies = freqtable(string.(mesh_df[:pmid]), mesh_df[:descriptor])

    # total number of articles
    pmid_count = length(unique(mesh_df[:pmid]))

    # find the counts by mesh term, find the top mesh headings, and names
    mesh_counts = vec(sum(mesh_frequencies, 1))
    count_perm = sortperm(mesh_counts, rev=true)
    mesh_names = collect(keys(mesh_frequencies.dicts[2]))

    # check if there are topn frequencies, if not use length
    topn = min(topn, length(mesh_names))

    #RETURN LABELS FOR ALL CHARTS
    top_mesh_labels = mesh_names[count_perm[1:topn]]

    #RETURN FOR BAR CHART
    topn_mesh = mesh_counts[count_perm[1:topn]]

    #co-occurrance matrix - only for top MeSH
    top_occ = mesh_frequencies.array[:, count_perm[1:topn]]
    top_occ_sp = sparse(top_occ)
    top_coo_sp = top_occ_sp' * top_occ_sp

    # RETURN FOR PLOT MATRICES
    #Point Mutual Information
    pmi_sp = BCBIStats.COOccur.pmi_mat(top_coo_sp, pmid_count)
    #chi2
    # top_chi2= BCBIStats.COOccur.chi2_mat(top_occ, min_freq=0) NOT USED RIGHT NOW
    #correlation
    corrcoef = BCBIStats.COOccur.corrcoef(top_occ);

    # convert to BitArray
    mh_occ = convert(BitArray{2}, mesh_frequencies.array)

    # ARules

    top_mesh_df = filter(row -> row[:descriptor] in top_mesh_labels, mesh_df)

    fsets = Array{Array{String,1},1}()
    idx = Dict{Int32,Int}()

    for i = 1:size(top_mesh_df)[1]
      if haskey(idx, top_mesh_df[i,:pmid])
        push!(fsets[idx[top_mesh_df[i,:pmid]]], top_mesh_df[i,:descriptor])
      else
        push!(fsets, [top_mesh_df[i,:descriptor]])
        idx[top_mesh_df[i,:pmid]] = length(fsets)
      end
    end

    mh_rules_pmid_count = idx.count

    # find ARules - not actually used in plots?
    mh_rules = apriori(fsets, supp = 0.001, conf = 0, maxlen = 9)


    return PubMedMiner.Stats(
        pmid_count,
        mesh_names,
        top_mesh_labels,
        topn_mesh,
        pmi_sp,
        top_coo_sp,
        corrcoef,
        # mh_rules,
        # rules_df,
        # root,
        mh_rules_pmid_count,
        mh_rules
        # s,
        # t,
        # v
    )

end
