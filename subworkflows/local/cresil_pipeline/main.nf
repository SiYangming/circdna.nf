include { CRESIL_TRIM }      from '../../../modules/local/cresil/trim/main'
include { CRESIL_IDENTIFY }  from '../../../modules/local/cresil/identify/main'
include { CRESIL_ANNOTATE }  from '../../../modules/local/cresil/annotate/main'

workflow CRESIL_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file

    main:
    genome_fasta
        .map { fasta -> [[id: 'genome'], fasta] }
        .set { genome_fasta_meta }

    // Use genome fasta as minimap2 index reference (cresil builds index if .mmi not found)
    genome_fasta_meta
        .set { minimap2_index }

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