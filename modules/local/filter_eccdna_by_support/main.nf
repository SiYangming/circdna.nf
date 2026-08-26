process FILTER_ECCDNA_BY_SUPPORT {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(input_file)
    val min_support

    output:
    tuple val(meta), path("${meta.id}.filtered.${input_file.getExtension()}"), emit: filtered
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ext = input_file.getExtension() ?: 'txt'
    def bin_script = "filter_by_read_support.py"
    """
    python ${bin_script} \\
        ${input_file} \\
        ${meta.id}.filtered.${ext} \\
        --min_support ${min_support}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    def ext = input_file.getExtension() ?: 'txt'
    """
    cp ${input_file} ${meta.id}.filtered.${ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "stub"
    END_VERSIONS
    """
}
