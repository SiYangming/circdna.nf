include { CIRCLESEEKER } from '../../../modules/local/circleseeker/main'

workflow CIRCLESEEKER_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    ch_versions = channel.empty()

    genome_fasta
        .map { fasta -> [[id: 'genome'], fasta] }
        .set { genome_fasta_meta }

    CIRCLESEEKER ( reads, genome_fasta_meta )
    ch_versions = ch_versions.mix(CIRCLESEEKER.out.versions)

    emit:
    merged   = CIRCLESEEKER.out.merged      // channel: [ val(meta), <prefix>_merged_output.csv ]
    bed      = CIRCLESEEKER.out.bed         // channel: [ val(meta), <prefix>.circleseeker.bed ]
    summary  = CIRCLESEEKER.out.summary     // channel: [ val(meta), <prefix>_summary.txt ]
    report   = CIRCLESEEKER.out.report      // channel: [ val(meta), <prefix>_report.html ]
    versions = ch_versions
}
