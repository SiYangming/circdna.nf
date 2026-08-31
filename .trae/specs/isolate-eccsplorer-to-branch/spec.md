# ECCsplorer 分支隔离与 Master 回退 Spec

## Why

当前 `circdna.nf` 的 `master` 分支已经混入大量 `ECCsplorer` 相关代码、配置、测试数据与规格文件，导致主线职责不清，也放大了与其他功能开发的冲突面。用户要求采用“选项 4”的方式，把所有 `ECCsplorer` 相关内容集中到现有 `ECCsplorer` 分支中构建，并让 `master` 回到“加入 ECCsplorer 之前”的状态。

## What Changes

- 将 `circdna.nf` 中所有 `ECCsplorer` 相关实现、配置、测试数据、样本表与规格迁移或保留到 `ECCsplorer` 分支
- 将 `master` 分支恢复为未接入 `ECCsplorer` 之前的状态
- 明确 `ECCsplorer` 分支是未来所有 `ECCsplorer` 模块化、参数迁移、`clu/all` 骨架与测试工作的唯一构建分支
- 将现有 `modularize-eccsplorer-modes` 的实施目标重新绑定到 `ECCsplorer` 分支执行，而不是继续污染 `master`
- 定义“哪些文件/目录属于 ECCsplorer 内容”，并据此制定主线回退边界
- 定义分支间的文件归属、版本策略、测试策略与验收路径

## Impact

- Affected specs:
  - `/Users/siyangming/nextflow_nf_core/.trae/specs/modularize-eccsplorer-modes`
  - `/Users/siyangming/nextflow_nf_core/.trae/specs/design-ngs-analysis-and-resume-real-test`
  - `/Users/siyangming/nextflow_nf_core/circdna.nf/.trae/specs/add-eccsplorer-database-and-control`
  - `/Users/siyangming/nextflow_nf_core/ECCsplorer/.trae/specs/build-eccsplorer-from-source-and-bam-support`
- Affected code:
  - `circdna.nf/modules/local/eccsplorer/`
  - `circdna.nf/modules/local/eccsplorer_*`
  - `circdna.nf/subworkflows/local/eccdna_mode/`
  - `circdna.nf/subworkflows/local/eccsplorer_*`
  - `circdna.nf/workflows/circdna.nf`
  - `circdna.nf/conf/modules.config`
  - `circdna.nf/conf/test_local.config`
  - `circdna.nf/conf/test_local_gdna.config`
  - `circdna.nf/conf/test_bam_local.config`
  - `circdna.nf/nextflow.config`
  - `circdna.nf/nextflow_schema.json`
  - `circdna.nf/modules.json`
  - `circdna.nf/samplesheets/` 中与 ECCsplorer 相关的测试样本表
  - `circdna.nf/testdatasets/` 中与 ECCsplorer 相关的数据库、注释与测试数据
  - `circdna.nf/.trae/specs/` 中与 ECCsplorer 相关的规格文档

## ADDED Requirements

### Requirement: ECCsplorer 必须独立在专用分支构建

系统 SHALL 将 `ECCsplorer` 相关功能的后续开发、模块化拆分、参数迁移、测试与数据准备全部限定在名为 `ECCsplorer` 的分支中进行。

#### Scenario: 分支作为唯一构建入口

- **WHEN** 需要继续开发或验证 `ECCsplorer`
- **THEN** 相关改动 SHALL 只发生在 `ECCsplorer` 分支
- **AND** `master` 不再承载新的 `ECCsplorer` 开发

#### Scenario: 现有模块化方案转移执行位置

- **WHEN** 执行 `modularize-eccsplorer-modes` 相关实施任务
- **THEN** 实施 SHALL 绑定到 `ECCsplorer` 分支
- **AND** 不得继续以 `master` 作为落地目标

### Requirement: 必须定义 ECCsplorer 内容归属范围

系统 SHALL 明确哪些文件和目录被视为 `ECCsplorer` 内容，以支持从 `master` 剥离并迁移到专用分支。

#### Scenario: 代码与流程层归属

- **WHEN** 判断某文件是否属于 `ECCsplorer` 内容
- **THEN** 以下内容 SHALL 视为 `ECCsplorer` 归属范围：
  - `modules/local/eccsplorer/`
  - `modules/local/eccsplorer_*`
  - `subworkflows/local/eccdna_mode/` 中与 ECCsplorer 直接相关的逻辑
  - `subworkflows/local/eccsplorer_*`
  - `workflows/circdna.nf` 中与 ECCsplorer 模式接线直接相关的逻辑
  - `conf/modules.config`、`nextflow.config`、`nextflow_schema.json` 中 ECCsplorer 相关参数与配置

