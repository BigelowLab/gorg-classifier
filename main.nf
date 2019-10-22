#!/usr/bin/env nextflow

params.help = false
if (params.help) {
    log.info """
    =======================================================================
    GORG Classifier, Single Cell Genome Center, Bigelow Laboratory
    =======================================================================

    #### Homepage / Documentation
    https://github.com/BigelowLab/gorg-classifier
    #### Authors
    Joe Brown <brwnjm@gmail.com>
    -----------------------------------------------------------------------

    Required arguments

    --seqs
        File path with wildcard(s) of your sequence files,
        e.g. "/data/*.fastq.gz"
    --nodes
        File path to nodes.dmp
    --names
        File path to names.dmp
    --kaiju_index
        File path to kaiju index (ends with .fmi)
    --annotations
        File path to GORG functional annotations (ends with .tsv)

    Optional parameters

    --outdir
        Directory, existing or not, into which the output is written
        Default: './results'
    --cpus
        CPUs allocated to `kaiju`
        Default: 8
    --kaiju_mismatches
        The number of mismatches allowed in a kaiju alignment
        Default: 3
    --kaiju_min_length
        The minimum alignment length threshold for kaiju alignments
        Default: 11

    -----------------------------------------------------------------------
    """.stripIndent()
    exit 0
}

// required arguments
params.seqs = false
if( !params.seqs ) { exit 1, "--seqs is not defined" }
params.nodes = false
if( !params.nodes ) { exit 1, "--nodes is not defined" }
params.names = false
if( !params.names ) { exit 1, "--names is not defined" }
params.kaiju_index = false
if( !params.kaiju_index ) { exit 1, "--kaiju_index is not defined" }
params.annotations = false
if( !params.annotations ) { exit 1, "--annotations is not defined" }

log.info """

    =======================================================================
    GORG Classifier, Single Cell Genome Center, Bigelow Laboratory
    =======================================================================

    #### Homepage / Documentation
    https://github.com/BigelowLab/gorg-classifier
    #### Authors
    Joe Brown <brwnjm@gmail.com>
    -----------------------------------------------------------------------

    Sequences          (*.fq/*.fna)   : ${params.seqs}
    Nodes              (nodes.dmp)    : ${params.nodes}
    Names              (names.dmp)    : ${params.names}
    Kaiju Index        (.fmi)         : ${params.kaiju_index}
    GORG Annotations   (.tsv)         : ${params.annotations}
    Output directory                  : ${params.outdir}
    Kaiju mismatches                  : ${params.kaiju_mismatches}
    Kaiju minimum alignment length    : ${params.kaiju_min_length}
    Kaiju CPUs                        : ${params.cpus}
    """.stripIndent()

// instantiate files
nodes = file(params.nodes)
names = file(params.names)
kaiju_index = file(params.kaiju_index)
annotations = file(params.annotations)

// check file existence
if( !nodes.exists() ) { exit 1, "Missing taxonomy nodes: ${nodes}" }
if( !names.exists() ) { exit 1, "Missing taxonomy names: ${names}" }
if( !kaiju_index.exists() ) { exit 1, "Missing kaiju index: ${kaiju_index}" }
if( !annotations.exists() ) { exit 1, "Missing GORG annotations: ${annotations}" }


Channel
    .fromPath(params.seqs, checkIfExists: true)
    .map { file -> tuple(file.baseName.split("\\.")[0], file) }
    .set { sequence_files }


process run_kaiju {
    tag "$sample"
    cpus params.cpus

    input:
    set sample, file(sequences) from sequence_files
    file nodes
    file kaiju_index

    output:
    set sample, file("${sample}_hits.txt") into kaiju_hits

    script:
    """
    kaiju -z ${task.cpus} -v -m ${params.kaiju_min_length} \
        -e ${params.kaiju_mismatches} -t $nodes -f $kaiju_index \
        -i $sequences -o ${sample}_hits.txt
    """
}


process add_taxonomy {
    tag "$sample"

    input:
    set sample, file(hits) from kaiju_hits
    file nodes
    file names

    output:
    set sample, file("${sample}_hits_names.txt") into assigned_taxonomies

    script:
    """
    addTaxonNames -t $nodes -n $names -i $hits -o ${sample}_hits_names.txt \
        -r superkingdom,phylum,class,order,family,genus,species
    """
}

process add_functions {
    tag "$sample"
    publishDir path: "${params.outdir}/annotations"

    input:
    set sample, file(hits) from assigned_taxonomies
    file annotations

    output:
    set sample, file("${sample}_annotated.txt.gz") into assigned_functions

    script:
    """
    awk 'BEGIN{{FS=IFS=OFS="\t"}} NR==FNR {{a[\$1";"\$5";"\$6]=\$8 FS \$11 FS \$9 FS \$12 FS \$10 FS \$13 FS \$14 FS \$15 FS \$16 FS \$17 FS \$18;next}}{{split(\$6, contigs, ","); print \$0 FS a[contigs[1]] }}' $annotations $hits | gzip > ${sample}_annotated.txt.gz
    """
}

process summarize_annotations {
    tag "$sample"
    publishDir path: "${params.outdir}/summaries"

    input:
    set sample, file(hits) from assigned_functions

    output:
    file("${sample}_summary.txt")

    script:
    template 'summarize_annotations.py'
}
