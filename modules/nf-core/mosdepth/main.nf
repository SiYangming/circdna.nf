process MOSDEPTH {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}/reference_mode/mosdepth", mode:'copy', enabled:true

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/xx/mosdepth/data'
        : 'quay.io/biocontainers/mosdepth:0.3.14--h05c3d44_1'}"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fai)

    output:
    tuple val(meta), path("*.regions.bed.gz"), emit: regions_bed
    tuple val(meta), path("*.regions.bed.gz.csi"), emit: regions_bed_csi
    tuple val(meta), path("*.global.dist.txt"), emit: global_dist
    tuple val(meta), path("*.summary.txt"), emit: summary
    tuple val("${task.process}"), val('mosdepth'), eval("mosdepth --version 2>&1 | sed 's/.* //'"), emit: versions_mosdepth, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: '--fast-mode'
    """
    mosdepth \\
        --threads ${task.cpus} \\
        ${args} \\
        ${prefix} \\
        ${bam}

    echo \$(mosdepth --version 2>&1 | sed 's/.* //') > version.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.regions.bed.gz
    touch ${prefix}.regions.bed.gz.csi
    touch ${prefix}.global.dist.txt
    echo -e "total\t1000000\t1000000\t30.0" > ${prefix}.summary.txt
    echo "0.3.8" > version.txt
    """
}
