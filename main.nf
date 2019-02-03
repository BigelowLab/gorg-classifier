#!/usr/bin/env nextflow
/*
========================================================================================
Bigelow Laboratory - GORG Classifier
========================================================================================

 #### Homepage / Documentation
 https://github.com/BigelowLab/gorg-classifier
 #### Authors
 Joe Brown <brwnjm@gmail.com>
----------------------------------------------------------------------------------------
*/

// required arguments
params.seqs = false
if( !params.seqs ) { exit 1, "--seqs is not defined" }
params.nodes = false
if( !params.nodes ) { exit 1, "--nodes is not defined" }
params.names = false
if( !params.names ) { exit 1, "--names is not defined" }
params.kaiju_index = false
if( !params.kaiju_index ) { exit 1, "--kaiju_index is not defined" }
params.gorg_annotations = false
if( !params.gorg_annotations ) { exit 1, "--gorg_annotations is not defined" }


log.info("\n")
log.info("==========================================")
log.info("GORG Classifier, Single Cell Genome Center")
log.info("==========================================")
log.info("\n")
log.info("Sequences          (*.fq/*.fna)   : ${params.seqs}")
log.info("Nodes              (nodes.dmp)    : ${params.nodes}")
log.info("Names              (names.dmp)    : ${params.names}")
log.info("Kaiju Index        (.fmi)         : ${params.kaiju_index}")
log.info("GORG Annotations   (.tsv)         : ${params.gorg_annotations}")
log.info("Output directory                  : ${params.outdir}")
log.info("Kaiju mismatches                  : ${params.kaiju_mismatches}")
log.info("Kaiju minimum alignment length    : ${params.kaiju_min_length}")
log.info("\n")

// instantiate files
nodes = file(params.nodes)
names = file(params.names)
kaiju_index = file(params.kaiju_index)
gorg_annotations = file(params.gorg_annotations)

// check file existence
if( !nodes.exists() ) { exit 1, "Missing taxonomy nodes: ${nodes}" }
if( !names.exists() ) { exit 1, "Missing taxonomy names: ${names}" }
if( !kaiju_index.exists() ) { exit 1, "Missing kaiju index: ${kaiju_index}" }
if( !gorg_annotations.exists() ) { exit 1, "Missing GORG annotations: ${gorg_annotations}" }


Channel
    .fromPath(params.seqs, checkIfExists: true)
    .map { file -> tuple(file.baseName.split("\\.")[0], file) }
    .set { sequence_files }

process run_kaiju {
    tag "$sample"
    publishDir "${params.outdir}/kaiju", mode: 'copy'
    cpus params.cpus
    memory 16.GB

    input:
    set sample, file(sequences) from sequence_files
    file nodes
    file kaiju_index

    output:
    set sample, file("${sample}_hits.txt") into kaiju_hits

    script:
    """
    kaiju -z ${task.cpus} -v -m ${params.kaiju_min_length} -e ${params.kaiju_mismatches} -t $nodes -f $kaiju_index -i $sequences -o ${sample}_hits.txt
    """
}

process add_taxonomy {
    tag "$sample"
    publishDir path: "${params.outdir}/kaiju", mode: "copy"

    input:
    set sample, file(hits) from kaiju_hits
    file nodes
    file names

    output:
    set sample, file("${sample}_hits_names.txt") into assigned_taxonomies

    script:
    """
    addTaxonNames -t $nodes -n $names -i $hits -o ${sample}_hits_names.txt -r superkingdom,phylum,class,order,family,genus,species
    """
}

process add_functions {
    tag "$sample"
    publishDir path: "${params.outdir}/annotations", mode: "copy"

    input:
    set sample, file(hits) from assigned_taxonomies
    file gorg_annotations

    output:
    set sample, file("${sample}_annotated.txt.gz") into assigned_functions

    script:
    """
    awk 'BEGIN{{FS=IFS=OFS="\t"}} NR==FNR {{a[\$1";"\$5";"\$6]=\$8 FS \$11 FS \$9 FS \$12 FS \$10 FS \$13 FS \$14 FS \$15 FS \$16 FS \$17 FS \$18;next}}{{split(\$6, contigs, ","); print \$0 FS a[contigs[1]] }}' $gorg_annotations $hits | gzip > ${sample}_annotated.txt.gz
    """
}

process summarize_annotations {
    tag "$sample"
    publishDir path: "${params.outdir}/summaries", mode: "copy"

    input:
    set sample, file(hits) from assigned_functions

    output:
    file("${sample}_summary.txt")

    script:
    template 'summarize_annotations.py'
}
