# nf-core/circdna: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v3.2.0 - [2026-07-24]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **Phase 0 Bug 修复**: 修复 v3.1.0 遗留的 5 个 bug，确保长读流程基础稳定性
  - 修复 `FLED_PIPELINE` 输入不匹配问题：`LONG_READ_MAPPING` emit 为 2 元组（无 bai），但 `FLED_PIPELINE` take 声明为 3 元组；新增 `SAMTOOLS_INDEX` 调用并 join 合并 bam+bai 为 3 元组
  - 修复 `FLYE_PIPELINE` ext.args 设置方式不生效问题：DSL2 中 `.ext.args` 在输出 channel 上设置无效，改由 `conf/modules.config` 中 `withName: 'FLYE'` 设置
  - 修复 `LONG_READ_FILTERING` 未实现 min_read_support 过滤问题：schema 定义了参数但代码中仅实现 blacklist + repeats 过滤
  - 新增长读测试配置 `conf/test_pacbio_lr.config` 和 `conf/test_nanopore_lr.config`，本地化测试数据
  - 修复主流程长读分支 minimap2 preset 切换：`conf/modules.config` 中 `MINIMAP2_ALIGN.ext.args` 改为依据 `meta.platform` 切换 `-ax map-hifi` / `-ax map-ont`
- **ecc_finder 第四引擎集成**: 新增 ecc_finder 作为第四种 eccDNA 检测引擎，支持 mapping-based（map）和 assembly-based（asm）两种模式
  - 模块来源：bio.nf 新建分支构建 4 个子模块（map_ont/map_sr/asm_ont/asm_sr），复制到 `modules/local/ecc_finder/`
  - 容器：`quay.io/bioinfortools/ecc_finder:1.0.0`（自构建上传）
  - 新增 `ECCFINDER_PIPELINE` 子流程，依据 `--eccfinder_mode`（map|asm|both）和 `--protocol`（pacbio/ont）选择子模块
  - 新增 `--eccfinder_mode` 参数及 schema 定义
- **NanoPlot QC 集成**: 在 `LONG_READ_PREPROCESSING` 子流程中集成 NanoPlot QC，对 PacBio 和 ONT 长读数据进行质量控制
- **Schema 修复**: 
  - 移除 `circle_identifier` 必填约束（长读模式下非必填）
  - 新增 `eccfinder_mode` schema 定义（enum: map/asm/both）
  - 更新 `long_read_identifier` 默认值包含 `eccfinder`
- **测试验证**: PacBio 和 Nanopore 长读 stub 测试均通过（`test_pacbio_lr` / `test_nanopore_lr` profile）
- **资源限制**: 测试配置中添加 `process_high`/`process_medium`/`process_low` 资源上限，适配本地测试环境
- **base.config 资源分配**: 为 13 个长读分析模块新增 `withName` 资源覆盖（PBCCS/LIMA/CHOPPER/PYCHOPPER/CRESIL_*/FLED/FLYE/ECC_FINDER_*/NANOPLOT/FILTER_ECCDNA_BY_SUPPORT）
- **临时文件清理**: 删除 `genome.txt`、`program.txt`、`scripts/err` 等临时捕获文件，更新 `.gitignore` 防止再次跟踪
- **Git 同步（Rebase）**: 将 circdnalr 分支 rebase 到远程最新版本，合入 7 个远程提交（短读 Bug 修复 + master 合并），保持线性历史
  - 合入 `153c4f4`: 修复 CIRCLE_FINDER_PIPELINE / CIRCLE_MAP_PIPELINE 结果不完整问题
  - 合入 `114cf9c`: 修复单样本处理问题
  - 合入 `8000897`: 将 fasta/fai 转换为 value channel 并传播到下游子流程
  - 合入 `4fc4571`: 合并 master（test_local.config 调整）
  - 合入 `6401fa4`: 更新 server guide 和 report 文件路径（来自 master）
  - 合入 `df389ad`: 合并 master 到 circdnalr
  - 合入 `3706645`: 远程版 v3.1.0 长读流程（与本地版内容等价）

