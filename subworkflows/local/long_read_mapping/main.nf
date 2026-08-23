include { MINIMAP2_ALIGN }   from '../../../modules/nf-core/minimap2/align/main'
include { SAMTOOLS_SORT }    from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX }   from '../../../modules/nf-core/samtools/index/main'

workflow LONG_READ_MAPPING {
    take:
    reads           // channel: [ val(meta), fastq ]
    genome_fasta    // channel: reference genome file(s)

    main:
    ch_versions = channel.empty()

    // For MINIMAP2_ALIGN: 2-tuple [ val(meta), path(reference) ]
    genome_fasta
        .map { fasta -> [[id: 'genome'], fasta] }
        .set { genome_fasta_meta }

    // For SAMTOOLS_SORT: 3-tuple [ val(meta2), path(fasta), path(fai) ]
    // fai is optional; pass empty list if not available
    genome_fasta
        .map { fasta ->
            def fai_file = new File(fasta.toString() + '.fai')
            [[id: 'genome'], fasta, fai_file.exists() ? fai_file : []]
        }
        .set { genome_fasta_fai }

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
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN.out.versions)

    SAMTOOLS_SORT ( aligned_bam, genome_fasta_fai, channel.value('bai') )
        .bam
        .set { sorted_bam }
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions)

    SAMTOOLS_INDEX ( sorted_bam )
        .index
        .set { bam_index }
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    // Combine sorted bam with its index into 3-tuple [ val(meta), bam, bai ]
    sorted_bam
        .join(bam_index, by: [0])
        .set { mapped_reads }

    emit:
    mapped_reads = mapped_reads    // channel: [ val(meta), sorted.bam, bai ]
    versions     = ch_versions
}
