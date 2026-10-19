# 二代测序分析模块设计与 Resume 真实测试 Spec

## Why

`ecc_pipe-main与ECCsplorer整合迁移指南（全量整合版）.md` 已经明确了 `circdna.nf` 上游、`eccdna.smk` 下游的总体路线，但对“二代测序相关的分析模块”还停留在结构级描述，缺少可直接落地的模块边界、输入输出契约和验证顺序。

同时，现有真实测试规格主要验证 `test_local` 能否跑通，还没有把“利用 `-resume` 快速复测”定义为正式要求。为了后续实施不反复返工，需要把 NGS 分析模块设计与 `test_local` 真实验证策略一起规格化。

## What Changes

- 明确记录 `ECCsplorer` 的迁移现状，区分“已迁移部分”和“本次需继续完成的部分”
- 为二代测序主链补充一套可实现的分析模块设计，限定首期范围为：
  - `circdna.nf` 上游 NGS 检测与交接
  - `eccdna.smk` 下游 `score / standardize / distribution / deg / visualize`
- 明确 `circdna.nf -> eccdna.smk` 的交接契约，包括 `handoff.tsv` 与 `samples.auto.yaml` 的字段要求
- 明确 `eccdna.smk` 的 NGS 下游规则边界、脚本来源和阶段顺序
- 将 `test_local` 真实测试从“单次全量跑通”升级为“首轮真实跑通 + 后续利用 `-resume` 快速复测”
- 约束首期只覆盖二代测序主链，不把 `AA / CReSIL / FLED / ECCsplorer clu` 纳入本次验收

## Impact

- Affected specs:
  - `circdna.nf/.trae/specs/migrate-exploration-to-snakemake`
  - `circdna.nf/.trae/specs/verify-test-local-real-run`
  - `circdna.nf/.trae/specs/rename-samplesheets-and-real-test`
  - `circdna.nf/.trae/specs/add-eccsplorer-database-and-control`
  - `ECCsplorer/.trae/specs/build-eccsplorer-from-source-and-bam-support`
- Affected code:
  - `circdna.nf/workflows/circdna.nf`
  - `circdna.nf/subworkflows/local/eccdna_mode/main.nf`
  - `circdna.nf/subworkflows/local/input_check/main.nf`
  - `circdna.nf/modules/local/export_handoff/`
  - `circdna.nf/bin/export_handoff_manifest.py`
  - `circdna.nf/conf/test_local.config`
  - `eccdna.smk/Snakefile`
  - `eccdna.smk/config/config.yaml`
  - `eccdna.smk/config/samples.template.yaml`
  - `eccdna.smk/rules/score.smk`
  - `eccdna.smk/rules/standardize.smk`
  - `eccdna.smk/rules/distribution.smk`
  - `eccdna.smk/rules/deg.smk`
  - `eccdna.smk/rules/visualize.smk`
  - `eccdna.smk/scripts/python/*`
  - `eccdna.smk/scripts/r/*`

## ADDED Requirements

### Requirement: ECCsplorer 迁移现状必须显式化

系统 SHALL 在本次规格中显式区分 `ECCsplorer` 哪些能力已经迁移到当前主链，哪些能力仍然只是文档设计或后续范围，避免实现阶段误判范围。

#### Scenario: 已迁移能力

- **WHEN** 审查当前 `circdna.nf` 与相关已完成规格
- **THEN** 系统 SHALL 认定以下能力已经迁移到现有主链：
  - `map` 模式作为 `ECCSPLORER` / `ECCSPLORER_WITH_CONTROL` 模块接入 `eccdna` 主链
  - FASTQ / BAM 双输入支持
  - `gDNA control` 路由支持
  - `eccsplorer_database` 注释数据库参数支持
  - 关键 mapping 结果的输出映射（`*_candidates.bed`、`*_junction_reads.txt`、`*_eccpipe_results`）

#### Scenario: 未迁移能力

- **WHEN** 审查当前代码与整合指南
- **THEN** 系统 SHALL 认定以下能力尚未完成迁移：
  - `PRExer` 的独立迁移，仅保留为参数借鉴来源
  - `clu` 模式的子工作流拆分与接线
  - `all` / `comparative` 的 DAG 化重构
  - `ECCsplorer cluster` 结果并入 `handoff.tsv` / `samples.auto.yaml`
  - 围绕上述能力的 `test_local` 真实测试与 `-resume` 验证

### Requirement: 二代测序主链交接清单

系统 SHALL 在 `circdna.nf` 的 `eccdna` 模式末端导出一套供 `eccdna.smk` 直接消费的交接清单，而不是继续依赖手工维护样本路径。

#### Scenario: 导出 handoff 契约

- **WHEN** 用户执行 `circdna.nf` 的 `eccdna` 模式并完成 NGS 检测主链
- **THEN** 系统 SHALL 产出 `handoff.tsv`
- **AND** 系统 SHALL 同步产出 `samples.auto.yaml`
- **AND** 两个文件 SHALL 至少包含 `sample`、`group`、`genome`、`eccsplorer_bed`、`circle_map_bed`、`eccdna_mosdepth_bed`

