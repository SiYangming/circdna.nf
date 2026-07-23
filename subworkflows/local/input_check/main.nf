//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../../modules/local/samplesheet_check/main'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .set { parsed_samplesheet }

    if ( params.protocol == "short_read" && params.input_format == "FASTQ" ) {
        parsed_samplesheet
            .map { it -> create_short_read_fastq_channels(it) }
            .set { reads }
    } else if ( params.protocol == "short_read" && params.input_format == "BAM" ) {
        parsed_samplesheet
            .map { it -> create_short_read_bam_channels(it) }
            .set { reads }
    } else if ( params.protocol in ["pacbio", "ont"] ) {
        parsed_samplesheet
            .map { it -> create_long_read_channels(it) }
            .set { reads }
    } else {
        exit 1, "ERROR: Invalid combination of protocol '${params.protocol}' and input_format '${params.input_format}'"
    }

    emit:
    reads   // channel: [ val(meta), [ reads ] ] OR
            // channel: [ val(meta),  bam  ] OR
            // channel: [ val(meta), fastq, input_bam, entrypoint ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

def create_short_read_fastq_channels(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.single_end   = row.single_end.toBoolean()

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
    meta.single_end   = row.single_end.toBoolean()
    meta.entrypoint   = row.entrypoint ?: params.entrypoint

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