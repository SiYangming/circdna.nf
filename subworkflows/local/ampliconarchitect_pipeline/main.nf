//
// AmpliconArchitect Pipeline Subworkflow
// Contains: CNVKIT_BATCH, CNVKIT_SEGMENT, AMPLICONSUITE
//

include { CNVKIT_BATCH         }     from '../../../modules/nf-core/cnvkit/batch/main'
include { CNVKIT_SEGMENT       }     from '../../../modules/nf-core/cnvkit/segment/main'
include { AMPLICONSUITE                                 }     from '../../../modules/local/ampliconsuite/main'

workflow AMPLICONARCHITECT_PIPELINE {
    take:
    bam_sorted              // channel: [ val(meta), path(bam) ]
    bam_sorted_bai          // channel: [ val(meta), path(bai) ]
    fasta_fai               // channel: [ val(meta), path(fasta), path(fai) ]
    cnvkit_reference        // path: cnvkit reference file
    mosek_license_dir       // path: mosek license directory
    aa_data_repo            // path: ampliconarchitect data repository

    main:
    ch_versions = channel.empty()

    ch_bam_bai_for_cnvkit = bam_sorted.join(bam_sorted_bai)

    CNVKIT_BATCH (
        ch_bam_bai_for_cnvkit.map { meta, bam, bai -> [meta, bam, bai, [], []] },
        fasta_fai,
        channel.empty(),
        cnvkit_reference,
        []
    )
    ch_versions = ch_versions.mix(CNVKIT_BATCH.out.versions_cnvkit)
    ch_versions = ch_versions.mix(CNVKIT_BATCH.out.versions_samtools)

    CNVKIT_SEGMENT (
        CNVKIT_BATCH.out.cnr
    )
    ch_versions = ch_versions.mix(CNVKIT_SEGMENT.out.versions_cnvkit)

    AMPLICONSUITE (
        bam_sorted,
        mosek_license_dir,
        aa_data_repo
    )
    ch_versions = ch_versions.mix(AMPLICONSUITE.out.versions)

    emit:
    cnvkit_cnr = CNVKIT_BATCH.out.cnr
    cnvkit_cns = CNVKIT_SEGMENT.out.segments
    versions = ch_versions
}