#### Scenario: 控制组存在时导出 control 路径

- **WHEN** samplesheet 中存在 `gdna` 控制组并通过 `group` 与 eccDNA 样本成功配对
- **THEN** `samples.auto.yaml` SHALL 包含 `gdna_mosdepth_bed`
- **AND** 未配对的样本 SHALL 被显式标记，而不是静默省略

### Requirement: 二代测序下游分析模块分层

系统 SHALL 将二代测序下游分析拆分为可独立验证的 Snakemake 规则层，而不是继续维持单体脚本入口。

#### Scenario: 评分层

- **WHEN** `eccdna.smk` 读取 `samples.auto.yaml`
- **THEN** `rules/score.smk` SHALL 负责 `candidate_merge` 与 `ecc_score`
- **AND** 评分参数 SHALL 由 `config/config.yaml` 提供

#### Scenario: 标准化层

- **WHEN** 评分层完成或直接消费原始候选 BED
- **THEN** `rules/standardize.smk` SHALL 将 `ECCsplorer`、`Circle-Map`、`merged_scored` 统一转换为标准 analysis BED
- **AND** 列契约 SHALL 明确写入脚本与文档

#### Scenario: 单样本分布分析层

- **WHEN** 标准 analysis BED 可用
- **THEN** `rules/distribution.smk` SHALL 产出染色体分布、长度分布、HOMER 注释及可选数据库注释
- **AND** 这些能力 SHALL 只针对二代测序主链验收，不要求长读长输入

#### Scenario: 队列级差异分析层

- **WHEN** 多个样本的标准 analysis BED 与分组文件可用
- **THEN** `rules/deg.smk` SHALL 构建 burden matrix
- **AND** SHALL 调用参数化后的 `deseq2.R`、`edger.R`、`limma.R`、`clusterprofile.R`

#### Scenario: 可视化层

- **WHEN** 用户提供目标 `ecc_id` 或目标区域
- **THEN** `rules/visualize.smk` SHALL 生成 circlize/CIRCOS 结果

### Requirement: test_local 真实测试采用 Resume 复测策略

系统 SHALL 把 `test_local` 真实测试定义为“两段式验证”，即先完成一次真实上游运行，再在后续调整下游模块或验证结果时优先使用 `-resume` 快速复测。

#### Scenario: 首轮真实运行建立缓存

- **WHEN** 用户第一次执行 `nextflow run main.nf -profile test_local,docker --mode eccdna`
- **THEN** 流程 SHALL 在真实模式下运行
- **AND** 生成可用于后续 `-resume` 的 work 缓存

#### Scenario: Resume 快速复测

- **WHEN** 用户在不改变上游重计算输入的前提下再次执行 `nextflow run main.nf -profile test_local,docker --mode eccdna -resume`
- **THEN** 已完成的上游样本级任务 SHALL 尽可能显示为 `CACHED`
- **AND** 验证重点 SHALL 放在交接导出、下游接口和新增分析模块相关步骤

#### Scenario: 真实测试验收范围

- **WHEN** 本次规格完成实施并执行 `test_local` 真实测试
- **THEN** 首期验收 SHALL 以 `eccdna` 模式的二代测序主链为主
- **AND** 不要求同一轮验收中完成 `reference` 全链、`AA`、`CReSIL`、`FLED` 或 `ECCsplorer clu`

## MODIFIED Requirements

### Requirement: test_local 真实验证范围

现有真实测试要求 SHALL 修改为“优先围绕 `eccdna` 二代测序主链进行真实验证，并允许通过 `-resume` 快速复测迭代验证结果”，而不是默认要求每次都从零开始执行所有模式。

#### Scenario: 限定首期真实测试范围

- **WHEN** 用户执行本次变更对应的真实测试
- **THEN** SHALL 优先验证 `eccdna` 模式的二代测序主链
- **AND** `reference` 模式或其他扩展检测器不作为本次阻塞项

### Requirement: 探索性分析迁移后的下游目标

迁移后的 `eccdna.smk` SHALL 不再只承担 `candidate_merge + ecc_score` 的薄评分层职责，而是成为二代测序下游分析编排层。

#### Scenario: Snakemake 作为下游编排层

- **WHEN** 用户按照整合指南执行 NGS 主链
- **THEN** `eccdna.smk` SHALL 覆盖 `score -> standardize -> distribution -> deg -> visualize` 的完整下游阶段

## REMOVED Requirements

### Requirement: 每次真实验证都从零开始全量执行

**Reason**: 该策略不适合当前“上游重计算、下游轻分析”的分层架构，会显著降低调试与验证效率。
**Migration**: 首轮真实运行建立缓存后，后续验证统一优先采用 `-resume`，只在输入契约变化或缓存失效时重新全量运行。

### Requirement: 首期同时覆盖所有检测器与所有模式

**Reason**: 当前任务目标明确指向 `circdna.nf` 二代测序相关分析模块设计，若同时纳入长读长与扩展检测器会扩大范围并削弱可交付性。
**Migration**: `AA / CReSIL / FLED / ECCsplorer clu` 保持在后续扩展阶段，另行建变更或在后续规格中追加。