## v3.1.0 - [2026-07-20]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **三代长读长 eccDNA 分析流程**: 在 circdna.nf 中集成 PacBio / ONT 长读长 eccDNA 分析，参考 nanoseq.nf 使用 `--protocol` 参数区分二代/三代，参考 isoseq.nf 使用 `--entrypoint` 参数控制预处理深度
- **三引擎分析**: 新增 CReSIL（mapping）、FLED（mapping）、Flye（assembly）三种长读长 eccDNA 鉴定引擎，可通过 `--long_read_identifier` 组合启用
- **平台特异性预处理**: PacBio 分支支持 PBCCS + LIMA；ONT 分支支持 CHOPPER + PYCHOPPER；默认以清洗后的 FASTQ 为入口，支持多级 entrypoint 回退到原始数据
- **结果收敛与过滤**: 新增长读结果过滤子流程，支持 blacklist/repeats 区域去除及最小 read support 过滤，统一输出标准 BED
- **模块管理**: nf-core 已有模块（pbccs/lima/chopper/pychopper/flye/minimap2）直接安装使用；CReSIL 从 bio.nf 复制到 modules/local；FLED 在 bio.nf 新建模块后复制到 modules/local
- **容器策略**: 优先使用 nf-core/biocontainers；FLED 容器在缺失时自行构建并上传至 quay.io/bioinfortools 和 anaconda.org/yangmingsi
- **参数扩展**: 新增 `protocol`、`entrypoint`、`primers`、`long_read_identifier`、`min_read_support`、`blacklist_bed`、`repeats_bed`、`save_long_read_intermediate`、`skip_long_read_qc` 等参数
- **样本表兼容**: 扩展样本表校验，支持长读样本表 `sample,fastq_1` 格式及可选 `input_bam` 列
- **文档与记录**: 所有变更同步记录于 CHANGELOG.md 与 CHANGES&FIX/20260720.md
- **技术实现**:
  - 重构主流程 `workflows/circdna.nf`，将长读分析独立于短读分析，避免重复调用 INPUT_CHECK
  - 修复 `input_check` 子流程中 SAMPLESHEET_CHECK 重复调用问题
  - 修复 `long_read_preprocessing` 子流程中 LIMA 重复调用问题，合并 lima_hifi 和 lima_fastq 分支
  - 修复 `long_read_mapping` 子流程中 MINIMAP2_ALIGN 和 SAMTOOLS_SORT 参数传递问题，使用 channel.value() 包装常量值
  - 修复 `fled_pipeline` 子流程中参数传递问题，将 tuple 拆分为独立 channel
  - 修复 `cresil_pipeline` 子流程中 channel.value() 使用问题，改为 channel.from()
  - 修复主流程中 MultiQC 相关 channel 未初始化问题，在流程开始时初始化所有空 channel
  - 修复 help 信息中 `paramsHelp()` 函数解析命令字符串失败问题，移除该调用

## v3.0.0 - [2026-07-14]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **物种扩展**: 补充 Beta_vulgaris、Lycium_ruthenicum 等新物种，共支持 15 个物种（Alopecurus_myosuroides、Amaranthus_palmeri、Arabidopsis_thaliana、Artemisia_annua、Beta_vulgaris、Cryptomeria_japonica、Cynodon_dactylon、Daucus_carota、Helianthus_annuus、Lycium_ruthenicum、Nicotiana_benthamiana、Oryza_sativa、Solanum_lycopersicum、Tragopogon_porrifolius、Triticum_aestivum）
- **样本表标准化**: 分离二代和三代数据，创建 circdna_xxx_eccDNA.csv（二代）和 circdnalr_xxx_long_read.csv（三代）样本表，总样本表包含 272 个二代样本和 141 个三代样本
- **--genome 参数支持**: 修复 workflow 逻辑，支持通过 `--genome` 参数自动获取 fasta 路径，无需手动指定 `--fasta`
- **SRA 转换优化**: 改进 `convert_sra_to_fastq_parallel.sh` 脚本，添加 sra.completed 完成标记文件、sra.broken 损坏文件记录、vdb-validate 完整性验证、内存限制（--mem 10G）、降低并发数、终极保底转换函数
- **基因组格式统一**: 统一使用 bgzip 压缩格式（.bgz），更新所有基因组路径和配置文件
- **配置优化**: 更新 server.config 添加所有物种基因组配置，添加 trace.overwrite 配置；更新 nextflow_schema.json 添加隐藏参数并修复 --fasta 验证
- **文档更新**: 更新 SERVER_RUN_GUIDE.md，添加 --genome 参数使用方式和批量运行脚本

## v2.0.0 - [2026-06-30]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **MultiQC 报告优化**: 借鉴 riboseq.nf 的处理方式，改进报告生成逻辑，报告内容更丰富
- **删除废弃模块**: 移除已废弃的 `CUSTOM_DUMPSOFTWAREVERSIONS` 模块（功能由 `softwareVersionsToYAML()` 替代）
- **离线配置加载修复**: 使用 `/dev/null` 替代不存在的 `empty.config`，支持本地路径配置
- **iGenomes 配置修复**: 添加 `igenomes_ignored.config` 文件，修复 ignore 模式下的配置加载
- **添加 arm64 和 emulate_amd64 profile**: 支持 Apple Silicon 原生运行和 x86_64 模拟
- **添加 gpu 和 wave profile**: 支持 GPU 加速和 Wave 容器自动构建
- **更新插件版本**: `nf-validation@1.1.3` → `nf-schema@2.5.1`
- **时间戳文件名**: timeline/report/trace/dag 文件添加时间戳后缀，避免覆盖
- **安全加固**: `process.shell` 添加 `-C` 选项，禁止输出重定向覆盖文件
- **补齐 charliecloud registry**: 添加所有容器引擎的默认 registry 配置
- **添加 CNVkit 模块**: 添加 `nf-core/cnvkit/batch` 和 `nf-core/cnvkit/segment` 模块，支持 WGS 数据分析
- **SE 数据支持**: 添加单端测序数据支持，samplesheet 解析和各模块均已适配
- **子工作流拆分**: 将主工作流拆分为 5 个模块化子工作流（`bam_preprocessing`、`circle_map_pipeline`、`circle_finder_pipeline`、`ampliconarchitect_pipeline`、`unicycler_pipeline`）

