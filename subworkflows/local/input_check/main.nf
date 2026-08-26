include { SAMPLESHEET_CHECK } from '../../../modules/local/samplesheet_check/main'

workflow INPUT_CHECK {
    take:
    samplesheet

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .set { parsed_samplesheet }

    // 按行 platform 分流（混表允许：同一张表含 Illumina + PacBio + ONT）
    parsed_samplesheet
        .filter { row -> (row.platform ?: 'illumina') == 'illumina' }
        .map { it -> params.input_format == 'BAM' ? create_short_read_bam_channels(it) : create_short_read_fastq_channels(it) }
        .set { reads_short }

    parsed_samplesheet
        .filter { row -> (row.platform ?: '') in ['pacbio', 'ont'] }
        .map { it -> create_long_read_channels(it) }
        .set { reads_long }

    emit:
    reads_short  // channel: [ val(meta), [ reads ] ] OR [ val(meta), bam ]
    reads_long   // channel: [ val(meta), fastq, input_bam, entrypoint ]
    versions     = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

def create_short_read_fastq_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.single_end   = row.containsKey('single_end') ? (row.single_end ? row.single_end.toBoolean() : false) : (!row.fastq_2 || row.fastq_2.isEmpty())
    if (row.containsKey('lane') && row.lane) {
        meta.lane = row.lane
    }
    meta.datatype     = row.containsKey('datatype') ? (row.datatype ? row.datatype : 'eccdna') : 'eccdna'
    // 兼容旧过滤（workflows 曾用 meta.data_type）；统一为小写 datatype
    meta.data_type    = meta.datatype
    meta.platform     = row.containsKey('platform') ? (row.platform ? row.platform : 'illumina') : 'illumina'
    meta.protocol     = row.containsKey('protocol') ? (row.protocol ? row.protocol : 'short_read') : 'short_read'
    // 短读缺省：datatype=gdna→wgs，eccdna→circleseq
    meta.assay        = row.containsKey('assay') && row.assay ? row.assay : (meta.datatype == 'gdna' ? 'wgs' : 'circleseq')
    meta.pair         = (row.containsKey('pair') && row.pair) ? row.pair : ((row.containsKey('group') && row.group) ? row.group : null)
    meta.concatemer   = row.containsKey('concatemer') && row.concatemer ? row.concatemer.toBoolean() : (meta.assay == 'rca')
    meta.read_type    = row.containsKey('read_type') && row.read_type ? row.read_type : (meta.single_end ? 'se' : 'pe')
    meta.enrichment   = row.containsKey('enrichment') && row.enrichment ? row.enrichment : 'none'

    def array = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (meta.single_end) {
        array = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
        }
        array = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return array
}

def create_short_read_bam_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id             = row.sample
    meta.single_end     = false
    meta.platform       = row.containsKey('platform') ? (row.platform ? row.platform : 'illumina') : 'illumina'
    meta.datatype       = row.containsKey('datatype') ? (row.datatype ? row.datatype : 'eccdna') : 'eccdna'
    meta.data_type      = meta.datatype
    meta.assay          = row.containsKey('assay') && row.assay ? row.assay : (meta.datatype == 'gdna' ? 'wgs' : 'circleseq')
    meta.pair           = (row.containsKey('pair') && row.pair) ? row.pair : null
    meta.concatemer     = false
    meta.read_type      = row.containsKey('read_type') && row.read_type ? row.read_type : 'pe'
    meta.enrichment     = row.containsKey('enrichment') && row.enrichment ? row.enrichment : 'none'

    def array = []
    if (!file(row.bam).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> BAM file does not exist!\n${row.bam}"
    }
    else {
        array = [ meta, file(row.bam) ]
    }
    return array
}

