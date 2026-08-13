//
// ECC Preprocessing Subworkflow
// Orchestrates the eccPrepare.py preprocessing chain:
//   FASTQ → FASTA → best_read_length → read_count → sub-sampled temp_fasta → merged FASTA
//
// Input:  ch_trimmed_reads (PE FASTQ from TrimGalore, [meta, [r1, r2]])
// Output: prexed_fasta (merged REPEATEXPLORER_READY.fa), versions
//

include { SEQTK_SEQ as SEQTK_SEQ_R1             } from '../../../modules/nf-core/seqtk/seq/main'
include { SEQTK_SEQ as SEQTK_SEQ_R2             } from '../../../modules/nf-core/seqtk/seq/main'
include { ECCSPLORER_PREPARE_READ_LENGTH   } from '../../../modules/local/eccsplorer_prepare_read_length/main'
include { ECCSPLORER_PREPARE_READ_COUNT    } from '../../../modules/local/eccsplorer_prepare_read_count/main'
include { ECCSPLORER_PREPARE_PREXING       } from '../../../modules/local/eccsplorer_prepare_prexing/main'
include { SEQKIT_CONCAT                     } from '../../../modules/nf-core/seqkit/concat/main'

workflow ECC_PREPROCESSING {
    take:
    ch_trimmed_reads       // [meta, [fastq1, fastq2]]

    main:
    ch_versions = channel.empty()

    //
    // Step 1: Convert PE FASTQ → FASTA (R1 and R2 separately)
    //
    ch_read1 = ch_trimmed_reads
        .map { meta, reads -> [meta, reads[0]] }
    ch_read2 = ch_trimmed_reads
        .map { meta, reads -> [meta, reads[1]] }

    ch_seqtk_r1 = SEQTK_SEQ_R1(ch_read1)
    ch_seqtk_r2 = SEQTK_SEQ_R2(ch_read2)
    ch_versions = ch_versions.mix(ch_seqtk_r1.versions_seqtk, ch_seqtk_r2.versions_seqtk)

    //
    // Step 2: Merge R1 FASTA + R2 FASTA → [meta, fasta1, fasta2]
    //
    ch_fasta_pairs = ch_seqtk_r1.fastx
        .map { meta, fasta -> [meta.id, fasta] }
        .join(
            ch_seqtk_r2.fastx
                .map { meta, fasta -> [meta.id, fasta] }
        )
        .map { id, fasta1, fasta2 -> [[id: id], fasta1, fasta2] }

    //
    // Step 3: Compute optimal read length per-sample, take global minimum
    //
    ch_read_length_input = ch_seqtk_r1.fastx
        .map { meta, fasta -> [meta, fasta] }

    ECCSPLORER_PREPARE_READ_LENGTH(ch_read_length_input)
    ch_versions = ch_versions.mix(ECCSPLORER_PREPARE_READ_LENGTH.out.versions)

    ch_best_read_length = ECCSPLORER_PREPARE_READ_LENGTH.out.read_length
        .map { meta, length_str -> length_str.trim().toInteger() }
        .collect()
        .map { lengths -> lengths.min() }

    //
    // Step 4: Compute available PE read count per-sample, take global minimum
    //
    ECCSPLORER_PREPARE_READ_COUNT(
        ch_fasta_pairs
            .combine(ch_best_read_length)
            .map { meta, fasta1, fasta2, brl -> [meta, fasta1, fasta2, brl] }
    )
    ch_versions = ch_versions.mix(ECCSPLORER_PREPARE_READ_COUNT.out.versions)

    ch_read_count = ECCSPLORER_PREPARE_READ_COUNT.out.read_count
        .map { meta, count_str -> count_str.trim().toInteger() }
        .collect()
        .map { counts -> counts.min() }

    //
    // Step 5: Sub-sample & truncate per-sample → temp FASTA
    //
    ECCSPLORER_PREPARE_PREXING(
        ch_fasta_pairs
            .combine(ch_best_read_length)
            .map { meta, fasta1, fasta2, brl -> [meta, fasta1, fasta2, brl] }
            .combine(ch_read_count)
            .map { meta, fasta1, fasta2, brl, rc -> [meta, fasta1, fasta2, brl, rc] }
    )
    ch_versions = ch_versions.mix(ECCSPLORER_PREPARE_PREXING.out.versions)

    //
    // Step 6: Concatenate all temp FASTA into REPEATEXPLORER_READY.fa
    //
    ch_concat_input = ECCSPLORER_PREPARE_PREXING.out.temp_fasta
        .map { meta, fasta -> fasta }
        .collect()
        .map { fasta_list -> [[id: 'repeat_explorer_ready'], fasta_list] }

    SEQKIT_CONCAT(ch_concat_input)
    ch_versions = ch_versions.mix(SEQKIT_CONCAT.out.versions_seqkit)

    emit:
    prexed_fasta = SEQKIT_CONCAT.out.fastx
    versions     = ch_versions
}
