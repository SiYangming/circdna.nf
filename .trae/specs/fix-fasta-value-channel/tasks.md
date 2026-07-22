# Tasks

- [x] Task 1: 修复 `subworkflows/local/bam_preprocessing/main.nf` 通道类型
  - [x] SubTask 1.1: 将 `ch_fasta` 定义为 `SAMTOOLS_FAIDX.out.fa.first()`（value channel）
  - [x] SubTask 1.2: 将 `ch_fasta_fai` 定义为 `SAMTOOLS_FAIDX.out.fa.join(SAMTOOLS_FAIDX.out.fai).map { meta, fasta, fai -> [meta, fasta, fai] }.first()`（value channel）
  - [x] SubTask 1.3: BAM_STATS_SAMTOOLS 入参由 `ch_fasta_fai` 改为 `ch_fasta`
  - [x] SubTask 1.4: 在 emit 中新增 `fai = SAMTOOLS_FAIDX.out.fai.first()` 与 `fasta_fai = ch_fasta_fai`

- [x] Task 2: 修复 `subworkflows/local/circle_finder_pipeline/main.nf`
  - [x] SubTask 2.1: 在 take 中新增 `fasta_fai` 入参（value channel `[meta, fasta, fai]`）
  - [x] SubTask 2.2: 定义 `def ch_fasta_fai = fasta_fai`，并将 SAMTOOLS_SORT_QNAME_CF 的第二个入参由 `channel.empty()` 改为 `ch_fasta_fai`

- [x] Task 3: 修复 `subworkflows/local/circle_map_pipeline/main.nf`
  - [x] SubTask 3.1: 将 take 中的 `fasta` 入参更名为 `fasta_fai`（value channel `[meta, fasta, fai]`）
  - [x] SubTask 3.2: 定义 `def ch_fasta_fai = fasta_fai`
  - [x] SubTask 3.3: SAMTOOLS_SORT_QNAME_CM 第二个入参由 `channel.empty()` 改为 `ch_fasta_fai`
  - [x] SubTask 3.4: SAMTOOLS_SORT_RE 第二个入参由 `channel.empty()` 改为 `ch_fasta_fai`
  - [x] SubTask 3.5: CIRCLEMAP_REALIGN 的第二个入参由 `fasta` 改为 `fasta_fai.map { meta, fasta, fai -> fasta }`

- [x] Task 4: 修复 `workflows/circdna.nf` 主流程调用
  - [x] SubTask 4.1: 移除 `include { SAMTOOLS_FAIDX ... }` import 行
  - [x] SubTask 4.2: AMPLICONARCHITECT_PIPELINE 调用中，将 `ch_fasta_meta.join(SAMTOOLS_FAIDX.out.fai)` 替换为 `BAM_PREPROCESSING.out.fasta_fai`
  - [x] SubTask 4.3: CIRCLE_FINDER_PIPELINE 调用新增第 5 个参数 `BAM_PREPROCESSING.out.fasta_fai`
  - [x] SubTask 4.4: CIRCLE_MAP_PIPELINE 调用中，将 `ch_fasta` 替换为 `BAM_PREPROCESSING.out.fasta_fai`

- [x] Task 5: 使用 `conf/test_local.config` 验证流程（不启用 unicycler，docker，nextflow 直接运行）
  - [x] SubTask 5.1: 确认当前在 master 分支
  - [x] SubTask 5.2: 运行 `nextflow run main.nf -c conf/test_local.config -profile docker --skip_unicycler`（或通过 circle_identifier 不含 unicycler 的方式跳过组装），不使用 `-resume`
  - [x] SubTask 5.3: 确认一次性生成 `results_testdata` 中 circdna_1/2/3 全部样本结果（73 tasks, 0 failed, 9m43s）

# Task Dependencies
- [Task 2], [Task 3] 依赖 [Task 1]（需 BAM_PREPROCESSING 产出 fasta_fai emit）
- [Task 4] 依赖 [Task 1], [Task 2], [Task 3]（调用签名需先对齐）
- [Task 5] 依赖 [Task 1], [Task 2], [Task 3], [Task 4] 全部完成
