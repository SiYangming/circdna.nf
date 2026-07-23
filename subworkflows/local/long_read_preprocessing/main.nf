include { PBCCS }            from '../../../modules/local/pbccs/main'
include { LIMA }             from '../../../modules/local/lima/main'
include { CHOPPER }          from '../../../modules/local/chopper/main'
include { PYCHOPPER }        from '../../../modules/local/pychopper/main'

workflow LONG_READ_PREPROCESSING {
    take:
    reads   // channel: [ val(meta), fastq, input_bam, entrypoint ]

    main:
    if ( params.protocol == "pacbio" ) {
        def pb_branches = reads
            .branch { meta, fastq, input_bam, entrypoint ->
                pbccs: entrypoint == "subreads" && input_bam
                lima: (entrypoint == "hifi_bam" || entrypoint == "raw_fastq") && fastq
                cleaned: entrypoint == "cleaned_fastq" && fastq
            }

        def lima_input = channel.empty()

        if ( pb_branches.pbccs ) {
            PBCCS ( 
                pb_branches.pbccs.map { meta, fastq, input_bam, entrypoint -> meta },
                pb_branches.pbccs.map { meta, fastq, input_bam, entrypoint -> input_bam },
                pb_branches.pbccs.map { meta, fastq, input_bam, entrypoint -> input_bam.toString().replace('.bam', '.bai') }
            )
                .hifi_fastq
                .combine(pb_branches.pbccs.map { meta, fastq, input_bam, entrypoint -> meta })
                .set { ccs_output }

            lima_input = lima_input.mix(ccs_output)
        }

        if ( pb_branches.lima ) {
            lima_input = lima_input.mix(pb_branches.lima.map { meta, fastq, input_bam, entrypoint -> [ meta, fastq ] })
        }

        if ( lima_input ) {
            LIMA ( 
                lima_input.map { meta, fastq -> meta },
                lima_input.map { meta, fastq -> fastq },
                channel.value(params.primers)
            )
                .trimmed_fastq
                .combine(lima_input.map { meta, fastq -> meta })
                .set { lima_output }
        }

        if ( pb_branches.cleaned ) {
            pb_branches.cleaned.map { meta, fastq, input_bam, entrypoint -> [ meta, fastq ] }
                .set { preprocessed_fastq }
        }

        if ( lima_input ) {
            lima_output.set { preprocessed_fastq }
        }

    } else if ( params.protocol == "ont" ) {
        def ont_branches = reads
            .branch { meta, fastq, input_bam, entrypoint ->
                raw: entrypoint == "raw_fastq" && fastq
                cleaned: entrypoint == "cleaned_fastq" && fastq
            }

        if ( ont_branches.raw ) {
            CHOPPER ( 
                ont_branches.raw.map { meta, fastq, input_bam, entrypoint -> meta },
                ont_branches.raw.map { meta, fastq, input_bam, entrypoint -> fastq }
            )
                .filtered_fastq
                .combine(ont_branches.raw.map { meta, fastq, input_bam, entrypoint -> meta })
                .set { chopper_output }

            PYCHOPPER ( 
                chopper_output.map { meta, filtered_fastq -> meta },
                chopper_output.map { meta, filtered_fastq -> filtered_fastq },
                channel.value(params.primers)
            )
                .full_length_fastq
                .combine(chopper_output.map { meta, filtered_fastq -> meta })
                .set { preprocessed_fastq }
        }

        if ( ont_branches.cleaned ) {
            ont_branches.cleaned.map { meta, fastq, input_bam, entrypoint -> [ meta, fastq ] }
                .set { preprocessed_fastq }
        }
    }

    emit:
    preprocessed_fastq   // channel: [ val(meta), fastq ]
}