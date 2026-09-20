process FILTER_ECCDNA_BY_SUPPORT {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(input_file)
    val min_support

    output:
    // 前缀可经 task.ext.prefix 覆盖：多个长读引擎的 filtered 文件发布到同一目录，
    // 统一用 ${meta.id} 会互相覆盖，只留下最后一个引擎的产物。
    def ext = input_file.getExtension() ?: 'txt'
    def prefix = task.ext.prefix ?: "${meta.id}"
    tuple val(meta), path("${prefix}.filtered.${ext}"), emit: filtered
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ext = input_file.getExtension() ?: 'txt'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bin_script = "filter_by_read_support.py"
    """
    ${bin_script} \\
        ${input_file} \\
        ${prefix}.filtered.${ext} \\
        --min_support ${min_support}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/^.* //')
    END_VERSIONS
    """

    stub:
    def ext = input_file.getExtension() ?: 'txt'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp ${input_file} ${prefix}.filtered.${ext}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "stub"
    END_VERSIONS
    """
}
