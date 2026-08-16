include { FLED } from '../../../modules/local/fled/main'

workflow FLED_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    reads
        .combine(genome_fasta)
        .set { fled_input }

    FLED (
        fled_input.map { meta, fastq, fasta -> [ meta, fastq ] },
        fled_input.map { meta, fastq, fasta -> fasta }
    )

    // Combine both junction outputs into a single candidates channel:
    // [ val(meta), <prefix>.*Junction.out ]
    FLED.out.junctions
        .set { eccdna_candidates }

    emit:
    eccdna_candidates    // channel: [ val(meta), <prefix>.*Junction.out ]
}
