//
// ECC_FINDER_ONT_SLIM — long-read (ONT/PacBio) eccDNA 检测子工作流（RCA 默认路径）
// map:   minimap2 → PAF 过滤 → [concatemer=true → TideHunter 拆 unit → unit 重比对]
//        → Genrich → merge
// asm:   TideHunter consensus → cd-hit-est 聚类 → 去 singleton
//
// RCA 语义（§4.1）：
//   * preset 跟 meta.read_type（map-hifi / map-pb / map-ont），不写死 map-ont
//   * concatemer=false（线性化 RCA / T7 debranch）：不跑 TIDEHUNTER_UNIT/ASM，
//     只跑 minimap2 map（BAM）+ Genrich + merge
//   * asm 分支仅 concatemer=true 且 read_type != clr
//

include { MINIMAP2_ALIGN as MINIMAP2_ONT          } from '../../../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_ONT_UNIT      } from '../../../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_ONT_READBAM   } from '../../../modules/nf-core/minimap2/align/main'
include { TIDEHUNTER as TIDEHUNTER_UNIT            } from '../../../modules/local/tidehunter/main'
include { TIDEHUNTER as TIDEHUNTER_ASM             } from '../../../modules/local/tidehunter/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_NAME_ONT  } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_READ      } from '../../../modules/nf-core/samtools/sort/main'
include { GENRICH as GENRICH_ONT                   } from '../../../modules/nf-core/genrich/main'
include { CDHIT_CDHITEST as CDHIT_ONT              } from '../../../modules/nf-core/cdhit/cdhitest/main'
include { ECC_FINDER_ONT_PAF_FILTER } from '../../../modules/local/ecc_finder_slim/paf_filter/main'
include { ECC_FINDER_ONT_MERGE       } from '../../../modules/local/ecc_finder_slim/ont_merge/main'
include { ECC_FINDER_ONT_ASM         } from '../../../modules/local/ecc_finder_slim/ont_asm/main'
include { ECC_FINDER_ONT_CSV_TO_BED } from '../../../modules/local/ecc_finder_ont_csv_to_bed/main'

