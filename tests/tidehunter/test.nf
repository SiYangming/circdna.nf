#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { TIDEHUNTER } from '../../modules/local/tidehunter/main'

workflow {
    ch_input = Channel.of(
        [ [id: 'sim_tandem'], file("${projectDir}/data/sim_tandem.fa") ]
    )

    TIDEHUNTER ( ch_input )

    TIDEHUNTER.out.cons_fa
        .view { meta, fa -> "TIDEHUNTER OK: ${fa}" }
}
