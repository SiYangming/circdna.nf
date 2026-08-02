# Checklist

## eccdna.smk Snakemake 仓库

- [ ] `eccdna.smk/` 目录已创建，包含 `Snakefile`, `config/`, `scripts/`, `environment.yml`, `README.md`, `.gitignore`
- [ ] `scripts/merge_candidates.py` 内容与原 `circdna.nf/bin/merge_candidates.py` 一致
- [ ] `scripts/calculate_ecc_score.py` 内容与原 `circdna.nf/bin/calculate_ecc_score.py` 一致
- [ ] `Snakefile` 包含 `rule all`, `rule candidate_merge`, `rule ecc_score` 三个规则
- [ ] `config/config.yaml` 包含 `w1`, `w2`, `w3`, `max_distance`, `nextflow_outdir` 等参数
- [ ] `config/samples.yaml` 提供样本配置模板（gdna + eccdna 样本列表）
- [ ] `environment.yml` 定义 Python >= 3.10 依赖
- [ ] `README.md` 说明使用方法、契约接口路径、参数说明
- [ ] Snakemake 工作流语法验证通过（`snakemake -n` 或 `snakemake --lint`）
- [ ] GitHub 仓库 `SiYangming/eccdna.smk` 已创建并推送

## circdna.nf Nextflow 修改

### 模块删除

- [ ] `modules/local/candidate_merge/` 目录已删除
- [ ] `modules/local/ecc_score/` 目录已删除
- [ ] `subworkflows/local/integrated_mode/` 目录已删除
- [ ] `bin/merge_candidates.py` 已删除（已迁移至 eccdna.smk）
- [ ] `bin/calculate_ecc_score.py` 已删除（已迁移至 eccdna.smk）

### 工作流修改

- [ ] `subworkflows/local/eccdna_mode/main.nf` 已移除 `include { CANDIDATE_MERGE }` 行
- [ ] `subworkflows/local/eccdna_mode/main.nf` 已移除 `ch_merge_input` 定义和 `CANDIDATE_MERGE(ch_merge_input)` 调用
- [ ] `subworkflows/local/eccdna_mode/main.nf` 已移除 `merged_bed = CANDIDATE_MERGE.out.merged_bed` emit
- [ ] `subworkflows/local/eccdna_mode/main.nf` 仍保留 `eccsplorer_bed` 和 `circle_map_bed` emit（作为契约接口）
- [ ] `workflows/circdna.nf` 已移除 `INTEGRATED_MODE` include（如有）
- [ ] `workflows/circdna.nf` 已移除 `else if (params.mode == 'integrated')` 整个分支
- [ ] `workflows/circdna.nf` 已从 `valid_modes` 列表中移除 `'integrated'`
- [ ] `workflows/circdna.nf` 中 `integrated` 相关的 `ch_mosdepth_multiqc` 处理已移除

### 配置修改

- [ ] `nextflow.config` 中 `ecc_score_w1`, `ecc_score_w2`, `ecc_score_w3` 三个参数已移除
- [ ] `nextflow.config` manifest `version = '4.0.0'`（原 3.2.1）
- [ ] `nextflow.config` 中 `mode` 参数注释已更新（仅 reference, eccdna）
- [ ] `nextflow.config` profiles 块中 `test_integrated` profile 引用已移除
- [ ] `conf/test_integrated.config` 文件已删除
- [ ] `conf/modules.config` 中 CANDIDATE_MERGE/ECC_SCORE 相关配置已移除（如有）
- [ ] `conf/test_local.config` 中 ecc_score_w1/w2/w3 配置已移除（如有）
- [ ] `nextflow_schema.json` 已通过 `nf-core schema build` 重新生成
- [ ] `modules.json` 中 candidate_merge/ecc_score 引用已移除（如有）

### CHANGELOG 与版本

- [ ] `CHANGELOG.md` 顶部新增 `## v4.0.0 - [2026-08-02]` 条目
- [ ] CHANGELOG v4.0.0 条目标注 BREAKING CHANGES
- [ ] CHANGELOG 描述 integrated 模式移除、CANDIDATE_MERGE/ECC_SCORE 迁移至 eccdna.smk
- [ ] CHANGELOG 包含迁移路径说明（用户应使用 eccdna.smk 仓库）

## 验证

- [ ] reference 模式可正常启动（`nextflow run main.nf -profile test_local --mode reference` 不报错）
- [ ] eccdna 模式可正常启动（`nextflow run main.nf -profile test_local --mode eccdna` 不报错）
- [ ] integrated 模式被正确拒绝（`nextflow run main.nf -profile test_local --mode integrated` 因 mode 验证失败而退出）
- [ ] eccdna 模式不再产出 `merged_bed`（仅产出 eccsplorer_bed + circle_map_bed）
- [ ] `nf-core lint` 无致命错误

## GitHub 提交

- [ ] circdna.nf 已 `git commit`，提交信息为 `release: v4.0.0 — migrate CANDIDATE_MERGE and ECC_SCORE to eccdna.smk`
- [ ] circdna.nf 已 `git tag -a v4.0.0`
- [ ] circdna.nf 已 `git push origin master --tags` 推送至 GitHub
- [ ] eccdna.smk 已初始化 git 并推送至 GitHub `SiYangming/eccdna.smk`
