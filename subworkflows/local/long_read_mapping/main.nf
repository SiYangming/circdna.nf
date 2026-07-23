include { MINIMAP2_ALIGN }   from '../../../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_SORT }    from '../../../modules/nf-core/samtools/sort/main'

workflow LONG_READ_MAPPING {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // file: reference genome

    main:
    def genome_fasta_meta = channel.value([[id: 'genome'], genome_fasta])
    
    def genome_fai = channel.fromPath(genome_fasta.toString().replace('.fa', '.fai'), checkIfExists: false)
    
    MINIMAP2_ALIGN ( 
        reads, 
        genome_fasta_meta, 
        channel.value(true), 
        channel.value('bai'), 
        channel.value(false), 
        channel.value(true) 
    )
        .bam
        .set { aligned_bam }

    SAMTOOLS_SORT ( aligned_bam, genome_fasta_meta.combine(genome_fai), channel.value('bai') )
        .bam
        .set { sorted_bam }

    emit:
    sorted_bam    // channel: [ val(meta), sorted.bam ]
}