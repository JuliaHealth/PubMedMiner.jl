using BCBIStats
using StatsBase
using FreqTables
using NamedArrays
using ARules

mutable struct Stats
    mesh_names::Vector{String}

    topn_mesh_labels::Vector{String}
    topn_mesh_counts::Vector{Integer}

    pmi_sp::SparseMatrixCSC{Float64,Integer}
    top_chi2::LowerTriangular
    corrcoef::Array{Float64}

    mh_rules::Array{ARules.Rule}
    mh_rules_df::DataFrame

    freq_item_tree::ARules.Node
    freq_item_df::DataFrame

    sankey_sources::Array{Integer}
    sankey_targets::Array{Integer}
    sankey_vals::Array{Integer}
end

function fill_sankey_data(node)
    sources = Array{Integer}(0)
    targets = Array{Integer}(0)
    vals = Array{Integer}(0)
    if length(node.item_ids) >1
        push!(sources, node.item_ids[end-1]-1)
        push!(targets, node.item_ids[end]-1)
        push!(vals, node.supp)
    end
    if has_children(node)
        for nd in node.children
            fill_sankey_data!(nd,  sources, targets, vals)
        end
    end

    return sources, targets, vals
end

function fill_sankey_data!(node, sources, targets, vals)
    if length(node.item_ids) >1
        push!(sources, node.item_ids[end-1]-1)
        push!(targets, node.item_ids[end]-1)
        push!(vals, node.supp)
    end
    if has_children(node)
        for nd in node.children
            fill_sankey_data!(nd,  sources, targets, vals)
        end
    end
end

"""
    get_plotting_inputs(mesh_df, topn)

Given a dataframe with PMIDs and Mesh Terms, returns various statistics for plotting
"""
function get_plotting_inputs(mesh_df::DataFrame, topn::Integer=50)

    # convert dataframe to frequency table
    mesh_frequencies = freqtable(mesh_df, :pmid, :descriptor)

    # find the counts by mesh term, find the top mesh headings, and names
    mesh_counts = vec(sum(mesh_frequencies, 1))
    count_perm = sortperm(mesh_counts, rev=true)
    mesh_names = collect(keys(mesh_frequencies.dicts[2]))
    top_mesh_labels = mesh_names[count_perm[1:topn]]

    #RETURN FOR BAR CHART
    topn_mesh = mesh_counts[count_perm[1:topn]]

    #co-occurrance matrix - only for top MeSH
    top_occ = mesh_frequencies.array[:, count_perm[1:topn]]
    top_occ_sp = sparse(top_occ)
    top_coo_sp = top_occ_sp' * top_occ_sp

    # RETURN FOR PLOT MATRICES
    #Point Mutual Information
    pmi_sp = BCBIStats.COOccur.pmi_mat(top_coo_sp)
    #chi2
    top_chi2= BCBIStats.COOccur.chi2_mat(top_occ, min_freq=0)
    #correlation
    corrcoef = BCBIStats.COOccur.corrcoef(top_occ);

    # convert to BitArray
    mh_occ = convert(BitArray{2}, mesh_frequencies.array)

    # find ARules - not actually used in plots?
    mh_rules = apriori(mh_occ, supp = 0.001, conf = 0.1, maxlen = 9)

    # ARules to DF
    mh_lkup = Dict(zip(values(mesh_frequencies.dicts[2]), keys(mesh_frequencies.dicts[2])))
    rules_df= ARules.rules_to_dataframe(mh_rules, mh_lkup, join_str = " | ");

    # generate frequent item sets tree given supp
    supp_int = round(Int, 0.001 * size(mh_occ, 1))
    root = frequent_item_tree(mh_occ, supp_int, 9);

    # frequent item sets to df
    supp_lkup = gen_support_dict(root, size(mh_occ, 1))
    item_lkup = mesh_frequencies.dicts[2]
    item_lkup_t = Dict(zip(values(item_lkup), keys(item_lkup)))
    freq = ARules.suppdict_to_dataframe(supp_lkup, item_lkup_t)

    # get sankey data
    sources, targets, vals = PubMedMiner.fill_sankey_data(root)

    freq_vals_perm = sortperm(vals, rev=true)
    s = sources[freq_vals_perm[1:topn]]
    t = targets[freq_vals_perm[1:topn]]
    v = vals[freq_vals_perm[1:topn]]

    return PubMedMiner.Stats(
        mesh_names,
        top_mesh_labels,
        topn_mesh,
        pmi_sp,
        top_chi2,
        corrcoef,
        mh_rules,
        rules_df,
        root,
        freq,
        s,
        t,
        v
    )

end
