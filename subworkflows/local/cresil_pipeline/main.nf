include { CRESIL_TRIM }      from '../../../modules/local/cresil/trim/main'
include { CRESIL_IDENTIFY }  from '../../../modules/local/cresil/identify/main'
include { CRESIL_ANNOTATE }  from '../../../modules/local/cresil/annotate/main'

workflow CRESIL_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // file: reference genome

    main:
    def genome_fasta_meta = channel.from([[id: 'genome'], genome_fasta])

    def minimap2_index = channel.fromPath(genome_fasta.toString().replace('.fa', '.mmi'), checkIfExists: false)
        .ifEmpty { channel.empty() }

    CRESIL_TRIM ( reads, minimap2_index )
        .trim
        .set { trimmed_reads }

    def genome_fai = channel.empty()

    CRESIL_IDENTIFY ( genome_fasta_meta, genome_fai, reads, trimmed_reads )
        .identify
        .set { eccdna_candidates }

    CRESIL_ANNOTATE ( eccdna_candidates, channel.empty(), channel.empty(), channel.empty() )
        .gene_annot
        .set { annotated_eccdna }

    emit:
    eccdna_candidates    // channel: [ val(meta), eccdna_final.txt ]
    annotated_eccdna     // channel: [ val(meta), gene_annotate.txt ]
}