# Checklist

- [ ] 已明确 `ECCsplorer` 已迁移能力：`map`
- [ ] 已明确 `ECCsplorer` 已迁移能力：FASTQ / BAM 双输入
- [ ] 已明确 `ECCsplorer` 已迁移能力：`gDNA control`
- [ ] 已明确 `ECCsplorer` 已迁移能力：数据库参数支持
- [ ] 已明确 `ECCsplorer` 已迁移能力：mapping 输出映射

- [ ] 已明确 `ECCsplorer` 未迁移能力：`PRExer`
- [ ] 已明确 `ECCsplorer` 未迁移能力：`clu`
- [ ] 已明确 `ECCsplorer` 未迁移能力：`all / comparative`
- [ ] 已明确 `ECCsplorer` 未迁移能力：cluster 结果交接与真实测试

- [ ] 已定义 `circdna.nf -> eccdna.smk` 的 `handoff.tsv` 字段契约
- [ ] 已定义 `circdna.nf -> eccdna.smk` 的 `samples.auto.yaml` 字段契约
- [ ] 已明确 `group`、`data_type`、control 配对与未配对样本的处理规则

- [ ] `eccdna.smk` 已定义 `score.smk`
- [ ] `eccdna.smk` 已定义 `standardize.smk`
- [ ] `eccdna.smk` 已定义 `distribution.smk`
- [ ] `eccdna.smk` 已定义 `deg.smk`
- [ ] `eccdna.smk` 已定义 `visualize.smk`

- [ ] 已明确标准 analysis BED 的列定义与输入输出路径
- [ ] 已明确 `Distribution.py` 迁移后的脚本边界
- [ ] 已明确 `DEG.py` 迁移后的脚本边界
- [ ] 已明确 `circlize.R` 相关可视化入口边界

- [ ] `test_local` 真实测试范围已限定为二代测序 `eccdna` 主链
- [ ] 已定义首轮真实运行命令与输出目录
- [ ] 已定义 `-resume` 快速复测命令与前提条件
- [ ] 已定义 `-resume` 复测时需要重点检查的 `CACHED` 任务范围

- [ ] 已定义真实测试后的关键产出检查项：`eccsplorer`
- [ ] 已定义真实测试后的关键产出检查项：`circlemap`
- [ ] 已定义真实测试后的关键产出检查项：`mosdepth`
- [ ] 已定义真实测试后的关键产出检查项：交接文件
- [ ] 已定义 `samples.auto.yaml` 驱动 `snakemake -n` 的最小验收条件

- [ ] 已明确本次不纳入首期验收的范围：`reference` 全链
- [ ] 已明确本次不纳入首期验收的范围：`AA / CReSIL / FLED`
- [ ] 已明确本次不纳入首期验收的范围：`ECCsplorer clu`