### Dependencies

- MultiQC: 1.18/1.19 → 1.35
- BWA: 0.7.17 → 0.7.19
- Samtools: 1.16.1/1.18 → 1.22.1/1.23.1
- CNVkit: 0.9.9 → 0.9.13

## v1.1.0 - [2024-02-03]

### Credits

Special thanks to the following for their input and contributions to the release:

- [Jens Luebeck](https://github.com/jluebeck)
- [Simon Pearce](https://github.com/SPPearce)
- [Maxime U Garcia](https://github.com/maxulysse)
- [Alex M. Ascensión](https://github.com/alexmascension)

### Enhancements & fixes

- Nf-core template update to 2.11.1
  - update of nf-core modules versions
- Removed AmpliconArchitect and AmpliconClassifier modules with their respective scripts in /bin
  - AmpliconArchitect and AmpliconClassifier is now run inside the AmpliconSuite-Pipeline. Additional scripts are not necessary.
  - Removed respective configs and workflow code
- Added AmpliconSuite-Pipeline
  - A wrapper for calling copy numbers, preparing amplified intervals, running AmpliconArchitect, and calling amplicon classes using AmpliconClassifier
  - Added docker container named [PrepareAA](https://quay.iorepository/nf-core/prepareaa?tab=tags) to run AmpliconSuite-Pipeline with singualarity or docker
  - Added module configs and description
- Changed `assets/multiqc_config.yml`to fit new pipeline version
- Included directory checks for `mosek_license_dir` and `aa_data_repo` .
  - Removed both directory parameters in the test profile as it is only checked when running `ampliconarchitect`
- Updated `nextflow_schema.json` to give better details about how to use `--circle_identifier`
- made `--circle_identifier` an essential parameter
- made `--input_format` an essential parameter and removed the default value to request specification by user
- Updated `--bwa_index` to accept only directory paths to the bwa index files. Makes the user input easier to not need to deal with file endings and patterns. Bug identified by [Alex M. Ascensión](https://github.com/alexmascension) in <https://github.com/nf-core/circdna/issues/68>

## v1.0.4 - [2023-06-26]

### `Added`

### `Fixed`

- Bug that the pipeline only runs with one sample when Picard Markduplicates is used

### `Dependencies`

### `Deprecated`

## v1.0.3 - [2023-05-26]

### `Added`

- Licence, contact, source information for AmpliconArchitect and PrepareAA python scripts
- documentation about absolute path needed of AmpliconArchitect data repository
- ampliconclassifier stub run tests
- new version of circdna metromap with updated colors
- note that ATAC-seq should be used in caution with the pipeline.
- build docker container for prepareaa -> Needs to be built first and will be included in the next release
- nf-core template update 2.8

### `Fixed`

- Circle_finder bug with bash sort command wanting to write into /tmp/ directory and not into work directory
- Usage.md updated to new paths and addition of nf-core modules

### `Dependencies`

### `Deprecated`

- Local python scripts not included in the pipeline
- Local versions of nf-core modules

## v1.0.2 - [2023-03-07]

### `Added`

- ampliconclassifier/makeinput module added -> Generates the input file used for ampliconclassifier functions
- ampliconclassifier/makeresultstable added -> Generates results table from AmpliconArchitect and AmpliconClassifier
- CNN Reference File For AmpliconArchitect
- mm10 option for AmpliconArchitect
- stub runs for AmpliconArchitect processes
- New module versions
- nf-core template 2.7.2

### `Fixed`

- Fixed ZeroDivisionError by Circle-Map
- Fixed keep_duplicates and skip_markduplicates parameter bug

### `Dependencies`

### `Deprecated`

- AmpliconArchitect Summary Process was deprecated

## v1.0.1 - [2022-06-22]

### `Added`

- Documentation Updates

### `Fixed`

- Fixed Bug with pipeline version in nextflow.config
- Fixed Circle-Map Realign bug in which only one sample is processed

### `Dependencies`

### `Deprecated`

- Samtools FAIDX

## v1.0.0 - [2022-06-01]

Initial release of nf-core/circdna, created with the [nf-core](https://nf-co.re/) template.

nf-core/circdna is a bioinformatics analysis pipeline for the identification of circular DNAs in eukaryotic cells. The pipeline is able to process WGS, ATAC-seq data or Circle-Seq data to give insights into the circular DNA landscape in your samples.

In total, the user can choose between 5 different branches inside the pipeline, depending on the biological question and the input data set. In these branches, specific software is used that is built for either the identification of amplified circular DNAs, the detection of putative circular DNA junctions, or the de novo assembly and mapping of circular DNAs.
