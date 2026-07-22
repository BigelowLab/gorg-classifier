#!/usr/bin/env python

import csv
import gzip


mode = "$params.mode"
sample = "$sample"
hits_file = "$hits"
annotations_file = "$annotations"
results_file = sample + "_annotated.txt.gz"


def gzopen(path, mode="remote"):
    if path.endswith(".gz") or mode != "local":
        return gzip.open(path, "rt")
    else:
        return open(path)


annotations = {}
# annotation headers, including additional of a custom database
keep = []
with gzopen(annotations_file, mode=mode) as fh:
    header = fh.readline().strip().split("\\t")
    fh.seek(0)
    keep = header[7:]
    reader = csv.DictReader(fh, delimiter="\\t")
    for row in reader:
        annotations[f"{row['contig_id']};{int(float(row['start']))};{int(float(row['stop']))}"] = [
            row[i] for i in keep
        ]

extend_length = 8 + len(keep)
with gzopen(hits_file) as in_fh, gzip.open(results_file, "wt") as out_fh:
    # add header to the annotations output
    output_header = [
        "status",
        "sequence_id",
        "taxonomy_id",
        "length",
        "taxonomy_ids_lca",
        "sequence_ids_lca",
        "protein_sequence",
        "taxonomic_lineage",
    ]
    output_header.extend(keep)
    print(*output_header, sep="\\t", file=out_fh)

    for line in in_fh:
        toks = line.strip("\\r\\n").split("\\t")
        if toks[0] != "U":
            contig_id = toks[5].partition(",")[0]
            toks.extend(annotations[contig_id])
        print(*toks, sep="\\t", file=out_fh)
