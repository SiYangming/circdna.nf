# Checklist

- [x] `subworkflows/local/bam_preprocessing/main.nf` 中 `ch_fasta` 通过 `.first()` 转为 value channel
- [x] `subworkflows/local/bam_preprocessing/main.nf` 中 `ch_fasta_fai` 通过 `.first()` 转为 value channel
- [x] `subworkflows/local/bam_preprocessing/main.nf` 中 BAM_STATS_SAMTOOLS 接收 `ch_fasta_fai`（value channel）
- [x] `subworkflows/local/bam_preprocessing/main.nf` emit 中新增 `fai` 与 `fasta_fai`
- [x] `subworkflows/local/circle_finder_pipeline/main.nf` take 新增 `fasta_fai` 入参
- [x] `subworkflows/local/circle_finder_pipeline/main.nf` SAMTOOLS_SORT_QNAME_CF 使用 `ch_fasta_fai` 替代 `channel.empty()`
- [x] `subworkflows/local/circle_map_pipeline/main.nf` 入参 `fasta` 更名为 `fasta_fai`
- [x] `subworkflows/local/circle_map_pipeline/main.nf` SAMTOOLS_SORT_QNAME_CM 使用 `ch_fasta_fai`
- [x] `subworkflows/local/circle_map_pipeline/main.nf` SAMTOOLS_SORT_RE 使用 `ch_fasta_fai`
- [x] `subworkflows/local/circle_map_pipeline/main.nf` CIRCLEMAP_REALIGN fasta 路径从 `fasta_fai.map { meta, fasta, fai -> fasta }` 提取
- [x] `workflows/circdna.nf` 移除 `SAMTOOLS_FAIDX` import
- [x] `workflows/circdna.nf` AMPLICONARCHITECT_PIPELINE 使用 `BAM_PREPROCESSING.out.fasta_fai`
- [x] `workflows/circdna.nf` CIRCLE_FINDER_PIPELINE 传入 `BAM_PREPROCESSING.out.fasta_fai`
- [x] `workflows/circdna.nf` CIRCLE_MAP_PIPELINE 传入 `BAM_PREPROCESSING.out.fasta_fai`（替代 `ch_fasta`）
- [x] 修改保存于 master 分支
- [x] 使用 `conf/test_local.config` 验证：不启用 unicycler、docker、nextflow 直接运行、不使用 `-resume`
- [x] 一次性生成 `results_testdata` 中 circdna_1/2/3 全部样本结果
