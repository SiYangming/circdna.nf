# Tasks

- [x] Task 1: 创建功能分支 `circleseeker`
  - [x] 从 master 创建并切换到 `circleseeker` 分支（未提交的 fled 修改保留在工作区、未纳入）
- [x] Task 2: 构建 CircleSeeker nf-core 标准模块
  - [x] `modules/local/circleseeker/main.nf`：process CIRCLESEEKER（conda/container 指令、gz 解压、FASTQ→FASTA 转换、circleseeker 调用、BED 转换、versions.yml、stub）
  - [x] `modules/local/circleseeker/environment.yml`：`bioconda::circleseeker=1.1.2`
  - [x] `modules/local/circleseeker/meta.yml`：输入/输出/工具元数据（参考 cresil/identify 格式）
  - [x] `modules/local/circleseeker/testdata/`：重构 test_reads.fa + test_ref.fa（含串联重复结构的 HiFi 模拟 reads，可真实检出 UeccDNA）
  - [x] 说明：模块级 `nextflow.config` 未创建——本仓库既有 local 模块（cresil/fled/ecc_finder）均无模块级配置，nf-core 标准亦不要求，相关 ext.args/publishDir 由 `conf/modules.config` 统一管理
- [x] Task 3: 编写 `bin/circleseeker_to_bed.py` 转换脚本
  - [x] 解析 v1.1.x `*_eccDNA_summary.csv`（chr/start/end/strand 直读，坐标 1-based→0-based），输出 BED6 + `read_count` 列（表头不含 `#`，与 `filter_by_read_support.py` 自动检测兼容）
  - [x] 已用真实 CircleSeeker 输出与样例 CSV 验证（含 filter_by_read_support min_support 过滤）
- [x] Task 4: 创建 `subworkflows/local/circleseeker_pipeline/`
  - [x] `main.nf`：CIRCLESEEKER 子流程（take reads + genome_fasta；emit merged/bed/summary/report/versions）
  - [x] `meta.yml`：子流程元数据
- [x] Task 5: 接入 `workflows/circdna.nf` 长读分支
  - [x] include `CIRCLESEEKER_PIPELINE` 与 `LONG_READ_FILTERING as LONG_READ_FILTERING_CIRCLESEEKER`
  - [x] 解析 `long_read_identifier` 新增 `run_circleseeker`，启用时运行子流程 + 过滤 + versions 汇入
- [x] Task 6: 更新配置
  - [x] `conf/modules.config`：CIRCLESEEKER publishDir（`${params.outdir}/long_read/circleseeker/${meta.id}`）
  - [x] `conf/test_pacbio_lr.config`、`conf/test_nanopore_lr.config`：`long_read_identifier` 加 circleseeker + withName 资源覆盖
- [x] Task 7: 编写 nf-test 模块测试
  - [x] `modules/local/circleseeker/tests/main.nf.test`（真实 + stub 用例，tag 遵循 nf-core 规范；snapshot 仅匹配稳定输出 merged/bed/versions）
  - [x] `modules/local/circleseeker/tests/nextflow.config`（docker enabled + `--platform linux/amd64` + A+C 用户映射 + 资源覆盖 + publishDir 禁用）
- [x] Task 8: 拉取镜像并运行 nf-test
  - [x] `docker pull quay.io/biocontainers/circleseeker:1.1.2--pyhdfd78af_0`（镜像已存在）
  - [x] nf-test 真实用例 + stub 用例通过（含快照稳定性复跑验证）
  - [x] 适配 v1.1.2 实际输出（`*_eccDNA_summary.csv` 而非 README 的 `*_merged_output.csv`），修复无检测结果时脚本报错问题
  - [x] 生成 `main.nf.test.snap`（真实检出 2 个 UeccDNA）
- [x] Task 9: 流水线接线验证
  - [x] `nextflow run main.nf -stub-run`（本地 testdata 临时 samplesheet + 本地参考 fasta + 临时 CPU 上限配置）长读分支 circleseeker 全链路通过（INPUT_CHECK→NANOPLOT→CIRCLESEEKER→FILTER_ECCDNA_BY_SUPPORT→MULTIQC）
  - [x] 临时文件已清理（临时 samplesheet/config/fastq.gz、work 目录、.nextflow 缓存）
- [x] Task 10: 版本与变更记录
  - [x] `nextflow.config` manifest version 4.1.0 → 4.2.0
  - [x] `CHANGELOG.md` 新增 v4.2.0 条目（Enhancements & fixes + Dependencies：circleseeker 1.1.2）
  - [x] 汇总检查完成（无新增参数，无需重新生成 nextflow_schema.json）

# Task Dependencies

- Task 1 是所有任务的前置（分支隔离）
- Task 2 → Task 7 → Task 8（模块构建 → 测试编写 → 测试运行）
- Task 3 → Task 4 → Task 5（转换脚本 → 子流程 → 流程接线）
- Task 6 依赖 Task 2（模块名/进程名确定后配置）
- Task 9 依赖 Task 5（接线完成）
- Task 10 依赖 Task 8、Task 9（测试通过后 bump 版本）
- Task 3、Task 4 与 Task 2 可并行推进
