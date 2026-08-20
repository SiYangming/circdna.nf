process REPEATEXPLORER2 {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] ?
        'docker://docker.1ms.run/kavonrtep/repeatexplorer:2.3.8' :
        'docker.1ms.run/kavonrtep/repeatexplorer:2.3.8' }"

    input:
    tuple val(meta), path(reads_fa)
    val(taxon)

    output:
    tuple val(meta), path("seqclust/"), emit: clu_dir
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def taxon_map = taxon == 'met' ? 'METAZOA3.0' : 'VIRIDIPLANTAE3.0'
    def prefix_length = task.ext.prefix_length ?: (params.eccsplorer_clu_prefix_length ?: 2)
    """
    # --- conda/docker 统一适配（幂等） ---
    # ① 命令定位：docker 镜像内补 PATH，两种模式统一用 "seqclust"
    [ -x /repex_tarean/seqclust ] && export PATH=/repex_tarean:\$PATH
    which seqclust >/dev/null 2>&1 || { echo "seqclust not found"; exit 1; }
    # ② databases：conda wrapper 按 REPEX_DATABASES 软链；docker 镜像内置
    export REPEX_DATABASES="${params.repex_databases}"
    # ③ Rserve 竞态 patch（幂等）：conda build 2 已固化自动跳过；docker 运行时打一次
    for r2py in /repex_tarean/lib/r2py.py "\${CONDA_PREFIX:-}/repeatexplorer/lib/r2py.py"; do
        [ -f "\$r2py" ] && python ${moduleDir}/bin/patch_r2py.py "\$r2py"
    done
    # ④ 输入下限校验（seqclust 要求 >=1000 条）
    NSEQ=\$(grep -c '^>' ${reads_fa})
    if [ "\$NSEQ" -lt 1000 ]; then
        echo "ERROR: seqclust requires >=1000 sequences, got \$NSEQ" >&2
        exit 1
    fi

    # --- RepeatExplorer2 (seqclust) clustering ---
    seqclust \\
        --paired \\
        --prefix_length ${prefix_length} \\
        --output_dir seqclust \\
        --taxon ${taxon_map} \\
        --cpu ${task.cpus} \\
        ${reads_fa} \\
        --cleanup --keep_names --options ILLUMINA \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatexplorer: 2.3.8
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p seqclust
    touch seqclust/CLUSTER_TABLE.csv
    touch seqclust/COMPARATIVE_ANALYSIS_COUNTS.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatexplorer: 2.3.8
    END_VERSIONS
    """
}
