# GORG Classifier

## Citation

> Pachiadaki, M. G., Brown, J. M., Brown, J., Bezuidt, O., Berube, P. M., Biller, S. J., Poulton, N. J., Burkart, M. D., Clair, J. J. L., Chisholm, S. W., et al. (2019). Charting the Complexity of the Marine Microbiome through Single-Cell Genomics. Cell. https://doi.org/10.1016/j.cell.2019.11.017

# Usage

Install [Nextflow](https://www.nextflow.io/):

```
curl -s https://get.nextflow.io | bash
```

Annotate with GORG NCBI taxonomy using Docker to handle dependencies:

```
nextflow run BigelowLab/gorg-classifier -profile docker \
    --seqs '/data/*.fastq'
```

Or Singularity:

```
nextflow run BigelowLab/gorg-classifier -profile singularity \
    --seqs '/data/*.fastq'
```


Altering `--mode` you can use our CREST annotated taxonomy.

## Required arguments

+ `--seqs`
    + File path with wildcard(s) of your sequence files, e.g. "/data/*.fastq.gz"

## Paired-end data

The pattern above ("/data/*.fastq.gz") works on single-end data and will treat
pair-end data as single end. For paired-end mode use a pattern such as:

```
--seqs "/data/*_{1,2}.fastq.gz"
```

## Optional parameters

+ `--outdir`
    + Directory, existing or not, into which the output is written
    + Defaults to './results'
+ `--cpus`
    + CPUs allocated to `kaiju`
    + Defaults to 8
+ `--mismatches`
    + The number of mismatches allowed in a kaiju alignment
    + Defaults to 3
+ `--minlength`
    + The minimum alignment length threshold for kaiju alignments
    + Defaults to 11

## Reference data

GORG reference materials can be downloaded from our OSF repo under Files/OSF Storage/gorg-tropics.

URL: https://osf.io/pcwj9/files/

The references are released under Attribution-NonCommercial 4.0 International.

## Local mode

If your compute environment lacks an internet connection, you may specify local
downloads for reference data after setting `--mode local`. See `--help` for more
details.

+ `--nodes`
    + File path to nodes.dmp
+ `--names`
    + File path to names.dmp
+ `--fmi`
    + File path to kaiju index (ends with .fmi)
+ `--annotations`
    + File path to GORG functional annotations (ends with .tsv)

The index, `GORG_v1_NCBI.fmi` or `GORG_v1_CREST.fmi`, must be paired with their respective
taxonomy metadata files (`names.dmp` and `nodes.dmp`) included with the reference data.

## Outputs

The final annotated sequences are available in `./results/annotations/${sample}_annotated.txt.gz`.
Column headers are added onto the annotations file.

Per sample summary data is collected in `.results/summaries/${sample}_summary.txt` and contains
a breakdown of counts per taxonomy and number of functional assignments.


# Updating the reference

We use Prokka to annotate contigs as it gives us reasonable annotations, an
faa, and a gff. From there we use AA sequences and design the header to
contain the contig ID, the start, and end of the AA within the context of
the contig. This is used to link kaiju alignments to the remainder of the
AA annotation.

The header's final detail is the lowest taxonomic identifier which
corresponds to a given taxonomy, e.g. SILVAmod (CREST) or NCBI.

The final result for an entry within the faa is:

```
>AG-313-D02_NODE_48;2006;2149_62672
MQLKHPLGKELLFIISIRIRLLRDEYSLGFKTIEQPAAIAEDIFVRV
```

Breaking down `>AG-313-D02_NODE_48;2006;2149_62672` gives us:

```
AG-313-D02_NODE_48 <- the contig ID
2006               <- start
2149               <- end
62672              <- most specific taxonomic assignment
```

After you update your headers, append them onto the GORG .faa and
create your kaiju index using tools available in the kaiju toolset.
For NCBI's taxonomy, this would look like:

```
$ mkbwt -n 8 -a protein -o GORG_v1_NCBI_custom GORG_v1_NCBI_custom.faa
$ mkfmi -r rm GORG_v1_NCBI_custom
```

The final piece is appending your functional annotations onto GORG_v1.tsv.
Matching to Kaiju hits is done using contig_id, start, and stop. Empty cells
are okay, but extra columns would be cut off.

Example of the GORG_v1.tsv:

```
contig_id	sag	ncbi_id	crest_id	start	stop	strand	prokka_gene	prokka_EC_number	prokka_product	swissprot_geneswissprot_EC_number	swissprot_product	swissprot_eggNOG	swissprot_KO	swissprot_Pfam	swissprot_CAZy	swissprot_TIGRFAMs
AG-313-D02_NODE_48	AG-313-D02	62672	2547	2006	2149	-			hypothetical protein			hypothetical protein
```

Now using your index, the taxonomic annotations, and your functional
annotations, run the classifier against your sequences:

```
$ nextflow run BigelowLab/gorg-classifier \
    -latest -profile docker \
    --seqs 'data/*.fq' \
    --nodes NCBI/nodes.dmp \
    --names NCBI/names.dmp \
    --fmi GORG_v1_NCBI_custom.fmi \
    --annotations GORG_v1_custom.tsv
```
