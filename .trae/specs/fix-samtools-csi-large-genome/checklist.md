# Checklist

- [x] `conf/large_genome.config` 使用 `withName: '.*SAMTOOLS_INDEX.*'` 正则匹配，`ext.args = '-c'` 覆盖全部 SAMTOOLS_INDEX 实例
- [x] `SERVER_RUN_GUIDE.md` 中 Tragopogon_porrifolius hap1 命令包含 `-c circdna.nf/conf/large_genome.config` 并标注大基因组，hap2 保持不变
- [x] `SERVER_RUN_GUIDE.md` 注意事项"大基因组"列表包含 Tragopogon_porrifolius hap1
- [x] `README.md` 已添加大基因组物种附加 `-c conf/large_genome.config`（CSI 索引）的说明
- [x] `nextflow.config` manifest version 未被修改（仍为 4.4.1）
- [x] `CHANGELOG.md` 已在 v4.4.1 条目下追加本次修复记录
- [x] Git 提交仅包含本次大基因组相关文件（`conf/large_genome.config`、`SERVER_RUN_GUIDE.md`、`README.md`、`CHANGELOG.md`），其他无关更改未提交