def create_long_read_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.single_end   = row.containsKey('single_end') ? (row.single_end ? row.single_end.toBoolean() : false) : (!row.fastq_2 || row.fastq_2.isEmpty())
    meta.entrypoint   = row.entrypoint ?: params.entrypoint
    meta.platform     = row.platform ?: params.protocol
    meta.datatype     = row.containsKey('datatype') ? (row.datatype ? row.datatype : 'eccdna') : 'eccdna'
    meta.data_type    = meta.datatype
    meta.pair         = (row.containsKey('pair') && row.pair) ? row.pair : null
    meta.concatemer   = row.containsKey('concatemer') && row.concatemer ? row.concatemer.toBoolean() : false
    meta.read_type    = row.containsKey('read_type') && row.read_type ? row.read_type : (meta.platform == 'ont' ? 'ont' : 'hifi')
    meta.enrichment   = row.containsKey('enrichment') && row.enrichment ? row.enrichment : 'none'

    // assay：长读禁止猜 ciderseq；gdna 唯一合法为 wgs，eccdna 需显式或 params.assay 回填
    if (row.containsKey('assay') && row.assay) {
        meta.assay = row.assay
    } else if (meta.datatype == 'gdna') {
        meta.assay = 'wgs'
    } else if (params.containsKey('assay') && params.assay) {
        meta.assay = params.assay
    } else {
        exit 1, "ERROR: Please check input samplesheet -> long-read sample '${meta.id}' has no 'assay' column value! " +
                "Set assay explicitly (wgs|rca|ciderseq|enriched) or backfill with --assay."
    }

    // concatemer 缺省仅在 assay=rca 时有效，其余强制 false（§1.3）
    if (!row.containsKey('concatemer') || !row.concatemer) {
        meta.concatemer = (meta.assay == 'rca')
    }
    // 非 rca assay 不允许 concatemer=true（§1.3）
    if (meta.assay != 'rca' && meta.concatemer) {
        exit 1, "ERROR: concatemer=true is only meaningful for assay=rca (sample '${meta.id}')."
    }

    assert_valid_combination(meta)

    def fastq = null
    def input_bam = null

    if (row.fastq_1 && !row.fastq_1.isEmpty()) {
        if (!file(row.fastq_1).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> FastQ file does not exist!\n${row.fastq_1}"
        }
        fastq = file(row.fastq_1)
    }

    if (row.input_bam && !row.input_bam.isEmpty()) {
        if (!file(row.input_bam).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> BAM file does not exist!\n${row.input_bam}"
        }
        input_bam = file(row.input_bam)
    }

    return [ meta, fastq, input_bam, meta.entrypoint ]
}

//
// §1.3 组合断言（workflow 层再做一遍，防止绕过 check_samplesheet）
//
def assert_valid_combination(meta) {
    def platform = meta.platform
    def assay    = meta.assay
    def datatype = meta.datatype
    def enrichment = meta.enrichment

    if (platform == 'illumina') {
        if (assay == 'wgs' && datatype == 'gdna') return
        if (assay == 'circleseq' && datatype == 'eccdna') return
        if (assay == 'wgs' && datatype == 'eccdna' && enrichment != 'none') return
        exit 1, "ERROR: Invalid combination for sample '${meta.id}': illumina assay='${assay}' datatype='${datatype}'; allowed: wgs+gdna, circleseq+eccdna (Illumina RCA must be circleseq)"
    } else if (platform in ['pacbio', 'ont']) {
        if (assay == 'ciderseq') {
            if (datatype != 'eccdna') exit 1, "ERROR: Invalid combination for sample '${meta.id}': ciderseq requires datatype=eccdna"
            return
        }
        if (assay == 'rca') {
            if (datatype != 'eccdna') exit 1, "ERROR: Invalid combination for sample '${meta.id}': rca requires datatype=eccdna"
            return
        }
        if (assay == 'enriched') {
            if (datatype != 'eccdna') exit 1, "ERROR: Invalid combination for sample '${meta.id}': enriched requires datatype=eccdna"
            return
        }
        if (assay == 'wgs') {
            if (datatype != 'gdna') exit 1, "ERROR: Invalid combination for sample '${meta.id}': long-read wgs requires datatype=gdna (un-enriched WGS cannot be eccDNA)"
            return
        }
        exit 1, "ERROR: Invalid combination for sample '${meta.id}': long-read assay='${assay}' not allowed; use wgs|rca|ciderseq|enriched"
    } else {
        exit 1, "ERROR: Invalid combination for sample '${meta.id}': unknown platform '${platform}'"
    }
}
