# Checklist

- [x] 功能分支 `circleseeker` 已从 master 创建，未提交的 fled 修改不受影响
- [x] `modules/local/circleseeker/` 包含 main.nf / meta.yml / environment.yml / tests/ + testdata/
  - [x] 说明：模块级 `nextflow.config` 按本仓库既有 local 模块惯例（cresil/fled/ecc_finder）与 nf-core 模块标准不保留，ext.args/publishDir 由 `conf/modules.config` 统一管理
- [x] main.nf 符合 nf-core 规范：conda+container 指令、ext.args / ext.prefix、stub、versions.yml emit
- [x] container 指向 `quay.io/biocontainers/circleseeker:1.1.2--pyhdfd78af_0`，environment.yml 引用 `bioconda::circleseeker=1.1.2`
- [x] 模块支持 gz 解压与 FASTQ→FASTA 转换
- [x] 模块产出 merged（`<prefix>_eccDNA_summary.csv`，v1.1.x 实际格式）/ BED / summary / report / versions 五个 emit
- [x] `bin/circleseeker_to_bed.py` 可将 summary CSV 转为带 `read_count` 列的 BED，且与 `filter_by_read_support.py` 兼容（已用真实输出验证）
- [x] `subworkflows/local/circleseeker_pipeline/main.nf` 存在（+ meta.yml），emit merged/bed/summary/report/versions
- [x] `workflows/circdna.nf` 长读分支支持 `circleseeker` 标识，BED 进入 LONG_READ_FILTERING，versions 汇入
- [x] `conf/modules.config` 已配置 CIRCLESEEKER publishDir（`${params.outdir}/long_read/circleseeker/${meta.id}`）
- [x] `conf/test_pacbio_lr.config`、`conf/test_nanopore_lr.config` 已包含 circleseeker 标识与资源覆盖
- [x] `modules/local/circleseeker/tests/main.nf.test` 含真实 + stub 两个用例，`tests/nextflow.config` 含 docker + amd64 + A+C 映射 + 资源覆盖
- [x] docker 镜像 `quay.io/biocontainers/circleseeker:1.1.2--pyhdfd78af_0` 已拉取（已存在）
- [x] nf-test 真实用例运行成功（真实检出 2 个 UeccDNA，read_count=3），snapshot 已生成且稳定性复跑通过
- [x] nf-test stub 用例运行成功
- [x] 流水线接线验证通过（stub-run 全链路 INPUT_CHECK→NANOPLOT→CIRCLESEEKER→FILTER_ECCDNA_BY_SUPPORT→MULTIQC）
- [x] 版本已 bump 至 4.2.0，CHANGELOG 已更新（含 circleseeker 1.1.2 依赖条目）