workflow ECC_FINDER_ONT_SLIM {
    take:
    reads       // channel: [meta, reads] (fasta/fastq long reads)
    fasta_meta  // channel: [meta, ref_fasta]
    run_map_ont // boolean
    run_asm_ont // boolean

    main:
    ch_versions = channel.empty()
    def ch_map_csv    = channel.empty()
    def ch_map_fasta  = channel.empty()
    def ch_map_bed    = channel.empty()
    def ch_asm_fasta  = channel.empty()
    def ch_unit_fa    = channel.empty()

    if (run_map_ont) {
        // 1) minimap2 map → PAF（preset 由 modules.config 按 meta.read_type 决定）
        MINIMAP2_ONT ( reads, fasta_meta, false, '', false, false )
        ch_versions = ch_versions.mix(MINIMAP2_ONT.out.versions_minimap2)

        // 2) PAF filtering (query/alignment length)
        ECC_FINDER_ONT_PAF_FILTER ( MINIMAP2_ONT.out.paf )
        ch_versions = ch_versions.mix(ECC_FINDER_ONT_PAF_FILTER.out.versions)

        // 3) concatemer 分支：true → TideHunter 拆 unit；false → 直接对原始 reads 比对做 Genrich
        def concat_reads   = reads.filter { meta, _f -> meta.concatemer }
        def noconcat_reads = reads.filter { meta, _f -> !meta.concatemer }

        def ch_unit_bam = channel.empty()
        if (concat_reads) {
            TIDEHUNTER_UNIT ( concat_reads, [], [] )
            ch_versions = ch_versions.mix(TIDEHUNTER_UNIT.out.versions)

            // 4) unit re-alignment → name-sorted BAM
            MINIMAP2_ONT_UNIT ( TIDEHUNTER_UNIT.out.unit_fa, fasta_meta, true, '', false, false )
            SAMTOOLS_SORT_NAME_ONT (
                MINIMAP2_ONT_UNIT.out.bam,
                fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
                ''
            )
            ch_versions = ch_versions.mix(
                MINIMAP2_ONT_UNIT.out.versions_minimap2,
                SAMTOOLS_SORT_NAME_ONT.out.versions_samtools
            )
            ch_unit_bam = ch_unit_bam.mix(SAMTOOLS_SORT_NAME_ONT.out.bam)
            ch_unit_fa  = ch_unit_fa.mix(TIDEHUNTER_UNIT.out.unit_fa)
        }

        if (noconcat_reads) {
            // 无 TideHunter：原始 reads 比对成 BAM（coordinate sort）→ Genrich
            MINIMAP2_ONT_READBAM ( noconcat_reads, fasta_meta, true, '', false, false )
            SAMTOOLS_SORT_READ (
                MINIMAP2_ONT_READBAM.out.bam,
                fasta_meta.map { meta, fa -> [ meta, fa, [] ] },
                ''
            )
            ch_versions = ch_versions.mix(
                MINIMAP2_ONT_READBAM.out.versions_minimap2,
                SAMTOOLS_SORT_READ.out.versions_samtools
            )
            ch_unit_bam = ch_unit_bam.mix(SAMTOOLS_SORT_READ.out.bam)
        }

        // 5) Genrich peak calling（nf-core GENRICH: treatment=[bam], control=[], blacklist=[]）
        GENRICH_ONT (
            ch_unit_bam.map { meta, bam -> [ meta, [bam], [] ] },
            []
        )
        ch_versions = ch_versions.mix(GENRICH_ONT.out.versions_genrich)

        // 6) merge sites with genome alignments → candidates
        ECC_FINDER_ONT_MERGE (
            GENRICH_ONT.out.peak,
            ECC_FINDER_ONT_PAF_FILTER.out.paf_bed,
            fasta_meta.map { _meta, f -> [ [id:'genome'], f ] }
        )
        ch_versions = ch_versions.mix(ECC_FINDER_ONT_MERGE.out.versions)
        ch_map_csv   = ch_map_csv.mix(ECC_FINDER_ONT_MERGE.out.csv)
        ch_map_fasta = ch_map_fasta.mix(ECC_FINDER_ONT_MERGE.out.fasta)
        ECC_FINDER_ONT_CSV_TO_BED ( ECC_FINDER_ONT_MERGE.out.csv )
        ch_versions = ch_versions.mix(ECC_FINDER_ONT_CSV_TO_BED.out.versions)
        ch_map_bed  = ch_map_bed.mix(ECC_FINDER_ONT_CSV_TO_BED.out.bed)
    }

    if (run_asm_ont) {
        def asm_reads = reads.filter { meta, _f -> meta.concatemer && meta.read_type != 'clr' }
        if (asm_reads) {
            // 1) TideHunter consensus (tandem repeat units per read)
            TIDEHUNTER_ASM ( asm_reads, [], [] )
            ch_versions = ch_versions.mix(TIDEHUNTER_ASM.out.versions)

            // 2) cd-hit-est clustering
            CDHIT_ONT ( TIDEHUNTER_ASM.out.cons_fa )
            ch_versions = ch_versions.mix(CDHIT_ONT.out.versions_cdhitest)

            // 3) drop singletons
            ECC_FINDER_ONT_ASM (
                CDHIT_ONT.out.fasta,
                CDHIT_ONT.out.clusters
            )
            ch_versions = ch_versions.mix(ECC_FINDER_ONT_ASM.out.versions)
            ch_asm_fasta = ch_asm_fasta.mix(ECC_FINDER_ONT_ASM.out.fasta)
        }
    }

    emit:
    map_csv    = ch_map_csv
    map_fasta  = ch_map_fasta
    map_bed    = ch_map_bed
    asm_fasta  = ch_asm_fasta
    unit_fa    = ch_unit_fa
    versions   = ch_versions
}
