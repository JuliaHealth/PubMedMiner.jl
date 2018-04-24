
#Optional for running Step 1. However, sometimes the concurrancy of DatabaBase creates errors. 
#If that happens, reduce the number of process or comment out the line completely. 
#The fewer the processes the longer the task. At times I've successfully used 12 workers, at others only 2
# addprocs(2); 

using Revise #used during development to detect changes in module - unknown behavior if using multiple processes
using PubMedMiner

#Settings
const mh = "Colonic Neoplasms"
const concepts = ("Disease or Syndrome", "Mental or Behavioral Dysfunction", "Neoplastic Process");

overwrite = false
@time save_semantic_occurrences(mh, concepts...; overwrite = overwrite) 

using FreqTables

@time occurrence_df = get_semantic_occurrences_df(mh, concepts...);

#temporary fix - FreqTables breaking with Unions of Missings
#see https://github.com/nalimilan/FreqTables.jl/issues/23

occurrence_df[:descriptor] = convert(Vector{String}, occurrence_df[:descriptor])
occurrence_df[:pmid] = convert(Vector{Int}, occurrence_df[:pmid])

@time mesh_frequencies = freqtable(occurrence_df, :pmid, :descriptor);

info("Found ", size(occurrence_df, 1), " related descriptors")

using PlotlyJS
using NamedArrays

# Visualize frequency 
topn = 50
mesh_counts = vec(sum(mesh_frequencies, 1))
count_perm = sortperm(mesh_counts, rev=true)
mesh_names = collect(keys(mesh_frequencies.dicts[2]))

#traces
#most frequent is epilepsy - remove from plot for better scaling
freq_trace = PlotlyJS.bar(; x = mesh_names[count_perm[2:topn]], y= mesh_counts[count_perm[2:topn]], marker_color="orange")

data = [freq_trace]
layout = Layout(;title="$(topn)-Most Frequent MeSH ",
                 showlegend=false,
                 margin= Dict(:t=> 70, :r=> 0, :l=> 50, :b=>200),
                 xaxis_tickangle = 90,)
plot(data, layout)

using BCBIStats.COOccur
using StatsBase

#co-occurrance matrix - only for topp MeSH 
# min_frequency = 5 -- alternatively compute topn based on min-frequency
top_occ = mesh_frequencies.array[:, count_perm[2:topn]]
top_mesh_labels = mesh_names[count_perm[2:topn]]
top_occ_sp = sparse(top_occ)
top_coo_sp = top_occ_sp' * top_occ_sp


#Point Mutual Information
pmi_sp = BCBIStats.COOccur.pmi_mat(top_coo_sp)
#chi2
top_chi2= BCBIStats.COOccur.chi2_mat(top_occ, min_freq=0);
#correlation
corrcoef = BCBIStats.COOccur.corrcoef(top_occ);

function plot_stat_mat(stat_mat, labels)
    stat_trace = heatmap(x=labels, y=labels, z=full(stat_mat- spdiagm(diag(stat_mat))))

    data = [stat_trace]
    layout = Layout(;
                     showlegend=false,
                     height = 900, width=900,
                     margin= Dict(:t=> 300, :r=> 0, :l=> 200, :b=>0),
                     xaxis_tickangle = 90, xaxis_autotick=false, yaxis_autotick=false,
                     yaxis_autorange = "reversed",
                     xaxis_side = "top", 
                     xaxis_ticks = "", yaxis_ticks = "")
    plot(data, layout)
end

plot_stat_mat(corrcoef, top_mesh_labels)

plot_stat_mat(pmi_sp, top_mesh_labels)

using PlotlyJSFactory

p = create_chord_plot(top_coo_sp, labels = top_mesh_labels)
relayout!(p, title="Co-occurrances between top 50 MeSH terms")
JupyterPlot(p)


using ARules
using DataFrames

# Remove serch MeSH (set column to 0). Rules of lenght 2 with search term correspond to histogram, 
# since it is in every transaction
mh_occ = convert(BitArray{2}, mesh_frequencies.array)

mh_col = mesh_frequencies.dicts[2][mh]
mh_occ[:, mh_col] = zeros(size(mh_occ,1))

mh_lkup = convert(DataStructures.OrderedDict{String,Int16}, mesh_frequencies.dicts[2]) 
@time mh_rules = apriori(mh_occ, supp = 0.001, conf = 0.1, maxlen = 9)

#Pretty print of rules
mh_lkup = Dict(zip(values(mesh_frequencies.dicts[2]), keys(mesh_frequencies.dicts[2])))
rules_dt= ARules.rules_to_dataframe(mh_rules, mh_lkup, join_str = " | ");

println(head(rules_dt))
println("Found ", size(rules_dt, 1), " rules")

supp_int = round(Int, 0.001 * size(mh_occ, 1))
@time root = frequent_item_tree(mh_occ, supp_int, 9);

supp_lkup = gen_support_dict(root, size(mh_occ, 1))
item_lkup = mesh_frequencies.dicts[2]
item_lkup_t = Dict(zip(values(item_lkup), keys(item_lkup)))
freq = ARules.suppdict_to_dataframe(supp_lkup, item_lkup_t);

println(head(freq))
println("Found ", size(freq, 1), " frequent itemsets")

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

sources = []
targets = []
vals = []
fill_sankey_data!(root, sources, targets, vals);

# size(sources)
topn_links = 50
freq_vals_perm = sortperm(vals, rev=true)
s = sources[freq_vals_perm[1:topn_links]]
t = targets[freq_vals_perm[1:topn_links]]
v = vals[freq_vals_perm[1:topn_links]]
l = mesh_names

println("Found, ", length(sources), "links, showing ", topn_links)

pad = 1e-7
trace=sankey(orientation="h",
             node = attr(domain=attr(x=[0,1], y=[0,1]), pad=pad, thickness=pad, line = attr(color="black", width= 0.5),
                         label=l), 
             link = attr(source=s, target=t, value = v))

layout = Layout(width=900, height=1100)

plot([trace], layout)
