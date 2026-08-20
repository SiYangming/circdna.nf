//
// ECC_FINDER_ONT_SLIM — ONT (long-read) eccDNA 检测子工作流
// map-ont: minimap2 → PAF 过滤 → TideHunter 拆 unit → unit 重比对 → Genrich → merge
// asm-ont: TideHunter consensus → cd-hit-est 聚类 → 去 singleton
//

include { MINIMAP2_ALIGN as MINIMAP2_ONT          } from '../../../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_ONT_UNIT      } from '../../../modules/nf-core/minimap2/align/main'
include { TIDEHUNTER as TIDEHUNTER_UNIT            } from '../../../modules/local/tidehunter/main'
include { TIDEHUNTER as TIDEHUNTER_ASM             } from '../../../modules/local/tidehunter/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_NAME_ONT  } from '../../../modules/nf-core/samtools/sort/main'
include { GENRICH as GENRICH_ONT                   } from '../../../modules/nf-core/genrich/main'
include { CDHIT_CDHITEST as CDHIT_ONT              } from '../../../modules/nf-core/cdhit/cdhitest/main'
include { ECC_FINDER_ONT_PAF_FILTER } from '../../../modules/local/ecc_finder_slim/paf_filter/main'
include { ECC_FINDER_ONT_MERGE       } from '../../../modules/local/ecc_finder_slim/ont_merge/main'
include { ECC_FINDER_ONT_ASM         } from '../../../modules/local/ecc_finder_slim/ont_asm/main'

workflow ECC_FINDER_ONT_SLIM {
    take:
    reads       // channel: [meta, reads] (fasta/fastq long reads)
    fasta_meta  // channel: [meta, ref_fasta]
    run_map_ont // boolean
    run_asm_ont // boolean

    main:
    ch_versions = channel.empty()

    if (run_map_ont) {
        // 1) minimap2 map-ont → PAF
        MINIMAP2_ONT ( reads, fasta_meta, false, '', false, false )
        ch_versions = ch_versions.mix(MINIMAP2_ONT.out.versions_minimap2)

        // 2) PAF filtering (query/alignment length)
        ECC_FINDER_ONT_PAF_FILTER ( MINIMAP2_ONT.out.paf )
        ch_versions = ch_versions.mix(ECC_FINDER_ONT_PAF_FILTER.out.versions)

        // 3) TideHunter splits tandem repeats into units (args '-u' in modules.config → unit_fa)
        TIDEHUNTER_UNIT ( reads, [], [] )
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

        // 5) Genrich peak calling on unit alignments (nf-core GENRICH: treatment=[bam], control=[], blacklist=[])
        GENRICH_ONT (
            SAMTOOLS_SORT_NAME_ONT.out.bam.map { meta, bam -> [ meta, [bam], [] ] },
            []
        )
        ch_versions = ch_versions.mix(GENRICH_ONT.out.versions_genrich)

        // 6) merge sites with genome alignments → candidates
        // (narrowPeak 前 3 列即 BED chr/start/end，ont_merge 兼容多余列)
        ECC_FINDER_ONT_MERGE (
            GENRICH_ONT.out.peak,
            ECC_FINDER_ONT_PAF_FILTER.out.paf_bed,
            fasta_meta.map { _meta, f -> [ [id:'genome'], f ] }
        )
        ch_versions = ch_versions.mix(ECC_FINDER_ONT_MERGE.out.versions)
    }

    if (run_asm_ont) {
        // 1) TideHunter consensus (tandem repeat units per read)
        TIDEHUNTER_ASM ( reads, [], [] )
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
    }

    emit:
    map_csv         = run_map_ont ? ECC_FINDER_ONT_MERGE.out.csv     : channel.empty()
    map_fasta       = run_map_ont ? ECC_FINDER_ONT_MERGE.out.fasta   : channel.empty()
    asm_fasta       = run_asm_ont ? ECC_FINDER_ONT_ASM.out.fasta     : channel.empty()
    unit_fa         = run_map_ont ? TIDEHUNTER_UNIT.out.unit_fa      : channel.empty()
    versions        = ch_versions
}
