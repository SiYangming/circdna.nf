include { FLED } from '../../../modules/local/fled/main'

workflow FLED_PIPELINE {
    take:
    mapped_reads    // channel: [ val(meta), bam, bai ]
    genome_fasta    // channel: reference genome file

    main:
    mapped_reads
        .combine(genome_fasta)
        .set { fled_input }

    FLED (
        fled_input.map { meta, bam, bai, fasta -> meta },
        fled_input.map { meta, bam, bai, fasta -> bam },
        fled_input.map { meta, bam, bai, fasta -> bai },
        fled_input.map { meta, bam, bai, fasta -> fasta }
    )
    fled_input
        .map { meta, bam, bai, fasta -> meta }
        .set { fled_meta }

    FLED.out.circles_bed
        .combine(fled_meta)
        .map { bed, meta -> [ meta, bed ] }
        .set { eccdna_candidates }

    emit:
    eccdna_candidates    // channel: [ val(meta), circles.bed ]
}