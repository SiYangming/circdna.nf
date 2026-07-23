include { FLED } from '../../../modules/local/fled/main'

workflow FLED_PIPELINE {
    take:
    mapped_reads    // channel: [ val(meta), bam, bai ]
    genome_fasta    // file: reference genome

    main:
    FLED ( 
        mapped_reads.map { meta, bam, bai -> meta },
        mapped_reads.map { meta, bam, bai -> bam },
        mapped_reads.map { meta, bam, bai -> bai },
        channel.value(genome_fasta)
    )
        .circles_bed
        .set { eccdna_candidates }

    emit:
    eccdna_candidates    // channel: [ val(meta), circles.bed ]
}