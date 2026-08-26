include { PBCCS }            from '../../../modules/nf-core/pbccs/main'
include { LIMA }             from '../../../modules/nf-core/lima/main'
include { CHOPPER }          from '../../../modules/nf-core/chopper/main'
include { PYCHOPPER }        from '../../../modules/nf-core/pychopper/main'
include { SAMTOOLS_CAT }     from '../../../modules/nf-core/samtools/cat/main'
include { SAMTOOLS_BAM2FQ }  from '../../../modules/nf-core/samtools/bam2fq/main'
include { NANOPLOT }         from '../../../modules/nf-core/nanoplot/main'

workflow LONG_READ_PREPROCESSING {
    take:
    reads   // channel: [ val(meta), fastq, input_bam, entrypoint ]

    main:
    ch_versions        = channel.empty()
    ch_nanoplot_qc     = channel.empty()
    preprocessed_fastq = channel.empty()

    // QC with NanoPlot (works for both PacBio and ONT long reads)
    if (!params.skip_long_read_qc) {
        reads
            .map { meta, fastq, bam, _ep -> [ meta, fastq ?: bam ] }
            .filter { _meta, f -> f != null }
            .set { ch_nanoplot_input }

        NANOPLOT ( ch_nanoplot_input )
        ch_versions    = ch_versions.mix(NANOPLOT.out.versions_nanoplot)
        ch_nanoplot_qc = NANOPLOT.out.txt
    }

    // 按行 meta.platform 分支（混表：ONT 行绝不进 PBCCS/LIMA）
    def pb_branches = reads
        .filter { meta, _f, _b, _ep -> meta.platform == 'pacbio' }
        .branch { _meta, fastq, input_bam, entrypoint ->
            pbccs: entrypoint == "subreads" && input_bam
            lima: (entrypoint == "hifi_bam" || entrypoint == "raw_fastq") && fastq
            cleaned: entrypoint == "cleaned_fastq" && fastq
        }

    def ont_branches = reads
        .filter { meta, _f, _b, _ep -> meta.platform == 'ont' }
        .branch { _meta, fastq, _input_bam, entrypoint ->
            raw: entrypoint == "raw_fastq" && fastq
            cleaned: entrypoint == "cleaned_fastq" && fastq
        }

    def lima_input = channel.empty()

    if ( pb_branches.pbccs ) {
        // nf-core PBCCS 分块模式：按 subreads BAM 大小计算分块数
        pb_branches.pbccs
            .map { meta, _fastq, input_bam, _entrypoint ->
                def bai = input_bam.toString().replace('.bam', '.bai')
                def n_chunks = Math.max(1, Math.ceil(input_bam.size() / (params.ccs_chunk_size * 1e9)) as int)
                [ [ meta, input_bam, bai ], n_chunks ]
            }
            .flatMap { ccs_tuple, n_chunks ->
                (1..n_chunks).collect { cn -> [ ccs_tuple, cn, n_chunks ] }
            }
            .set { ch_ccs_chunks }

        PBCCS (
            ch_ccs_chunks.map { ccs_tuple, _cn, _chunk_on -> ccs_tuple },
            ch_ccs_chunks.map { _ccs_tuple, cn, _chunk_on -> cn },
            ch_ccs_chunks.map { _ccs_tuple, _cn, chunk_on -> chunk_on }
        )
        ch_versions = ch_versions.mix(PBCCS.out.versions)

        PBCCS.out.bam
            .map { meta, bam -> [ meta, bam ] }
            .groupTuple(by: 0)
            .map { meta, bams -> [ meta, bams.sort { a, b -> chunk_no(a) <=> chunk_no(b) } ] }
            .set { ch_ccs_bams }

        SAMTOOLS_CAT ( ch_ccs_bams )
        ch_versions = ch_versions.mix(SAMTOOLS_CAT.out.versions_samtools)

        lima_input = lima_input.mix(SAMTOOLS_CAT.out.bam)
    }

    if ( pb_branches.lima ) {
        lima_input = lima_input.mix(pb_branches.lima.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] })
    }

    if ( lima_input ) {
        LIMA ( lima_input, channel.value(params.primers) )
        ch_versions = ch_versions.mix(LIMA.out.versions_lima)

        // BAM 输入 → LIMA 输出 BAM → 转 FASTQ；FASTQ 输入 → 直接使用
        SAMTOOLS_BAM2FQ ( LIMA.out.bam, false )
        ch_versions = ch_versions.mix(SAMTOOLS_BAM2FQ.out.versions_samtools)

        preprocessed_fastq = LIMA.out.fastqgz.mix(SAMTOOLS_BAM2FQ.out.reads)
    }

    if ( pb_branches.cleaned ) {
        preprocessed_fastq = preprocessed_fastq.mix(pb_branches.cleaned.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] })
    }

    if ( ont_branches.raw ) {
        CHOPPER (
            ont_branches.raw.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] },
            []
        )
        ch_versions = ch_versions.mix(CHOPPER.out.versions_chopper)

        PYCHOPPER ( CHOPPER.out.fastq )
        ch_versions = ch_versions.mix(PYCHOPPER.out.versions)

        preprocessed_fastq = preprocessed_fastq.mix(PYCHOPPER.out.fastq)
    }

    if ( ont_branches.cleaned ) {
        preprocessed_fastq = preprocessed_fastq.mix(ont_branches.cleaned.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] })
    }

    emit:
    preprocessed_fastq = preprocessed_fastq
    nanoplot_qc        = ch_nanoplot_qc
    versions           = ch_versions
}

// 从分块文件名（{prefix}.chunk{N}.bam）中提取 chunk 编号
def chunk_no(file) {
    def m = (file.name =~ /chunk(\d+)/)
    m ? m[0][1] as int : 0
}
