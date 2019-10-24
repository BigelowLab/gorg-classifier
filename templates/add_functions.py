#!/usr/bin/env python
from __future__ import print_function
import csv
import gzip


sample = "$sample"
hits_file = "$hits"
annotations_file = "$annotations"
results_file = sample + "_annotated.txt.gz"

gzopen = lambda f: gzip.open(f, "rt") if f.endswith(".gz") else open(f)

annotations = {}
# annotation headers, including additional of a custom database
keep = []
with gzopen(annotations_file) as fh:
    header = fh.readline().strip().split("\\t")
    fh.seek(0)
    keep = header[7:]
    reader = csv.DictReader(fh, delimiter="\\t")
    for row in reader:
        annotations[f"{row['contig_id']};{row['start']};{row['stop']}"] = [row[i] for i in keep]

extend_length = 8 + len(keep)
with gzopen(hits_file) as in_fh, gzip.open(results_file, "wt") as out_fh:
    for line in in_fh:
        toks = line.strip().split("\\t")
        # with names, there are 7 columns
        # then add the length of `keep` to maintain rectangular table
        if toks[0] == "U":
            toks.extend([""] * extend_length)
        else:
            contig_id = toks[5].partition(",")[0]
            toks.extend(annotations[contig_id])
        print(*toks, sep="\\t", file=out_fh)
