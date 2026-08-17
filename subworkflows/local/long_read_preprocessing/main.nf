include { PBCCS }            from '../../../modules/local/pbccs/main'
include { LIMA }             from '../../../modules/local/lima/main'
include { CHOPPER }          from '../../../modules/local/chopper/main'
include { PYCHOPPER }        from '../../../modules/local/pychopper/main'
include { NANOPLOT }         from '../../../modules/nf-core/nanoplot/main'

workflow LONG_READ_PREPROCESSING {
    take:
    reads   // channel: [ val(meta), fastq, input_bam, entrypoint ]

    main:
    // QC with NanoPlot (works for both PacBio and ONT long reads)
    ch_nanoplot_versions = channel.empty()
    ch_nanoplot_qc       = channel.empty()
    preprocessed_fastq   = channel.empty()

    if (!params.skip_long_read_qc) {
        reads
            .map { meta, fastq, bam, _ep -> [ meta, fastq ?: bam ] }
            .filter { _meta, f -> f != null }
            .set { ch_nanoplot_input }

        NANOPLOT ( ch_nanoplot_input )
        ch_nanoplot_versions = NANOPLOT.out.versions_nanoplot
        ch_nanoplot_qc       = NANOPLOT.out.txt
    }

    if ( params.protocol == "pacbio" ) {
        def pb_branches = reads
            .branch { _meta, fastq, input_bam, entrypoint ->
                pbccs: entrypoint == "subreads" && input_bam
                lima: (entrypoint == "hifi_bam" || entrypoint == "raw_fastq") && fastq
                cleaned: entrypoint == "cleaned_fastq" && fastq
            }

        def lima_input = channel.empty()

        if ( pb_branches.pbccs ) {
            PBCCS (
                pb_branches.pbccs.map { meta, _fastq, _input_bam, _entrypoint -> meta },
                pb_branches.pbccs.map { _meta, _fastq, input_bam, _entrypoint -> input_bam },
                pb_branches.pbccs.map { _meta, _fastq, input_bam, _entrypoint -> input_bam.toString().replace('.bam', '.bai') }
            )
                .hifi_fastq
                .combine(pb_branches.pbccs.map { meta, _fastq, _input_bam, _entrypoint -> meta })
                .set { ccs_output }

            lima_input = lima_input.mix(ccs_output)
        }

        if ( pb_branches.lima ) {
            lima_input = lima_input.mix(pb_branches.lima.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] })
        }

        if ( lima_input ) {
            LIMA (
                lima_input.map { meta, _fastq -> meta },
                lima_input.map { _meta, fastq -> fastq },
                channel.value(params.primers)
            )
                .trimmed_fastq
                .combine(lima_input.map { meta, _fastq -> meta })
                .set { lima_output }
        }

        if ( pb_branches.cleaned ) {
            preprocessed_fastq = pb_branches.cleaned.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] }
        }

        if ( lima_input ) {
            preprocessed_fastq = lima_output
        }

    } else if ( params.protocol == "ont" ) {
        def ont_branches = reads
            .branch { _meta, fastq, _input_bam, entrypoint ->
                raw: entrypoint == "raw_fastq" && fastq
                cleaned: entrypoint == "cleaned_fastq" && fastq
            }

        if ( ont_branches.raw ) {
            CHOPPER (
                ont_branches.raw.map { meta, _fastq, _input_bam, _entrypoint -> meta },
                ont_branches.raw.map { _meta, fastq, _input_bam, _entrypoint -> fastq }
            )
                .filtered_fastq
                .combine(ont_branches.raw.map { meta, _fastq, _input_bam, _entrypoint -> meta })
                .set { chopper_output }

            PYCHOPPER (
                chopper_output.map { meta, _filtered_fastq -> meta },
                chopper_output.map { _meta, filtered_fastq -> filtered_fastq },
                channel.value(params.primers)
            )
                .full_length_fastq
                .combine(chopper_output.map { meta, _filtered_fastq -> meta })
                .set { preprocessed_fastq }
        }

        if ( ont_branches.cleaned ) {
            preprocessed_fastq = ont_branches.cleaned.map { meta, fastq, _input_bam, _entrypoint -> [ meta, fastq ] }
        }
    }

    emit:
    preprocessed_fastq = preprocessed_fastq
    nanoplot_qc        = ch_nanoplot_qc
    versions           = ch_nanoplot_versions
}
