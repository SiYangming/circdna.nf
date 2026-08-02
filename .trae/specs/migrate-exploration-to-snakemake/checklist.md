# Checklist

## eccdna.smk Snakemake 仓库

- [x] `eccdna.smk/` 目录已创建，包含 `Snakefile`, `config/`, `scripts/`, `environment.yml`, `README.md`, `.gitignore`
- [x] `scripts/merge_candidates.py` 内容与原 `circdna.nf/bin/merge_candidates.py` 一致
- [x] `scripts/calculate_ecc_score.py` 内容与原 `circdna.nf/bin/calculate_ecc_score.py` 一致
- [x] `Snakefile` 包含 `rule all`, `rule candidate_merge`, `rule ecc_score` 三个规则
- [x] `config/config.yaml` 包含 `w1`, `w2`, `w3`, `max_distance`, `nextflow_outdir` 等参数
- [x] `config/samples.yaml` 提供样本配置模板（gdna + eccdna 样本列表）
- [x] `environment.yml` 定义 Python >= 3.10 依赖
- [x] `README.md` 说明使用方法、契约接口路径、参数说明
- [x] Snakemake 工作流语法验证通过（`snakemake -n` 或 `snakemake --lint`）
- [ ] GitHub 仓库 `SiYangming/eccdna.smk` 已创建并推送（**阻塞：需用户手动创建仓库或重新授权 GitHub MCP**）

## circdna.nf Nextflow 修改

### 模块删除

- [x] `modules/local/candidate_merge/` 目录已删除
- [x] `modules/local/ecc_score/` 目录已删除
- [x] `subworkflows/local/integrated_mode/` 目录已删除
- [x] `bin/merge_candidates.py` 已删除（已迁移至 eccdna.smk）
- [x] `bin/calculate_ecc_score.py` 已删除（已迁移至 eccdna.smk）

### 工作流修改

- [x] `subworkflows/local/eccdna_mode/main.nf` 已移除 `include { CANDIDATE_MERGE }` 行
- [x] `subworkflows/local/eccdna_mode/main.nf` 已移除 `ch_merge_input` 定义和 `CANDIDATE_MERGE(ch_merge_input)` 调用
- [x] `subworkflows/local/eccdna_mode/main.nf` 已移除 `merged_bed = CANDIDATE_MERGE.out.merged_bed` emit
- [x] `subworkflows/local/eccdna_mode/main.nf` 仍保留 `eccsplorer_bed` 和 `circle_map_bed` emit（作为契约接口）
- [x] `workflows/circdna.nf` 已移除 `INTEGRATED_MODE` include（如有）
- [x] `workflows/circdna.nf` 已移除 `else if (params.mode == 'integrated')` 整个分支
- [x] `workflows/circdna.nf` 已从 `valid_modes` 列表中移除 `'integrated'`
- [x] `workflows/circdna.nf` 中 `integrated` 相关的 `ch_mosdepth_multiqc` 处理已移除

### 配置修改

- [x] `nextflow.config` 中 `ecc_score_w1`, `ecc_score_w2`, `ecc_score_w3` 三个参数已移除
- [x] `nextflow.config` manifest `version = '4.0.0'`（原 3.2.1）
- [x] `nextflow.config` 中 `mode` 参数注释已更新（仅 reference, eccdna）
- [x] `nextflow.config` profiles 块中 `test_integrated` profile 引用已移除
- [x] `conf/test_integrated.config` 文件已删除
- [x] `conf/modules.config` 中 CANDIDATE_MERGE/ECC_SCORE 相关配置已移除（如有）
- [x] `conf/test_local.config` 中 ecc_score_w1/w2/w3 配置已移除（如有）
- [x] `nextflow_schema.json` 已通过 `nf-core schema build` 重新生成
- [x] `modules.json` 中 candidate_merge/ecc_score 引用已移除（如有）

### CHANGELOG 与版本

- [x] `CHANGELOG.md` 顶部新增 `## v4.0.0 - [2026-08-02]` 条目
- [x] CHANGELOG v4.0.0 条目标注 BREAKING CHANGES
- [x] CHANGELOG 描述 integrated 模式移除、CANDIDATE_MERGE/ECC_SCORE 迁移至 eccdna.smk
- [x] CHANGELOG 包含迁移路径说明（用户应使用 eccdna.smk 仓库）

## 验证

- [x] reference 模式可正常启动（`nextflow run main.nf -profile test_local,docker --mode reference -stub-run` 成功启动，SAMPLESHEET_CHECK → BWA_INDEX → REFERENCE_MODE 路由正确）
- [x] eccdna 模式可正常启动（`nextflow run main.nf -profile test_local,docker --mode eccdna -stub-run` 成功启动，ECCDNA_MODE → ECCSPLORER → CIRCLEMAP 路由正确，无 CANDIDATE_MERGE/ECC_SCORE 步骤）
- [x] integrated 模式被正确拒绝（`nextflow run main.nf -profile test_local --mode integrated` 因 mode 验证失败而退出）
- [x] eccdna 模式不再产出 `merged_bed`（仅产出 eccsplorer_bed + circle_map_bed）— 代码审查 + stub-run 确认
- [x] `nf-core lint` — 跳过（nf-core 3.5.2 在 Python 3.14 环境下有 `pipelines_lint() missing 'plain_text'` bug）

### 已知问题（非阻塞）

- `docker.userEmulation` 配置在 Nextflow 26.04.6+ 不再支持（WARN: Config setting `docker.userEmulation` is not supported anymore）。A 层（`docker.runOptions = '-u $(id -u):$(id -g)'`）和 C 层（`docker.fixOwnership = true`）仍然有效，权限映射功能不受影响。后续可在新版本中移除 B 层配置。

## GitHub 提交

- [x] circdna.nf 已 `git commit`，提交信息为 `release: v4.0.0 — migrate CANDIDATE_MERGE and ECC_SCORE to eccdna.smk`（commit 7c01758）
- [x] circdna.nf 已 `git tag -a v4.0.0`
- [x] circdna.nf 已 `git push origin master --tags` 推送至 GitHub（成功）
- [ ] eccdna.smk 已初始化 git 并推送至 GitHub `SiYangming/eccdna.smk`（**阻塞：仓库尚未创建**）

## .trae 文档组织

- [x] 根目录 `.trae/documents/` 仅保留跨流程文档（`fix-docker-permission.md`）
- [x] `circdna.nf/.trae/documents/` 包含 circdna 专属文档（5 个文档已归位）
- [x] `.trae/specs/migrate-exploration-to-snakemake/` spec 文档已创建并随 v4.0.0 提交
