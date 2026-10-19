include { CRESIL_VISUALIZE } from './main.nf'

workflow {
    CRESIL_VISUALIZE(
        channel.of([ ['id':'test'], file("${moduleDir}/../testdata/eccDNA_final.txt") ]),
        channel.of([ ['id':'test'], file("${moduleDir}/../testdata/cresil_gAnnotation/gene.annotate.txt") ]),
        channel.of([ ['id':'test'], file("${moduleDir}/../testdata/cresil_gAnnotation/CpG.annotate.txt") ]),
        channel.of([ ['id':'test'], file("${moduleDir}/../testdata/cresil_gAnnotation/repeat.annotate.txt") ]),
        channel.of([ ['id':'test'], file("${moduleDir}/../testdata/cresil_gAnnotation/variant.annotate.txt") ]),
        'ec1'
    )
    CRESIL_VISUALIZE.out.circos_config.view()
}
