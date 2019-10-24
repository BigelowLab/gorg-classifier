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
    --fmi
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
    --mismatches
        The number of mismatches allowed in a kaiju alignment
        Default: 3
    --minlength
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
params.fmi = false
if( !params.fmi ) { exit 1, "--fmi is not defined" }
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
    Kaiju Index        (.fmi)         : ${params.fmi}
    GORG Annotations   (.tsv)         : ${params.annotations}
    Output directory                  : ${params.outdir}
    Kaiju mismatches                  : ${params.mismatches}
    Kaiju minimum alignment length    : ${params.minlength}
    Kaiju CPUs                        : ${params.cpus}
    -----------------------------------------------------------------------

    """.stripIndent()

// instantiate files
nodes = file(params.nodes)
names = file(params.names)
fmi = file(params.fmi)
annotations = file(params.annotations)

// check file existence
if( !nodes.exists() ) { exit 1, "Missing taxonomy nodes: ${nodes}" }
if( !names.exists() ) { exit 1, "Missing taxonomy names: ${names}" }
if( !fmi.exists() ) { exit 1, "Missing kaiju index: ${fmi}" }
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
    file fmi

    output:
    set sample, file("${sample}_hits.txt") into kaiju_hits

    script:
    """
    kaiju -z ${task.cpus} -v -m ${params.minlength} \
        -e ${params.mismatches} -t $nodes -f $fmi \
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
    set sample, file("${sample}_hits_names.txt.gz") into assigned_taxonomies

    script:
    """
    kaiju-addTaxonNames -t $nodes -n $names -i $hits -o ${sample}_hits_names.txt \
        -r superkingdom,phylum,class,order,family,genus,species
    gzip ${sample}_hits_names.txt
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
    template 'add_functions.py'
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
