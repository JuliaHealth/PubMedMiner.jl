using VegaLite
using DataFrames
using LinearAlgebra

# These are the same plots as in the web app, data is added after the fact, so stubbed values are used at first in the specs
# syntax highlighting not so great...

function barplot(stats::Stats)
  spec = vl"""
  {
    "title": {
      "text": "Top $(length(stats.mesh_names)) Co-Occuring Terms by Count"
    },
    "data": {
      "values": []
    },
    "mark": "bar",
    "encoding": {
      "x": {
        "field": "x",
        "type": "nominal",
        "sort": { "field": "y" }
      },
      "y": {
        "field": "y",
        "type": "quantitative"
      },
      "color": {
        "value": "\u00233B5B8C"
      },
      "tooltip" : [
        {
          "field": "x",
          "type": "nominal",
          "title": "MeSH"
        },
        {
          "field": "y",
          "type": "quantitative",
          "title": "Count"
        }
      ]
    }
  }
  """
  df = DataFrame(x=stats.mesh_names, y=stats.mesh_counts)
  spec(df)

  return nothing
end

function stats_matrix(stats::Stats, measure::Symbol)

  maxExtent = maximum(abs.(vals))
  minExtent = -1*maxExtent

  data = []
  for i = 1:length(stats.mesh_names), j = 1:length(stats.mesh_names)
    if i != j
      push!(data, (x=i,y=j,val=stats.measure[i,j]))
    end
  end

  table = data |> columntable

  spec = vl"""
  {
    "title": {
      "text": $string(measure)
    },
    "width": 700,
    "height": 700,
    "data": {
      "values": []
    },
    "transform": [
      {
        "filter": "datum.x != datum.y"
      }
    ],
    "config": { "axis": { "domain": false }},
    "mark": "rect",
    "encoding": {
      "x": {
        "field": "x",
        "type": "nominal",
        "axis": {
          "orient": "top",
          "ticks": false,
          "domain": false,
          "labelPadding": 4,
          "minExtent": 180
        }
       },
      "y": {
        "field": "y",
        "type": "nominal",
        "axis": {
          "ticks": false,
          "domain": false,
          "labelPadding": 4,
          "minExtent": 180
        }
      },
      "color": {
        "field": "val",
        "type": "quantitative",
        "legend": {
            "title": null
        },
        "scale": {
          "domain": [$minExtent, 0, $maxExtent],
          "range": ["\u00234d4d4d", "\u0023bababa", "\u0023ffffff", "\u0023ffffff", "\u002367a9cf","\u00233B5B8C"]
        }
      },
      "tooltip": [
        {
          "field": "x",
          "type": "nominal",
          "title": "MeSH 1"
        },
        {
          "field": "y",
          "type": "nominal",
          "title": "MeSH 2"
        },
        {
          "field": "val",
          "type": "quantitative",
          "title": "Value"
        }
      ]
    }
  """
  spec(table)
end

function chord_diagram(stats::Stats)

end