#### Scenario: 数据与测试层归属

- **WHEN** 判断样本表、测试数据和脚本是否属于 `ECCsplorer` 内容
- **THEN** 以下内容 SHALL 视为 `ECCsplorer` 归属范围：
  - 专门服务于 ECCsplorer 的 `samplesheets/*eccdna*`、`*gdna*`、`*integrated*`、`*bam*`
  - `testdatasets/eccsplorer_db/`
  - 与 ECCsplorer 控制组、数据库准备、真实测试直接相关的脚本与配置

### Requirement: Master 必须回退到加入 ECCsplorer 前的状态

系统 SHALL 以“恢复主线非 ECCsplorer 状态”为目标处理 `master`，而不是仅仅停止继续开发。

#### Scenario: Master 主线回退

- **WHEN** 对 `master` 进行整理
- **THEN** 所有 `ECCsplorer` 相关模块、子工作流、参数、测试样本和数据 SHALL 从主线移除
- **AND** `master` 应恢复为未引入 ECCsplorer 前的可理解状态

#### Scenario: 保留非 ECCsplorer 能力

- **WHEN** 回退 `master`
- **THEN** 与 `Circle-Map`、`AmpliconArchitect`、其他原有流程无关的能力 SHALL 保持不受影响
- **AND** 不得因为剥离 ECCsplorer 而误删非相关功能

### Requirement: 分支间职责必须明确

系统 SHALL 为 `master` 与 `ECCsplorer` 分支定义清晰的职责边界。

#### Scenario: Master 的职责

- **WHEN** 用户使用 `master`
- **THEN** 它 SHALL 代表不含 ECCsplorer 的主线流程
- **AND** 其测试与文档 SHALL 不再依赖 ECCsplorer 相关输入

#### Scenario: ECCsplorer 分支的职责

- **WHEN** 用户使用 `ECCsplorer` 分支
- **THEN** 它 SHALL 包含所有 ECCsplorer 集成内容
- **AND** 未来的 `PRExer/map/clu/all-comparative` 模块化工作 SHALL 都在该分支继续

### Requirement: 规格与测试必须随分支归档

系统 SHALL 将 ECCsplorer 专属规格、测试与实现计划和其分支归属保持一致。

#### Scenario: 规格归属

- **WHEN** 某 `.trae/specs` 文档主要服务于 ECCsplorer
- **THEN** 该规格 SHALL 以 `ECCsplorer` 分支为实施目标
- **AND** 不应继续默认绑定 `master`

#### Scenario: 测试归属

- **WHEN** 运行 ECCsplorer 相关 `test_local`、数据库准备或控制组测试
- **THEN** 这些测试 SHALL 只在 `ECCsplorer` 分支验收

## MODIFIED Requirements

### Requirement: modularize-eccsplorer-modes 的实施目标

现有 `modularize-eccsplorer-modes` SHALL 从“直接在当前主线实施”修改为“只在 `ECCsplorer` 分支实施”。

#### Scenario: 模块化任务的执行位置

- **WHEN** 实施 `eccsplorer_input_normalize`、`eccsplorer_map_pipeline`、`clu` 骨架、`all/comparative` 骨架
- **THEN** 这些任务 SHALL 在 `ECCsplorer` 分支执行
- **AND** 不得以修改 `master` 为默认落点

### Requirement: test_local 真实测试范围

现有与 ECCsplorer 相关的 `test_local` / `-resume` 真实测试要求 SHALL 修改为只在 `ECCsplorer` 分支上执行与验收。

#### Scenario: 主线测试与分支测试分离

- **WHEN** 用户在 `master` 上运行测试
- **THEN** 不应要求 ECCsplorer 相关样本或数据库准备
- **AND** ECCsplorer 相关真实测试 SHALL 转移到 `ECCsplorer` 分支

## REMOVED Requirements

### Requirement: Master 继续承载 ECCsplorer 集成开发

**Reason**: 这会继续污染主线，并增加与其他流程开发的冲突面。
**Migration**: 将所有 ECCsplorer 相关实现、测试、参数和规格迁移到 `ECCsplorer` 分支；`master` 只保留非 ECCsplorer 主线。

### Requirement: 在 Master 上直接落地 modularize-eccsplorer-modes

**Reason**: 当前用户已明确选择“选项 4”，要求所有 ECCsplorer 内容在专用分支构建。
**Migration**: 将 `modularize-eccsplorer-modes` 的后续实现全部转移到 `ECCsplorer` 分支，并把 `master` 回退到 pre-ECCsplorer 状态。
