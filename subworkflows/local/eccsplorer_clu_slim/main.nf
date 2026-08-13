//
// ECCSPLORER_CLU_SLIM — 原子化 RepeatExplorer2 聚类子工作流
// clu_prepare (reads 预处理) → REPEATEXPLORER2 (seqclust 聚类) → clu_candidates (候选提取)
//

include { ECCSPLORER_CLU_PREPARE   } from '../../../modules/local/eccsplorer_slim/clu_prepare/main'
include { ECCSPLORER_CLU_CANDIDATES } from '../../../modules/local/eccsplorer_slim/clu_candidates/main'
include { REPEATEXPLORER2          } from '../../../../bio.nf/modules/repeatexplorer2/main'

workflow ECCSPLORER_CLU_SLIM {
    take:
    reads    // channel: [meta, r1, r2] treatment reads
    control  // channel: [meta, c1, c2] control reads
    taxon    // val

    main:
    ch_versions = channel.empty()

    // Prepare concatenated interlaced reads (TR/CO prefixed)
    ECCSPLORER_CLU_PREPARE ( reads, control, taxon )
    ch_versions = ch_versions.mix(ECCSPLORER_CLU_PREPARE.out.versions)

    // RepeatExplorer2 clustering
    REPEATEXPLORER2 (
        ECCSPLORER_CLU_PREPARE.out.ready_fa,
        taxon
    )
    ch_versions = ch_versions.mix(REPEATEXPLORER2.out.versions)

    // Extract eccDNA candidate clusters
    ECCSPLORER_CLU_CANDIDATES (
        REPEATEXPLORER2.out.clu_dir,
        'TR',
        'CO'
    )
    ch_versions = ch_versions.mix(ECCSPLORER_CLU_CANDIDATES.out.versions)

    emit:
    ready_fa        = ECCSPLORER_CLU_PREPARE.out.ready_fa
    clu_dir         = REPEATEXPLORER2.out.clu_dir
    cluster_candidates = ECCSPLORER_CLU_CANDIDATES.out.cluster_candidates
    comparative_table  = ECCSPLORER_CLU_CANDIDATES.out.comparative_table
    versions        = ch_versions
}
