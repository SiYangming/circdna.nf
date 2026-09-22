# Checklist

- [ ] `subworkflows/local/eccdna_mode/main.nf` 第 50 行 `ch_eccsplorer_fasta` 不再调用 `.first()`
- [ ] `subworkflows/local/bam_preprocessing/main.nf` 第 39 行的 `.first()` 保持不变（作用于 queue channel，非冗余）
- [ ] `workflows/circdna.nf` 第 50 行的 `.first()` 保持不变（作用于 queue channel，非冗余）
- [ ] `workflows/circdna.nf` 第 81 行的 `.first()` 保持不变（test_local 不执行，且作用于 queue channel）
- [ ] CHANGELOG.md 已新增条目记录该修复
- [ ] 运行 `nextflow run main.nf -profile test_local,docker --outdir results_circdna_test_local_eccdna -resume` 后，日志中不出现 "The operator `first` is useless when applied to a value channel" 警告
- [ ] ECCSPLORER process 仍处理 3 of 3 样本（无 one-to-one 匹配退化）
