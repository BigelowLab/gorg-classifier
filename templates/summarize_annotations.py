#!/usr/bin/env python

import csv
import gzip
import sys

from collections import Counter


sample = "$sample"
hits_file = "$hits"
results_file = sample + "_summary.txt"

gzopen = lambda f: gzip.open(f, "rt") if f.endswith(".gz") else open(f)
levels = ["superkingdom", "phylum", "class", "order", "family", "genus", "species"]
# required = ["prokka_gene", "prokka_EC_number", "prokka_product", "swissprot_gene", "swissprot_EC_number", "swissprot_product"]
required = ["prokka_gene", "prokka_EC_number", "prokka_product"]

summaries = Counter()

def standard_database(observed, expected):
    for e in expected:
        if e not in observed:
            return False
    return True

with gzopen(hits_file) as in_fh, open(results_file, "w") as out_fh:
    reader = csv.DictReader(in_fh, delimiter="\\t")

    if not standard_database(reader.fieldnames, required):
        print("custom databases without the expected columns are not supported in the summary function", file=out_fh)
        sys.exit(0)

    for i, row in enumerate(reader):
        if row["status"] == "U":
            continue
        for assignment, level in zip(row["taxonomic_lineage"].split(";"), levels):
            if assignment.strip() == "NA":
                continue
            summaries.update([level])

        if (
            row["prokka_gene"]
            or row["prokka_EC_number"]
            or row["prokka_product"]
            #or row["swissprot_gene"]
            #or row["swissprot_EC_number"]
            #or row["swissprot_product"]
        ):
            summaries.update(["function"])
            hypothetical = False
            for assignment in [
                row["prokka_gene"],
                row["prokka_EC_number"],
                row["prokka_product"],
                #row["swissprot_gene"],
                #row["swissprot_EC_number"],
                #row["swissprot_product"],
            ]:
                if "hypothetical" in assignment:
                    hypothetical = True
            if not hypothetical:
                summaries.update(["nonhypothetical"])

        if row["prokka_EC_number"]:# or row["swissprot_EC_number"]:
            summaries.update(["ec"])

    print("Sequences: ", i, file=out_fh)
    i = i / 100.0
    print("Taxonomy assignments", file=out_fh)
    print(
        " Superkingdom:",
        summaries["superkingdom"],
        "(%.2f%%)" % (summaries["superkingdom"] / i),
        file=out_fh,
    )
    print(
        " Phylum:",
        summaries["phylum"],
        "(%.2f%%)" % (summaries["phylum"] / i),
        file=out_fh,
    )
    print(
        " Class:",
        summaries["class"],
        "(%.2f%%)" % (summaries["class"] / i),
        file=out_fh,
    )
    print(
        " Order:",
        summaries["order"],
        "(%.2f%%)" % (summaries["order"] / i),
        file=out_fh,
    )
    print(
        " Family:",
        summaries["family"],
        "(%.2f%%)" % (summaries["family"] / i),
        file=out_fh,
    )
    print(
        " Genus:",
        summaries["genus"],
        "(%.2f%%)" % (summaries["genus"] / i),
        file=out_fh,
    )
    print(
        " Species:",
        summaries["species"],
        "(%.2f%%)" % (summaries["species"] / i),
        file=out_fh,
    )
    print("Functional assignments", file=out_fh)
    print(
        " Function:",
        summaries["function"],
        "(%.2f%%)" % (summaries["function"] / i),
        file=out_fh,
    )
    print(
        " Non-hypothetical:",
        summaries["nonhypothetical"],
        "(%.2f%%)" % (summaries["nonhypothetical"] / i),
        file=out_fh,
    )
    print(" EC:", summaries["ec"], "(%.2f%%)" % (summaries["ec"] / i), file=out_fh)
