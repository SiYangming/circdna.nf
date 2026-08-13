#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { ECC_FINDER_ONT_SLIM } from '../../subworkflows/local/ecc_finder_ont_slim/main'

workflow {
    ch_reads = Channel.of(
        [ [id: 'sim_ont'], file("${projectDir}/../tidehunter/data/sim_tandem.fa") ]
    )
    ch_ref = Channel.of(
        [ [id: 'genome'], file("${projectDir}/../../testdatasets/reference/genome.fa") ]
    )

    ECC_FINDER_ONT_SLIM ( ch_reads, ch_ref, false, true )

    ECC_FINDER_ONT_SLIM.out.map_csv.view { m, f -> "ONT MAP CSV: ${f}" }
    ECC_FINDER_ONT_SLIM.out.asm_fasta.view { m, f -> "ONT ASM FASTA: ${f}" }
}
