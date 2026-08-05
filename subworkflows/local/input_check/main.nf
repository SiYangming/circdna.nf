include { SAMPLESHEET_CHECK } from '../../../modules/local/samplesheet_check/main'

workflow INPUT_CHECK {
    take:
    samplesheet

    main:
    SAMPLESHEET_CHECK ( samplesheet )
    ch_versions = SAMPLESHEET_CHECK.out.versions

    if ( params.input_format == "FASTQ" ) {
        channel.fromPath(samplesheet).splitCsv ( header:true, sep:',' )
            .map { it -> create_fastq_channels(it) }
            .set { reads }
    } else if ( params.input_format == "BAM" ) {
        channel.fromPath(samplesheet).splitCsv ( header:true, sep:',' )
            .map { it -> create_bam_channels(it) }
            .set { reads }
    } else if ( params.protocol in ["pacbio", "ont"] ) {
        channel.fromPath(samplesheet).splitCsv ( header:true, sep:',' )
            .map { it -> create_long_read_channels(it) }
            .set { reads }
    }

    emit:
    reads
    versions = ch_versions
}

def create_fastq_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.single_end   = row.containsKey('single_end') ? (row.single_end ? row.single_end.toBoolean() : false) : (!row.fastq_2 || row.fastq_2.isEmpty())
    if (row.containsKey('lane') && row.lane) {
        meta.lane = row.lane
    }
    // Support both 'data_type' and 'datatype' column names
    def dt_value = ''
    if (row.containsKey('data_type') && row.data_type) {
        dt_value = row.data_type.toLowerCase()
    } else if (row.containsKey('datatype') && row.datatype) {
        dt_value = row.datatype.toLowerCase()
    }
    meta.datatype = dt_value ?: 'eccdna'
    meta.data_type = meta.datatype
    meta.platform     = row.containsKey('platform') ? (row.platform ? row.platform : 'illumina') : 'illumina'
    meta.protocol     = row.containsKey('protocol') ? (row.protocol ? row.protocol : 'short_read') : 'short_read'
    // Support optional 'group' column for eccDNA/gDNA pairing
    meta.group = row.containsKey('group') ? (row.group ?: '') : ''

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

def create_bam_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id             = row.sample
    meta.single_end     = false
    meta.data_type = row.containsKey('data_type') ? (row.data_type ? row.data_type.toLowerCase() : 'eccdna') :
                     (row.containsKey('datatype') ? (row.datatype ? row.datatype.toLowerCase() : 'eccdna') : 'eccdna')
    meta.datatype = meta.data_type
    meta.group = row.containsKey('group') ? (row.group ?: '') : ''

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
