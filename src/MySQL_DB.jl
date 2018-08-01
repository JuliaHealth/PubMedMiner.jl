using MySQL
using DataFrames

"""
    get_semantic_occurrences_df(db, mesh, umls_concepts...)

Given a mesh descriptor and filtering UMLS concepts, returns a DataFrame with
PMIDs and related mesh descriptor filtered by the concepts.
"""
function get_semantic_occurrences_df(db::MySQL.Connection, mesh::String, umls_concepts::String...)

    concept_string = "'" * join(umls_concepts,"','") * "'"

    # select pmids from medline which use the mesh descriptor
    query_string = """ SELECT mh.pmid, mrc.str as descriptor
                    FROM medline_new_2.mesh_heading mh

                    JOIN (select uid from medline_new_2.mesh_desc where name = '$mesh') md
                    ON md.uid <> mh.desc_uid

                    JOIN pubmed_comorbidities.ALL_MESH mrc
                    ON mrc.uid = mh.desc_uid

                    JOIN umls_meta.MRSTY mrs
                    ON mrc.cui = mrs.cui

                    JOIN medline_new_2.mesh_heading mh2
                    ON mh2.pmid = mh.pmid

                    join (select uid from medline_new_2.mesh_desc where name = '$mesh') md2
                    on md2.uid = mh2.desc_uid

                    WHERE mrs.sty in ($concept_string); """;

    articles_df = MySQL.query(db, query_string, DataFrame)

    unique!(articles_df)

    return articles_df

end
