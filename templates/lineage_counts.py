#!/usr/bin/env python3

import gzip
import csv
from collections import defaultdict

# Read sample name and input file path from Nextflow variables
sample = "$sample"
hits_file = "$hits"
output_file = f"{sample}_tax_counts.txt"


lineage_levels = ['Superkingdom', 'Phylum', 'Class', 'Order',
                  'Family', 'Genus', 'Species']
level_index_map = {lvl: i for i, lvl in enumerate(lineage_levels)}

def parse_lineage(lineage_str, level_idx):
    """Return full lineage up to the given level."""
    parts = lineage_str.replace(" ", "").split(";")
    if not parts or level_idx >= len(parts):
        return "Unclassified"
    return ";".join(parts[:level_idx + 1])

def process_file(file_path):
    lldict = {lvl: defaultdict(int) for lvl in lineage_levels}
    with gzip.open(file_path, 'rt') as f:
        reader = csv.DictReader(f, delimiter='\\t')
        for row in reader:
            if row['status'] != 'C':
                continue
            lineage = row['taxonomic_lineage']
            for lvl in lineage_levels:
                idx = level_index_map[lvl]
                taxon = parse_lineage(lineage, idx)
                lldict[lvl][taxon] += 1
    return lldict

def write_lldict_to_tsv(lldict, sample_id, outfile):
    with open(outfile, 'w') as out:
        out.write("sample_id\\tlineage_level\\ttaxon\\tcount\\n")
        for level, tax_counts in lldict.items():
            for taxon, count in tax_counts.items():
                out.write(f"{sample_id}\\t{level}\\t{taxon}\\t{count}\\n")

lldict = process_file(hits_file)
write_lldict_to_tsv(lldict, sample, output_file)
