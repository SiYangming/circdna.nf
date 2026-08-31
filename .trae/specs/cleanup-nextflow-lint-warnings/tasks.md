# Tasks

- [x] Task 1: 修改 4 个 subworkflow 文件消除 lint 警告
  - [ ] SubTask 1.1: `subworkflows/local/circle_map_pipeline/main.nf` — 删除第 46 行 `ch_qname_sorted_bai = SAMTOOLS_SORT_QNAME_CM.out.index`（未使用变量）
  - [ ] SubTask 1.2: `subworkflows/local/eccdna_mode/main.nf` — 第 39 行 `.map { meta, fai -> fai }` → `.map { _meta, fai -> fai }`
  - [ ] SubTask 1.3: `subworkflows/local/eccdna_mode/main.nf` — 第 50 行 `.map { meta, fasta -> fasta }` → `.map { _meta, fasta -> fasta }`
  - [ ] SubTask 1.4: `subworkflows/local/input_check/main.nf` — 第 12、16、20 行 `Channel.fromPath` → `channel.fromPath`（3 处）
  - [ ] SubTask 1.5: `subworkflows/local/reference_mode/main.nf` — 第 14 行 take 参数 `repeat_gff` → `_repeat_gff`
  - [ ] SubTask 1.6: `subworkflows/local/reference_mode/main.nf` — 第 31 行 `.map { meta, fai -> fai }` → `.map { _meta, fai -> fai }`
- [x] Task 2: 更新 CHANGELOG.md 与 nextflow.config 版本号
  - [ ] SubTask 2.1: CHANGELOG.md 顶部新增 v4.2.3 条目（PATCH），描述 lint 警告清理
  - [ ] SubTask 2.2: nextflow.config manifest.version `4.2.2` → `4.2.3`
- [x] Task 3: 验证 lint 警告消除与 pipeline 运行不受影响
  - [ ] SubTask 3.1: 运行 `nextflow lint .`，确认 8 条警告全部消失
  - [ ] SubTask 3.2: 运行 `nextflow run main.nf -profile test_local,docker --mode eccdna -resume`，确认 Pipeline 正常完成且 ECCSPLORER 处理 3 of 3 样本

# Task Dependencies

- [Task 3] depends on [Task 1] and [Task 2]
