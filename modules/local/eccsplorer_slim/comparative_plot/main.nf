process ECCSPLORER_COMPARATIVE_PLOT {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eccsplorer_slim:1.0.0--0' :
        'quay.io/bioinfortools/eccsplorer_slim:1.0.0' }"

    input:
    tuple val(meta), path(blast_m6)
    tuple val(meta2), path(norm_csv)

    output:
    tuple val(meta), path("${prefix}_comparative_scatter.png"), emit: scatter
    tuple val(meta), path("${prefix}_eccComp_summary.html"), emit: html
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    python <<PYEOF
    import os
    import pandas as pd
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    # scatter (cluster TR vs CO sizes from norm csv)
    fig, ax = plt.subplots(figsize=(8, 6))
    try:
        df = pd.read_csv('${norm_csv}', sep='\t')
        if not df.empty:
            tr = pd.to_numeric(df.iloc[:, 4], errors='coerce').fillna(0)
            co = pd.to_numeric(df.iloc[:, 6] if df.shape[1] >= 7 else df.iloc[:, 4], errors='coerce').fillna(0)
            ax.scatter(co + 1, tr + 1, alpha=0.6, s=20)
            ax.set_xscale('log'); ax.set_yscale('log')
            ax.set_xlabel('CO cluster size + 1'); ax.set_ylabel('TR cluster size + 1')
            ax.set_title('Comparative cluster scatter')
        else:
            ax.text(0.5, 0.5, 'no candidates', ha='center', va='center')
    except Exception as e:
        ax.text(0.5, 0.5, 'no data', ha='center', va='center')
    fig.tight_layout(); fig.savefig('${prefix}_comparative_scatter.png', dpi=150)

    # HTML summary
    hits = 0
    if os.path.isfile('${blast_m6}'):
        hits = sum(1 for _ in open('${blast_m6}') if _.strip())
    with open('${prefix}_eccComp_summary.html', 'w') as f:
        f.write(f'<html><body><h1>eccComp summary</h1><p>cluster-candidate blast hits: {hits}</p>'
                f'<img src="${prefix}_comparative_scatter.png" style="max-width:700px"></body></html>')
    PYEOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_comparative_scatter.png
    touch ${prefix}_eccComp_summary.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eccsplorer_slim: 1.0.0
    END_VERSIONS
    """
}
