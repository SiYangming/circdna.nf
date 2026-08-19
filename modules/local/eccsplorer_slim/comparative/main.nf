process ECCSPLORER_COMPARATIVE {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.17.0--d4fb881691596759' :
        'community.wave.seqera.io/library/blast:2.17.0--d4fb881691596759' }"

    input:
    tuple val(meta), path(map_cand_fa)     // mapper candidate sequences (ECC-SEQUENCES.fasta)
    tuple val(meta2), path(cluster_contigs) // cluster contig fastas (per-cluster)
    tuple val(meta3), path(norm_csv)       // region-coverages normalized csv

    output:
    tuple val(meta), path("${prefix}_comparative-blast.m6"), emit: blast_m6
    tuple val(meta), path("${prefix}_comparative_scatter.png"), emit: scatter
    tuple val(meta), path("${prefix}_eccComp_summary.html"), emit: html
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # 1) makeblastdb from mapper candidates
    makeblastdb -in ${map_cand_fa} -dbtype nucl -out ${prefix}_mapperdb -title mapperdb $args

    # 2) blast each cluster contig vs mapper candidates (replicates eccComparer blast_cand)
    : > ${prefix}_comparative-blast.m6
    for f in ${cluster_contigs}; do
        cl=\$(basename \$f .fa | sed 's/.*CL//')
        blastn -query \$f -db ${prefix}_mapperdb \\
            -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen" \\
            -max_hsps 25 >> ${prefix}_comparative-blast.m6 2>/dev/null || true
    done

    # 3) scatter plot (cluster size TR vs CO from norm csv cols)
    python <<PYEOF
    import sys
    import pandas as pd
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    df = pd.read_csv('${norm_csv}', sep='\t')
    fig, ax = plt.subplots(figsize=(8, 6))
    if not df.empty:
        tr = pd.to_numeric(df.iloc[:, 4], errors='coerce').fillna(0)
        co = pd.to_numeric(df.iloc[:, 6] if df.shape[1] >= 7 else df.iloc[:, 4], errors='coerce').fillna(0)
        ax.scatter(co + 1, tr + 1, alpha=0.6, s=20)
        ax.set_xscale('log'); ax.set_yscale('log')
        ax.set_xlabel('CO cluster size + 1'); ax.set_ylabel('TR cluster size + 1')
        ax.set_title('Comparative cluster scatter')
    else:
        ax.text(0.5, 0.5, 'no candidates', ha='center', va='center')
    fig.tight_layout(); fig.savefig('${prefix}_comparative_scatter.png', dpi=150)
    PYEOF

    # 4) HTML summary
    python <<PYEOF
    import os
    hits = 0
    if os.path.isfile('${prefix}_comparative-blast.m6'):
        hits = sum(1 for _ in open('${prefix}_comparative-blast.m6') if _.strip())
    with open('${prefix}_eccComp_summary.html', 'w') as f:
        f.write(f'<html><body><h1>eccComp summary</h1><p>mapped blast hits: {hits}</p>'
                f'<img src="${prefix}_comparative_scatter.png" style="max-width:700px"></body></html>')
    PYEOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: 2.17.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_comparative-blast.m6
    touch ${prefix}_comparative_scatter.png
    touch ${prefix}_eccComp_summary.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: 2.17.0
    END_VERSIONS
    """
}
