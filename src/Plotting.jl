using PlotlyJS
using PlotlyJSFactory

"""
    bar_plot_topn(mesh_names, mesh_counts)

Plots topn mesh terms vs their counts.
"""
function bar_plot_topn(mesh_names::Array{String}, mesh_counts::Array{Integer})
    #traces
    freq_trace = PlotlyJS.bar(; x = mesh_names, y= mesh_counts, marker_color="orange")

    data = [freq_trace]

    topn = length(mesh_names)

    layout = Layout(;title="$(topn)-Most Frequent MeSH",
                     showlegend=false,
                     margin= Dict(:t=> 70, :r=> 0, :l=> 50, :b=>200),
                     xaxis_tickangle = 90,)
    plot(data, layout)
end


"""
    plot_stat_mat(stat_mat, mesh_names)

Creates a heat map showing pair statistics of the MeSH terms. For use with:
* Point Mutual Information (PubMedMiner.Stats.pmi_sp)
* Correlation (PubMedMiner.Stats.corrcoef)
"""
function plot_stat_mat(stat_mat, mesh_names)
    stat_trace = heatmap(x=mesh_names, y=mesh_names, z=full(stat_mat- spdiagm(diag(stat_mat))))

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

"""
    plot_chord_coo(top_coo_sp, mesh_names)

Creates a chord diagram showing relationships between the topn mesh terms.
"""
function plot_chord_coo(top_coo_sp, mesh_names)
    p = create_chord_plot(top_coo_sp, labels = mesh_names)

    # Adding title not working right now...

    # topn = length(mesh_names)
    #
    # relayout!(p, title="Co-occurrances between top $topn MeSH terms")
    #
    # plot(p)
end

"""
    plot_sankey_arules(source, target, value, all_mesh_names)

Creates a sankey plot showing the frequent item sets.
"""
function plot_sankey_arules(source, target, value, all_mesh_names)
    pad = 1e-7
    trace=sankey(orientation="h",
         node = attr(domain=attr(x=[0,1], y=[0,1]), pad=pad, thickness=pad, line=attr(color="black", width=0.5), label=all_mesh_names),
         link = attr(source=source, target=target, value = value))

    layout = Layout(width=900, height=1100)

    plot([trace], layout)
end
