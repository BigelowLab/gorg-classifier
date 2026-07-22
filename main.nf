nextflow.enable.dsl=2

params.help = false
if (params.help) {
    log.info """
    =======================================================================
    GORG Classifier, Single Cell Genome Center, Bigelow Laboratory
    =======================================================================

    #### Homepage / Documentation
    https://github.com/BigelowLab/gorg-classifier
    #### Citation
    https://doi.org/10.1016/j.cell.2019.11.017
    #### Reference data
    URL: https://osf.io/pcwj9
    License: Attribution-NonCommercial 4.0 International.
    #### Authors
    Joe Brown <brwnjm@gmail.com>
    Julia Brown <julia@bigelow.org>
    -----------------------------------------------------------------------

    Required arguments

    --seqs
        File path with wildcard(s) of your sequence files,
        e.g. "/data/*.fastq.gz"

    Optional parameters

    --mode
        One of 'ncbi', 'crest', or 'local'. Downloads references
        and annotates using respective reference files
        Default: 'ncbi'
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

    Local mode

    --nodes
        File path to nodes.dmp
    --names
        File path to names.dmp
    --fmi
        File path to kaiju index (ends with .fmi)
    --annotations
        File path to GORG functional annotations (ends with .tsv)

    -----------------------------------------------------------------------
    """.stripIndent()
    exit 0
}

// required arguments
params.seqs = false
// local mode
params.nodes = false
params.annotations = false
params.names = false
params.fmi = false

if (!params.seqs) { exit 1, "--seqs is not defined" }
if (params.mode == "local") {
    if (!params.nodes) { exit 1, "--nodes is not defined" }
    if (!params.names) { exit 1, "--names is not defined" }
    if (!params.fmi) { exit 1, "--fmi is not defined" }
    if (!params.annotations) { exit 1, "--annotations is not defined" }

    nodes = file(params.nodes)
    names = file(params.names)
    fmi = file(params.fmi)
    annotations = file(params.annotations)

    // check file existence
    if( !nodes.exists() ) { exit 1, "Missing taxonomy nodes: ${nodes}" }
    if( !names.exists() ) { exit 1, "Missing taxonomy names: ${names}" }
    if( !fmi.exists() ) { exit 1, "Missing kaiju index: ${fmi}" }
    if( !annotations.exists() ) { exit 1, "Missing GORG annotations: ${annotations}" }
}
else if(params.mode == "ncbi") {
    // future file versioning will look like: ?action=download&amp;version=1&amp;direct
    fmi = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12d0946b571000d064725")
    annotations = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12a440db187000e3afd8a")
    names = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12d3146b571000b0663af")
    nodes = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12d3446b571000d06473b")

}
else if(params.mode == "crest") {
    fmi = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12c74743c23000c9ed206")
    annotations = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12a440db187000e3afd8a")
    names = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12d0c743c23000a9ee2bf")
    nodes = file("https://files.osf.io/v1/resources/pcwj9/providers/osfstorage/5db12d0b46b571000e06e7a8")
} else {
    exit 1, "--mode must be one of 'ncbi', 'crest', or 'local'"
}

log.info """

    =======================================================================
    GORG Classifier, Single Cell Genome Center, Bigelow Laboratory
    =======================================================================

    #### Homepage / Documentation
    https://github.com/BigelowLab/gorg-classifier
    #### Citation
    https://doi.org/10.1016/j.cell.2019.11.017
    #### Reference data
    URL: https://osf.io/pcwj9
    License: Attribution-NonCommercial 4.0 International.
    #### Authors
    Joe Brown <brwnjm@gmail.com>
    -----------------------------------------------------------------------

    Sequences          (*.fq/*.fna)   : ${params.seqs}
    Mode                              : ${params.mode}
    Nodes              (nodes.dmp)    : ${nodes}
    Names              (names.dmp)    : ${names}
    Kaiju Index        (.fmi)         : ${fmi}
    GORG Annotations   (.tsv)         : ${annotations}
    Output directory                  : ${params.outdir}
    Kaiju mismatches                  : ${params.mismatches}
    Kaiju minimum alignment length    : ${params.minlength}
    Kaiju CPUs                        : ${params.cpus}
    -----------------------------------------------------------------------

    """.stripIndent()


process run_kaiju {
    tag "$sample"
    cpus params.cpus
    publishDir path: "${params.outdir}/kaiju"

    input:
    tuple val(sample), path(r1), path(r2)
    path(nodes)
    path(fmi)

    output:
    tuple val(sample), path("${sample}_hits.txt")

    script:
    def r2path = r2 ? "-j ${r2}" : ""
    """
    kaiju -z ${task.cpus} -v -m ${params.minlength} \
        -e ${params.mismatches} -t $nodes -f $fmi \
        -i ${r1} ${r2path} -o ${sample}_hits.txt
    """
}


process add_taxonomy {
    tag "$sample"
    publishDir path: "${params.outdir}/kaiju"

    input:
    tuple val(sample), path(hits)
    path(nodes)
    path(names)

    output:
    tuple val(sample), path("${sample}_hits_names.txt.gz")

    script:
    """
    kaiju-addTaxonNames -t ${nodes} -n ${names} -i ${hits} -o ${sample}_hits_names.txt \
        -r superkingdom,phylum,class,order,family,genus,species
    gzip ${sample}_hits_names.txt
    """
}


process add_functions {
    tag "$sample"
    publishDir path: "${params.outdir}/annotations"

    input:
    tuple val(sample), path(hits)
    path(annotations)

    output:
    tuple val(sample), path("${sample}_annotated.txt.gz")

    script:
    template 'add_functions.py'
}

process lineage_counts {
    tag "$sample"
    publishDir path: "${params.outdir}/summaries"
    cache false

    input:
    tuple val(sample), path(hits)

    output:
    path("${sample}_tax_counts.txt")

    script:
    template 'lineage_counts.py'
}

process summarize_annotations {
    tag "$sample"
    publishDir path: "${params.outdir}/summaries"

    input:
    tuple val(sample), path(hits)

    output:
    path("${sample}_summary.txt")

    script:
    template 'summarize_annotations.py'
}


workflow {
    seqs = Channel
        .fromFilePairs(params.seqs, size: -1, checkIfExists: true, flat: true)
        .map { it ->
            if (it.size == 2) {
                it.add([])
            }
            return it
        }
    run_kaiju(seqs, nodes, fmi)
    add_taxonomy(run_kaiju.out, nodes, names)
    add_functions(add_taxonomy.out, annotations)
    lineage_counts(add_functions.out) 
    summarize_annotations(add_functions.out)
}
