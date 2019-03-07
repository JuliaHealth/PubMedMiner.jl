using VegaLite
using DataFrames
using JSON
using Combinatorics

# These are the same plots as in the web app, data is added after the fact, so stubbed values are used at first in the specs
# syntax highlighting not so great...

function barplot(stats::Stats)
  spec = """
  {
    "title": {
      "text": "Top $(length(stats.topn_codes)) Co-Occuring Terms by Count"
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
          "title": "Code"
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

  dict = JSON.parse(spec)

  data = DataFrame(x=stats.topn_codes, y=stats.topn_counts)

  # return dict

  plot = VegaLite.VLSpec{:plot}(dict)(data)

  # plot(data)

  return plot
end

function stats_matrix(stats::Stats, measure::Symbol)

  vals = getfield(stats, measure)

  maxExtent = maximum(abs.(vals))
  d = [-1*maxExtent, 0, maxExtent]

  data = []
  for i = 1:length(stats.topn_codes), j = 1:length(stats.topn_codes)
    push!(data, (x=stats.topn_codes[i],y=stats.topn_codes[j],val=vals[i,j]))
  end

  table = data |> DataFrame

  spec = """
  {
    "title": {
      "text": "$(string(measure))"
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
          "domain": $d,
          "range": ["\u00234d4d4d", "\u0023bababa", "\u0023ffffff", "\u0023ffffff", "\u002367a9cf","\u00233B5B8C"]
        }
      },
      "tooltip": [
        {
          "field": "x",
          "type": "nominal",
          "title": "Code 1"
        },
        {
          "field": "y",
          "type": "nominal",
          "title": "Code 2"
        },
        {
          "field": "val",
          "type": "quantitative",
          "title": "Value"
        }
      ]
    }
  }
  """
  dict = JSON.parse(spec)

  return VegaLite.VLSpec{:plot}(dict)(table)
end

function chord_diagram(stats::Stats)
  chordRules = []
  ruleID = 0
  for row in eachrow(stats.rules_df)
    lhs = row[:lhs][2:end-1]
    lhsArr = split(lhs, " | ")

    rhs = row[:rhs]
    shortName = length(rhs) > 25 ? rhs[1:25] * "..." : rhs

    perms = permutations(lhsArr) |> collect

    for perm in perms
      newLhs = join(perm, " | ")
      fset = newLhs * " | " * rhs
      ruleID += 1
      push!(chordRules, (id=ruleID, lhs=newLhs, rhs=rhs, sname=shortName, fset=fset, fsetSize=length(perm)+1, conf=round(row[:conf], digits=4), lift=round(row[:lift], digits=4), supp=round(row[:supp], digits=4)))
    end
  end

  println("size rules: ", size(stats.rules_df))
  println("size perms: ", length(chordRules))

  sort!(chordRules, by= x -> x.supp, rev=true)

  chordIDs = []

  for i in 1:length(stats.topn_codes) # topn_codes
    code = string(stats.topn_codes[i])
    shortName = length(code) > 25 ? code[1:25] * "..." : code

    push!(chordIDs, (id=i-1, name=code, sname=shortName, supp=round(stats.topn_counts[i] / stats.rules_unit_count, digits=4)))

    ruleID += 1
    push!(chordRules, (id=ruleID, lhs=missing, rhs=code, sname=shortName, fset=code, fsetSize=1, conf=0, lift=0, supp=round(stats.topn_counts[i] / stats.rules_unit_count, digits=4)))
  end

  chordRels=[]
  for i = 1:length(stats.topn_codes), j = 1:length(stats.topn_codes)
    if i < j && stats.top_coo_sp[i,j] > 0
      push!(chordRels, (source=i-1, target=j-1, size=stats.top_coo_sp[i,j]))
    end
  end

  ruleStr = json(chordRules)
  idStr = json(chordIDs)
  relStr = json(chordRels)

  dataSize = length(chordIDs)
  maxEdgeSize = maximum(x->x.size, chordRels)
  maxFreqItems = maximum(x->x.fsetSize, chordRules)

  spec = """
  {
    "\$schema": "https://vega.github.io/schema/vega/v4.4.0.json",
    "autosize": "pad",
    "padding": 5,
    "height": 700,

    "signals": [
      { "name": "chordWidth", "value": 600},
      { "name": "originX", "update": "chordWidth / 2" },
      { "name": "originY", "update": "height / 2" },
      { "name": "radius", "update": "chordWidth / 2 - 175" },
      { "name": "dataSize", "update": $dataSize },
      { "name": "maxEdgeSize", "update": $maxEdgeSize },
      { "name": "maxFreqItems", "value": $(maxFreqItems-1) },
      { "name": "textOffset", "value": 5 },
      { "name": "textSize", "value": 11 },
      { "name": "treeWidth", "value": $((maxFreqItems-1)*175 + 320)},
      {
        "name": "clicked",
        "value": {},
        "on": [
          { "events": "@cell:click", "update": "clicked && clicked.id === datum.id ? {} : datum" }
        ]
      },
      {
        "name": "active",
        "value": {},
        "update": "clicked",
        "on": [
          { "events": "@cell:mouseover", "update": "clicked.name ? clicked : datum" },
          { "events": "@cell:mouseout", "update": "clicked.name ? clicked : {}" }
        ]
      },
      {
        "name": "freqItems",
        "value": { "fset": "", "supp": 0 },
        "update": "active ? {'fset': active.name, 'supp': active.supp} : (clickedRule && {'fset': clickedRule.fset, 'supp': clickedRule.supp})",
        "on": [
          { "events": "@ruleNodes:click", "update": "{'fset': datum.rule.fset, 'supp': datum.rule.supp}" },
          { "events": "@ruleLabels:click", "update": "{'fset': datum.rule.fset, 'supp': datum.rule.supp}" }
        ]
      },
      {
        "name": "clickedRule",
        "value": {},
        "update": "clicked && {}",
        "on": [
          { "events": "@ruleNodes:click", "update": "clickedRule.fset && clickedRule.fset === datum.fset ? {} : datum" },
          { "events": "@ruleLabels:click", "update": "clickedRule.fset && clickedRule.fset === datum.fset ? {} : datum" }
        ]
      },
      {
        "name": "activeRule",
        "value": {},
        "update": "clickedRule",
        "on": [
          { "events": "@ruleNodes:mouseover", "update": "(clickedRule.fset && datum.depth <= clickedRule.depth) ? clickedRule : datum" },
          { "events": "@ruleNodes:mouseout", "update": "clickedRule.fset ? clickedRule : {}" },
          { "events": "@ruleLabels:mouseover", "update": "(clickedRule.fset && datum.depth <= clickedRule.depth) ? clickedRule : datum" },
          { "events": "@ruleLabels:mouseout", "update": "clickedRule.fset ? clickedRule : {}" }
        ]
      }
    ],

    "data": [
      {
        "name": "edges",
        "values" : $relStr,
        "transform": [
          {
            "type": "formula", "as": "strokeSize",
            "expr": "max(min(datum.size / $maxEdgeSize * 10, 7), 0.3)"
          }
        ]
      },
      {
        "name": "sourceDegree",
        "source": "edges",
        "transform": [
          {"type": "aggregate", "groupby": ["source"]}
        ]
      },
      {
        "name": "targetDegree",
        "source": "edges",
        "transform": [
          {"type": "aggregate", "groupby": ["target"]}
        ]
      },
      {
        "name": "nodes",
        "values": $idStr,
        "transform": [
          { "type": "window", "ops": ["rank"], "as": ["order"] },
          {
            "type": "lookup", "from": "sourceDegree", "key": "source",
            "fields": ["id"], "as": ["sourceDegree"],
            "default": {"count": 0}
          },
          {
            "type": "lookup", "from": "targetDegree", "key": "target",
            "fields": ["id"], "as": ["targetDegree"],
            "default": {"count": 0}
          },
          {
            "type": "formula", "as": "degree",
            "expr": "datum.sourceDegree.count + datum.targetDegree.count"
          },
          {
            "type": "formula", "as": "angle",
            "expr": "( 360 * datum.id / $dataSize + 270) % 360"
          },
          {
            "type": "formula",
            "expr": "inrange(datum.angle, [90, 270])",
            "as":   "leftside"
          },
          {
            "type": "formula", "as": "x",
            "expr": "originX + radius * cos(PI * datum.angle / 180)"
          },
          {
            "type": "formula", "as": "y",
            "expr": "originX + radius * sin(PI * datum.angle / 180)"

          },
          {
            "type": "voronoi",
            "x": "x",
            "y": "y",
            "size": [{"signal": "height"}, {"signal": "height"}]
          }
        ]
      },
      {
        "name": "selected",
        "source": "edges",
        "transform": [
          {
            "type": "filter",
            "expr": "datum.source === active.id || datum.target === active.id"
          }
        ]
      },
      {
        "name": "activeNode",
        "source": "nodes",
        "transform": [
          {
            "type": "filter",
            "expr": "datum.id === active.id"
          }
        ]
      },
      {
        "name": "rules",
        "values": $ruleStr
      },
      {
        "name": "rulesFilter",
        "source": "rules",
        "transform": [
          {
            "type": "filter",
            "expr": "(datum.lhs === null && datum.rhs === active.name) || datum.lhs === active.name ||  (freqItems.fset && datum.lhs === freqItems.fset) || (freqItems.fset && (datum.lhs + ' |') === substring(freqItems.fset, 0, length(datum.lhs + ' |')))"
          },
          {
            "type": "formula",
            "as": "lhsArr",
            "expr": "datum.lhs ? split(datum.lhs, ' | ') : null"
          },
          {
            "type": "window",
            "groupby": ["lhs"],
            "sort": {"field": "supp", "order": "descending"},
            "ops": ["row_number"],
            "as": ["rank"]
          },
          {
            "type": "formula",
            "as": "hasChildren",
            "expr": "indata('rules', 'lhs', datum.fset)"
          }
        ]
      },
      {
        "name": "tree",
        "source": "rulesFilter",
        "transform": [
          {
            "type": "stratify",
            "key": "fset",
            "parentKey": "lhs"
          },
          {
            "type": "tree",
            "method": "tidy",
            "size": [{"signal": "height-70"}, {"signal": "treeWidth"}],
            "as": ["y", "origX", "depth", "children"]
          },
          {
            "type": "formula",
            "as": "x",
            "expr": "(datum.depth / $maxFreqItems) * (treeWidth - 320)"
          },
          {
            "type": "lookup",
            "from": "rulesFilter",
            "key": "fset",
            "fields": ["fset"],
            "as": ["rule"]
          }
        ]
      },
      {
        "name": "links",
        "source": "tree",
        "transform": [
          { "type": "treelinks" },
          {
            "type": "linkpath",
            "shape": "diagonal",
            "orient": "horizontal"
          }
        ]
      }
    ],

    "layout": {
      "padding": 10,
      "offset": 20,
      "bounds": "full",
      "align": "none",
      "center": {"row": true}
    },

    "marks": [
      {
        "type": "group",
        "name": "chord",
        "title": {
          "text": "Co-Occurences of Codes in Population",
          "frame": "group",
          "fontSize": 22
        },

        "encode": {
          "update": {
            "width": { "signal": "chordWidth" },
            "height": { "signal": "height" }
          }
        },

        "marks": [
          {
            "type": "symbol",
            "name": "layout",
            "interactive": false,
            "from": {"data": "nodes"},
            "encode": {
              "enter": {
                "opacity": {"value": 0}
              },
              "update": {
                "x": {"field": "x"},
                "y": {"field": "y"}
              }
            }
          },
          {
            "type": "path",
            "from": {"data": "edges"},
            "encode": {
              "update": {
                "stroke": [
                  {"value": "#3B5B8C"}
                ],
                "strokeOpacity": [
                  {"test": "datum.source === active.id || datum.target === active.id", "value": 1 },
                  {"test": "active.name", "value": 0},
                  {"value": 0.07}
                ],
                "strokeWidth": {"field": "strokeSize"},
                "strokeCap": "round"
              }
            },
            "transform": [
              {
                "type": "lookup", "from": "layout", "key": "datum.id",
                "fields": ["datum.source", "datum.target"],
                "as": ["sourceNode", "targetNode"]
              },
              {
                "type": "linkpath",
                "sourceX": {"expr": "datum.sourceNode.x"},
                "targetX": {"expr": "datum.targetNode.x"},
                "sourceY": {"expr": "datum.sourceNode.y"},
                "targetY": {"expr": "datum.targetNode.y"},
                "shape": "diagonal"
              }
            ]
          },
          {
            "type": "text",
            "name": "textNodes",
            "from": {"data": "nodes"},
            "encode": {
              "enter": {
                "text": {"field": "sname"},
                "baseline": {"value": "middle"}
              },
              "update": {
                "x": {"field": "x"},
                "y": {"field": "y"},
                "dx": {"signal": "textOffset * (datum.leftside ? -1 : 1)"},
                "angle": {"signal": "datum.leftside ? datum.angle - 180 : datum.angle"},
                "align": {"signal": "datum.leftside ? 'right' : 'left'"},
                "fontSize": [
                  {"test": "datum.id === active.id", "signal": "textSize*1.2" },
                  {"signal": "textSize"}
                ],
                "fontWeight": [
                  {"test": "indata('selected', 'source', datum.id)", "value": "bold"},
                  {"test": "indata('selected', 'target', datum.id)", "value": "bold"},
                  {"value": null}
                ],
                "fill": [
                  {"test": "indata('selected', 'source', datum.id)", "value": "black"},
                  {"test": "indata('selected', 'target', datum.id)", "value": "black"},
                  { "value": "LightSlateGray" }
                ]
              }
            }
          },
          {
            "type": "path",
            "name": "cell",
            "from": {"data": "nodes"},
            "encode": {
              "enter": {
                "fill": {"value": "transparent"},
                "strokeWidth": {"value": 0.35}
              },
              "update": {
                "path": {"field": "path"}
              }
            }
          }
        ]
      },



      {
        "type": "group",
        "name": "activeTree",
        "title": {
          "text": "Frequent Itemset Tree of Selected Code",
          "frame": "group",
          "fontSize": 22
        },

        "encode": {
          "enter": {
            "width": { "signal": "treeWidth" },
            "height": { "signal": "height" }
          }
        },

        "marks": [
          {
            "type": "path",
            "from": {"data": "links"},
            "encode": {
              "enter": {
                "stroke": {"value": "#ccc"},
                "x": {"value": 160},
                "y": {"value": 30}
              },
              "update": {
                "path": {"field": "path"}
              }
            }
          },
          {
            "type": "symbol",
            "name": "ruleNodes",
            "from": {"data": "tree"},
            "encode": {
              "enter": {
                "size": {"value": 200},
                "fill": {"value": "#3B5B8C"},
                "stroke": {"value": "#3B5B8C"}
              },
              "update": {
                "x": {"signal": "datum.x + 160"},
                "y": {"signal": "datum.y + 30"},
                "fillOpacity": {"signal": "datum.hasChildren ? 1 : 0"}
              },
              "hover": {
                "fillOpacity": {"value": 0.5}
              }
            }
          },
          {
            "type": "text",
            "name": "ruleLabels",
            "from": {"data": "tree"},
            "encode": {
              "enter": {
                "text": {"field": "sname"},
                "fontSize": {"value": 10},
                "baseline": {"value": "middle"},
                "opacity": {"value": 1}
              },
              "update": {
                "x": {"signal": "datum.x + 160"},
                "y": {"signal": "datum.y + 30"},
                "dx": {"signal": "(datum.depth === 0 ? -1 : 1) * 12"},
                "align": {"signal": "datum.depth === 0 ? 'right' : 'left'"},
                "fontWeight": {"signal": "(datum.children || datum.fset === activeRule.fset) ? 'bold': ''"}
              }
            }
          },


          {
            "type": "text",
            "encode": {
              "enter": {
                "fontSize": {"value": 16},
                "baseline": {"value": "middle"},
                "x": {"signal": "treeWidth / 2"},
                "y": {"signal": "5"},
                "align": {"value": "center"},
                "opacity": {"value": 1}
              },
              "update": {
                "text": {"signal": "'{ ' + (activeRule.fset ? activeRule.fset : freqItems.fset) + ' }'"}
              }
            }
          },
          {
            "type": "text",
            "encode": {
              "enter": {
                "fontSize": {"value": 14},
                "baseline": {"value": "middle"},
                "x": {"signal": "treeWidth / 2"},
                "y": {"signal": "20"},
                "align": {"value": "center"},
                "opacity": {"value": 1}
              },
              "update": {
                "text": {"signal": "'Support: ' + (activeRule.supp ? activeRule.supp : freqItems.supp)"}
              }
            }
          },


          {
            "type": "symbol",
            "encode": {
              "enter": {
                "size": {"value": 200},
                "stroke": {"value": "#3B5B8C"},
                "xc": {"value": 20},
                "yc": {"signal": "height - 30"},
                "fill": {"value": "#3B5B8C"},
                "fillOpacity": {"value": 1}
              }
            }
          },
          {
            "type": "symbol",
            "encode": {
              "enter": {
                "size": {"value": 200},
                "stroke": {"value": "#3B5B8C"},
                "xc": {"value": 20},
                "yc": {"signal": "height - 10"},
                "fillOpacity": {"value": 0}
              }
            }
          },
          {
            "type": "text",
            "encode": {
              "enter": {
                "text": {"value": "Expandable"},
                "fontSize": {"value": 10},
                "x": {"value": 30},
                "y": {"signal": "height - 30"},
                "baseline": {"value": "middle"}
              }
            }
          },
          {
            "type": "text",
            "encode": {
              "enter": {
                "text": {"value": "Not Expandable"},
                "fontSize": {"value": 10},
                "x": {"value": 30},
                "y": {"signal": "height - 10"},
                "baseline": {"value": "middle"}
              }
            }
          },



          {
            "type": "text",
            "encode": {
              "enter": {
                "text": {"value": "Explore the Chord Diagram on the Left to see the Frequent Itemset Tree"},
                "fontSize": {"value": 14},
                "x": {"signal": "treeWidth / 2"},
                "y": {"signal": "height / 2"},
                "baseline": {"value": "middle"},
                "align": {"value": "center"},
                "fill": {"value": "DarkSlateGray"}
              },
              "update": {
                "text": {"signal": "(activeRule.fset || freqItems.fset) ? '' : 'Explore the Chord Diagram on the Left to see the Frequent Item Set Tree'"}
              }
            }
          }
        ]
      }
    ]
  }
  """
  dict = JSON.parse(spec)

  # return dict

  return VegaLite.VGSpec(dict)
end
