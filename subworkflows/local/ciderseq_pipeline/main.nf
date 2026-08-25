include { CIDERSEQ_SEPARATE } from '../../../modules/local/ciderseq/separate/main'
include { CIDERSEQ_ALIGN    } from '../../../modules/local/ciderseq/align/main'
include { CIDERSEQ_DECONCAT } from '../../../modules/local/ciderseq/deconcat/main'
include { CIDERSEQ_ANNOTATE } from '../../../modules/local/ciderseq/annotate/main'
include { CIDERSEQ_PHASE    } from '../../../modules/local/ciderseq/phase/main'

workflow CIDERSEQ_PIPELINE {
    take:
    reads           // channel: [ val(meta), fastq ]
    config          // channel: path to ciderseq_config.json
    blastdb         // channel: directory (or db file) of the blastn database
    align_targets   // channel: directory of the align target fasta files
    protein_db      // channel: directory (or db file) of the tblastn protein database
    align_genomes   // val: list of genome names to align (keys of config align.targets)
    phase_genomes   // val: list of genome names to phase (keys of config phase.phasegenomes)

    main:
    ch_versions = channel.empty()

    // STEP 1: separate — BLASTn read binning (per sample, emits one file per genome)
    CIDERSEQ_SEPARATE ( reads, config, blastdb )
        .separated
        .flatMap { meta, fastas ->
            (fastas as List).collect { fasta ->
                // {sample}.{genome}.fa -> genome = last dot-separated token
                def genome = fasta.baseName.tokenize('.').last()
                [ meta + [ genome: genome ], genome, fasta ]
            }
        }
        .branch { meta, genome, fasta ->
            alignable: align_genomes.contains(genome)
            skipped:   true
        }
        .set { ch_separated_branch }
    ch_versions = ch_versions.mix(CIDERSEQ_SEPARATE.out.versions)

    // STEP 2: align — MUSCLE end trimming (per genome, only target genomes)
    CIDERSEQ_ALIGN (
        ch_separated_branch.alignable.map { meta, genome, fasta -> [ meta, fasta ] },
        config,
        align_targets,
        ch_separated_branch.alignable.map { meta, genome, fasta -> genome }
    )
    ch_versions = ch_versions.mix(CIDERSEQ_ALIGN.out.versions)

    // STEP 3: deconcat — DeConcat algorithm (per genome)
    CIDERSEQ_DECONCAT ( CIDERSEQ_ALIGN.out.aligned, config )
    ch_versions = ch_versions.mix(CIDERSEQ_DECONCAT.out.versions)

    // STEP 4: annotate — tBLASTn ORF annotation (per genome)
    CIDERSEQ_ANNOTATE ( CIDERSEQ_DECONCAT.out.deconcat, config, protein_db )
    ch_versions = ch_versions.mix(CIDERSEQ_ANNOTATE.out.versions)

    // STEP 5: phase — sequence phasing (per genome, only phase genomes)
    // Join deconcat fasta with its annotation JSON by (sample, genome).
    ch_deconcat_for_phase = CIDERSEQ_DECONCAT.out.deconcat
        .map { meta, fa -> [ meta.id + '|' + meta.genome, meta, fa ] }
    ch_annotation_for_phase = CIDERSEQ_ANNOTATE.out.annotation
        .map { meta, json -> [ meta.id + '|' + meta.genome, json ] }

    ch_deconcat_for_phase
        .join( ch_annotation_for_phase )
        .map { key, meta, fa, json -> [ meta, fa, json ] }
        .filter { meta, fa, json -> phase_genomes.contains(meta.genome) }
        .set { ch_phase_input }

    CIDERSEQ_PHASE (
        ch_phase_input.map { meta, fa, json -> [ meta, fa ] },
        ch_phase_input.map { meta, fa, json -> json },
        config,
        ch_phase_input.map { meta, fa, json -> meta.genome }
    )
    ch_versions = ch_versions.mix(CIDERSEQ_PHASE.out.versions)

    emit:
    separated   = CIDERSEQ_SEPARATE.out.separated
    aligned     = CIDERSEQ_ALIGN.out.aligned
    deconcat    = CIDERSEQ_DECONCAT.out.deconcat
    stat        = CIDERSEQ_DECONCAT.out.stat
    annotation  = CIDERSEQ_ANNOTATE.out.annotation
    phased      = CIDERSEQ_PHASE.out.phased
    versions    = ch_versions
}
