# Tasks

- [ ] Task 1: 移除 `eccdna_mode/main.nf` 中 `ch_eccsplorer_fasta` 上多余的 `.first()`
  - [ ] SubTask 1.1: 将 `subworkflows/local/eccdna_mode/main.nf` 第 50 行从 `fasta_meta.map { meta, fasta -> fasta }.first()` 改为 `fasta_meta.map { meta, fasta -> fasta }`
  - [ ] SubTask 1.2: 确认不修改其他任何 `.first()` 调用（`bam_preprocessing/main.nf:39`、`workflows/circdna.nf:50/81`）
- [ ] Task 2: 更新 CHANGELOG.md
  - [ ] SubTask 2.1: 在当前 dev 版本下新增 PATCH 条目，记录移除冗余 `.first()` 操作符
- [ ] Task 3: 验证修复
  - [ ] SubTask 3.1: 运行 `nextflow run main.nf -profile test_local,docker --outdir results_circdna_test_local_eccdna -resume`，确认警告消失
  - [ ] SubTask 3.2: 确认 ECCSPLORER process 仍处理所有样本（3 of 3），无 one-to-one 匹配问题

# Task Dependencies

- [Task 3] 依赖 [Task 1] 和 [Task 2]
