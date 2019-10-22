# GORG Classifier

# Usage

## Required arguments

+ `--seqs`
    + File path with wildcard(s) of your sequence files, e.g. "/data/*.fastq.gz"
+ `--nodes`
    + File path to nodes.dmp
+ `--names`
    + File path to names.dmp
+ `--kaiju_index`
    + File path to kaiju index (ends with .fmi)
+ `--annotations`
    + File path to GORG functional annotations (ends with .tsv)

## Optional parameters

+ `--outdir`
    + Directory, existing or not, into which the output is written
    + Defaults to './results'
+ `--cpus`
    + CPUs allocated to `kaiju`
    + Defaults to 8
+ `--kaiju_mismatches`
    + The number of mismatches allowed in a kaiju alignment
    + Defaults to 3
+ `--kaiju_min_length`
    + The minimum alignment length threshold for kaiju alignments
    + Defaults to 11

## Example

Install Nextflow

```
curl -s https://get.nextflow.io | bash
```

With Docker or Singularity:

```
nextflow run BigelowLab/gorg-classifier -latest -profile docker \
    --seqs '/data/*.fastq' \
    --nodes /GORG/NCBI/nodes.dmp \
    --names /GORG/NCBI/names.dmp \
    --kaiju_index /GORG/GORG_v1_NCBI.fmi \
    --annotations /GORG/GORG_v1.tsv
```

With dependencies (kaiju, awk, and python) installed locally:

```
nextflow run BigelowLab/gorg-classifier -latest \
    --seqs '/data/*.fastq' \
    --nodes /GORG/NCBI/nodes.dmp \
    --names /GORG/NCBI/names.dmp \
    --kaiju_index /GORG/GORG_v1_NCBI.fmi \
    --annotations /GORG/GORG_v1.tsv
```

## Outputs

The final annotated sequences are available in `./results/annotations/${sample}_annotated.txt.gz`. The columns
are defined as:

+ status - classified ("C") or unclassified ("U")
+ sequence ID
+ taxonomy ID
+ length
+ taxonomy IDs used in LCA
+ sequence IDs used in the LCA
+ protein sequence
+ taxonomic lineage
+ prokka gene
+ swissprot gene
+ prokka EC
+ swissprot EC
+ prokka product
+ swissprot product
+ eggNOG
+ KO
+ Pfam
+ CAZy
+ TIGRFAMs
