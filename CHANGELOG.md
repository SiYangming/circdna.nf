# nf-core/circdna: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v4.4.1 - [2026-08-05]

### Credits

Special thanks to the following for their input and contributions:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **ECCsplorer 参数入口集中化**: 在 `nextflow.config` 中新增 `eccsplorer_input_normalize`、`eccsplorer_map_core`、`eccsplorer_map_extract`、`eccsplorer_clu`、`eccsplorer_all` 作为主入口语义，并将原有 `eccsplorer_trim_reads` 保留为兼容别名，避免旧命令失效
- **ECCsplorer 运行时拼参收敛**: `conf/modules.config` 的 `ECCSPLORER` 与 `ECCSPLORER_WITH_CONTROL` 统一复用集中化参数拼装逻辑，仅保留当前已落地的 map 路径；`clu/all` 重型能力默认关闭且不改变现有输出结构
- **Schema 最小一致性更新**: `nextflow_schema.json` 同步新增 ECCsplorer 新参数入口与 `eccsplorer_database` 描述，并将旧参数标记为隐藏兼容入口，帮助命令行帮助信息迁移到新语义
- **大基因组 CSI 索引匹配修复**: `conf/large_genome.config` 的 `SAMTOOLS_INDEX` 匹配改为正则 `.*SAMTOOLS_INDEX.*`，使 `-c`（CSI 索引）覆盖全部 SAMTOOLS_INDEX 实例（含 alias 的 `SAMTOOLS_INDEX_BAM`/`SAMTOOLS_INDEX_FILTERED`/`SAMTOOLS_INDEX_RE`），修复参考序列超过 BAI 上限（约 512 Mb/染色体）时 `samtools index` 报 `Numerical result out of range` 的问题
- **Tragopogon_porrifolius hap1 标注大基因组**: `SERVER_RUN_GUIDE.md` 中 hap1 命令附加 `-c circdna.nf/conf/large_genome.config` 并标注大基因组（hap2 不变）
- **README 大基因组 CSI 用法说明**: `README.md` Usage 部分新增大基因组物种附加 `-c conf/large_genome.config` 的提示（小麦、日本柳杉、Tragopogon_porrifolius hap1）

### Notes

- 当前 Nextflow 集成仍只实际执行 ECCsplorer `map` 路径，`clu` 与 `all` 为预留语义入口
- 默认配置保持现有输出兼容：结果仍发布到 `${params.outdir}/eccsplorer/`，未启用未落地的重型功能

## v4.4.0 - [2026-08-04]

### Credits

Special thanks to the following for their input and contributions:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **新增 `analysis` 模式（下游分析）**: 在 `--mode` 参数中新增 `analysis` 选项，支持独立运行下游分析，不依赖上游检测流程。用户可通过 `--analysis_input` 参数传入检测产物 BED 文件（目录或单文件），跳过 FASTQ/BAM 预处理和 eccDNA 检测步骤，直接执行分布分析、基因 burden 矩阵、DEG 差异分析和火山图。`workflows/circdna.nf` 在 analysis 分支中通过 `channel.fromPath` 收集 BED 文件并传入 `DOWNSTREAM_ANALYSIS` 子工作流
- **新增 `DOWNSTREAM_ANALYSIS` 子工作流**: `subworkflows/local/downstream_analysis/main.nf` 编排下游分析模块：`ECC_DISTRIBUTION`（分布分析，始终运行）→ `ECC_HOMER_ANNOTATION`（HOMER 注释，仅当 `--annotation_db` 提供时运行）→ `ECC_GENE_BURDEN`（基因 burden 矩阵，仅当 `--gene_bed` 提供时运行）→ `ECC_DEG_PERM`/`ECC_DEG_R`（DEG 差异分析，仅当 `--group_file` 提供时运行）→ `ECC_ENRICHMENT`（GO/KEGG/GSEA 富集，仅当 `--org_db` 提供且 DEG 方法为 R 时运行）→ `ECC_VOLCANO`（火山图，依赖 DEG 结果）→ `ECC_VISUALIZE`（Circlize 可视化，仅当 `--ecc_id_visualize` 和 `--gene_bed` 提供时运行）
- **新增 `ECC_DISTRIBUTION` 模块**: `modules/local/ecc_distribution/main.nf`，移植自 ecc_pipe `Distribution.py`。生成染色体分布饼图（`*_chr_distribution.pdf` + `.csv`）和长度分布图（`*_length_distribution.pdf` + 4 个 CSV）。支持 circlemap/cresil/eccsplorer/通用 6 列格式。依赖 pandas、matplotlib、seaborn
- **新增 `ECC_GENE_BURDEN` 模块**: `modules/local/ecc_gene_burden/main.nf`，移植自 ecc_pipe `DEG.py: make_ecc_gene_martix()`。通过 bedtools intersect 计算 eccDNA 与基因的重叠，输出基因 burden 计数矩阵（`*_ecc_gene_number.csv`）和 intersect BED（`*_ecc_gene_intersect.bed`）。依赖 bedtools、pandas
- **新增 `ECC_DEG_PERM` 模块**: `modules/local/ecc_deg/main.nf`，移植自 ecc_pipe `DEG.py: ecc_permutation_test()`。非参数置换检验，对 eccDNA 基因 burden 矩阵进行两组比较，输出 log2(CPM+1) 标准化矩阵（`ecc_perm_norm_matrix.csv`）和 DEG 结果（`ecc_perm_result.csv`，含 log2FoldChange、pvalue、adj.P.Val）。纯 Python 实现（numpy + pandas），无 R 依赖
- **新增 `ECC_VOLCANO` 模块**: `modules/local/ecc_deg/main.nf`，移植自 ecc_pipe `DEG.py: volcano_plot()`。基于 DEG 结果绘制火山图（`*.volcano.pdf`），按 log2FC 和 pvalue 阈值着色 up/down/normal，标注 top5 基因。依赖 matplotlib
- **新增 `ECC_HOMER_ANNOTATION` 模块**: `modules/local/ecc_distribution/main.nf`，移植自 ecc_pipe `Distribution.py: annotate_homer()`。调用 HOMER `annotatePeaks.pl` 对 eccDNA 区域进行注释，输出注释分布统计 CSV（`*_homer_anno_distribution.csv`）、柱状图 PDF（`*_homer_anno_distribution.pdf`）和原始注释 TSV（`*_result.analysis.anno.tsv`）。条件执行：仅当 `--annotation_db` 提供时运行。依赖 HOMER、pandas、matplotlib
- **新增 `ECC_DEG_R` 模块**: `modules/local/ecc_deg/main.nf`，移植自 ecc_pipe `analysis_code/{deseq2,edger,limma}.R`。支持三种 R DEG 方法（DESeq2/edgeR/limma），通过 `--deg_method` 参数选择。输出标准化矩阵（`{method}_norm_matrix.csv`）和 DEG 结果（`{method}_result.csv`）。使用独立 `environment_r.yml` 隔离 R 依赖。条件执行：仅当 `--deg_method` 非 `ecc_perm` 且 `--group_file` 提供时运行
- **新增 `ECC_ENRICHMENT` 模块**: `modules/local/ecc_deg/main.nf`，移植自 ecc_pipe `analysis_code/clusterprofile.R`。基于 R DEG 结果执行 GO/KEGG/GSEA 富集分析，输出 GO 上调/下调 CSV（`*_GO_up.csv`、`*_GO_down.csv`）和 GSEA 结果 CSV + 图（`*_gsea_result_*.csv`、`*_gsea_top_*.pdf`）。动态加载物种注释包（通过 `--org_db` 参数，如 `org.Hs.eg.db`、`org.Mm.eg.db`、`org.At.tair.db`）。条件执行：仅当 `--org_db` 提供且 DEG 方法为 R 时运行
- **新增 `ECC_VISUALIZE` 模块**: `modules/local/ecc_visualize/main.nf`，移植自 ecc_pipe `Circlize.py + circlize.R`。两步流程：Python 预处理（`ecc_circlize_prep.py` 提取目标 eccDNA 区域并与基因 BED 交集）→ R 绘图（`ecc_circlize.R` 使用 circlize 包绘制环形可视化）。输出 `circlize_plot.pdf`。条件执行：仅当 `--ecc_id_visualize` 和 `--gene_bed` 提供时运行
- **新增 Python 脚本**: `bin/ecc_distribution.py`（分布分析）、`bin/ecc_gene_burden.py`（burden 矩阵）、`bin/ecc_perm.py`（ecc_perm 置换检验 + burden 矩阵合并）、`bin/ecc_volcano.py`（火山图）、`bin/ecc_homer_anno.py`（HOMER 注释）、`bin/ecc_merge_burden.py`（burden CSV 合并，供 R DEG 使用）、`bin/ecc_circlize_prep.py`（Circlize 预处理）
- **新增 R 脚本**: `bin/deseq2.R`、`bin/edger.R`、`bin/limma.R`（三种 R DEG 方法，移植自 ecc_pipe）、`bin/clusterprofile.R`（GO/KEGG/GSEA 富集，动态加载物种注释包）、`bin/ecc_circlize.R`（环形可视化，移植自 ecc_pipe）
- **新增 `test_analysis` 测试 profile**: `conf/test_analysis.config`，使用 `results/results_testdata/circlemap/realign/` 下的真实 Circle-Map 检测结果 BED 作为输入，配套 `samplesheets/test_group.txt`（DEG 分组文件）和 `testdatasets/reference/test_gene_bed.bed`（测试用基因 BED）。stub 模式验证通过
- **参数 schema 更新**: `nextflow_schema.json` 新增 `downstream_analysis_options` 分组（含 `analysis_mode`、`analysis_input`、`detect_type`、`group_file`、`deg_method`、`log2fc_threshold`、`pvalue_threshold`、`annotation_db`、`gene_bed`、`intersect_ratio`、`max_permutations`、`ecc_id_visualize`）；`mode` 参数 enum 新增 `analysis` 选项；`input` 和 `input_format` 从 required 列表中移除（analysis 模式不需要）
- **`WorkflowMain.groovy` 更新**: analysis 模式下跳过 `--input` 检查，改由 `--analysis_input` 提供
- **`modules.config` 更新**: 新增 `ECC_DISTRIBUTION`、`ECC_HOMER_ANNOTATION`、`ECC_GENE_BURDEN`、`ECC_DEG_PERM`、`ECC_DEG_R`、`ECC_ENRICHMENT`、`ECC_VOLCANO`、`ECC_VISUALIZE` 的资源配置和 publishDir（输出到 `${params.outdir}/analysis/{distribution,homer_annotation,gene_burden,deg,enrichment,visualize}/`）

### Dependencies

- **bedtools**: 2.31.1（ECC_GENE_BURDEN、ECC_VISUALIZE 模块使用）
- **python**: 3.11（ECC_DISTRIBUTION、ECC_DEG_PERM、ECC_VOLCANO、ECC_HOMER_ANNOTATION、ECC_VISUALIZE 模块使用）
- **pandas**: ≥2.0（ECC_DISTRIBUTION、ECC_GENE_BURDEN、ECC_DEG_PERM、ECC_HOMER_ANNOTATION、ECC_VISUALIZE 模块使用）
- **numpy**: ≥1.24（ECC_DEG_PERM 模块使用）
- **matplotlib**: ≥3.8（ECC_DISTRIBUTION、ECC_VOLCANO、ECC_HOMER_ANNOTATION 模块使用）
- **seaborn**: ≥0.12（ECC_DISTRIBUTION 模块使用）
- **HOMER**: 4.11（ECC_HOMER_ANNOTATION 模块使用，`annotatePeaks.pl`）
- **R**: ≥4.3（ECC_DEG_R、ECC_ENRICHMENT、ECC_VISUALIZE 模块使用）
- **DESeq2**: 1.42.0（ECC_DEG_R 模块，`--deg_method deseq2` 时使用）
- **edgeR**: ≥3.40（ECC_DEG_R 模块，`--deg_method edger` 时使用）
- **limma**: ≥3.58（ECC_DEG_R 模块，`--deg_method limma` 时使用）
- **clusterProfiler**: 4.10.0（ECC_ENRICHMENT 模块使用）
- **circlize**: 0.4.16（ECC_VISUALIZE 模块使用）

### Notes

- analysis 模式位于检测流程下游，可消费 Circle-Map/ECCsplorer/CReSIL 等任意检测工具的 BED 输出
- ecc_perm 作为默认 DEG 方法（纯 Python，无 R 依赖，适合 eccDNA 稀疏矩阵）
- 下游分析模块支持物种无关框架：分布分析、ecc_perm、火山图无物种依赖；基因 burden 矩阵和 Circlize 可视化只需提供基因 BED；HOMER 注释需提供物种基因组名（`--annotation_db`）；R DEG 方法无物种依赖；GO/KEGG/GSEA 富集需提供物种注释包（`--org_db`）
- 所有下游分析模块均为条件执行，通过参数控制是否运行，未提供参数时自动跳过

## v4.3.0 - [2026-08-04]

### Credits

Special thanks to the following for their input and contributions:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **ECCsplorer BLAST 注释数据库支持**: 新增 `params.eccsplorer_database` 参数（默认 null），指向未压缩的 FASTA 注释库。当参数非 null 时，ECCSPLORER 和 ECCSPLORER_WITH_CONTROL 模块的 `ext.args` 自动附加 `-d ${params.eccsplorer_database}`，对候选 eccDNA 序列进行重复元件/功能注释。新增 `scripts/prepare_eccsplorer_database.sh` 脚本，支持合并 Dfam + RepBase 物种库生成单一 FASTA 数据库
- **ECCsplorer gDNA control 支持（由 samplesheet data_type + group 列驱动）**: 新增 `ECCSPLORER_WITH_CONTROL` process 变体，接受额外的 gDNA control R1/R2 作为 ECCsplorer 的 dataset B（位置参数 3、4）。control 启用完全由 samplesheet 驱动，无需命令行参数：当 samplesheet 含 `data_type=gDNA` 行时自动启用，仅含 `eccDNA` 时不启用。通过新增的可选 `group` 分组列建立 eccDNA 与 gDNA 的配对关系（同一 group 值下的 eccDNA 使用该 group 下的 gDNA 作为 control），不再依赖样本名数字后缀匹配。`subworkflows/local/eccdna_mode/main.nf` 根据 `meta.data_type` 和 `meta.group` 分离样本并路由 control 通道，`workflows/circdna.nf` 按 data_type 过滤 eccDNA/gDNA reads 分别传入 ECCDNA_MODE
- **check_samplesheet.py 兼容现有 data_type 列格式 + 新增 group 列**: 同时识别 `data_type` 和 `datatype` 两种列名，值归一化为小写后校验（接受 `eccDNA`/`gDNA`/`eccdna`/`gdna` 任一写法）。新增识别可选的 `group` 分组列，输出 samplesheet 保留原始列名。`subworkflows/local/input_check/main.nf` 的 `create_fastq_channels` 和 `create_bam_channels` 均解析 `data_type` 和 `group` 列到 meta map
- **统一输出目录规范**: 所有 test profile 的 `--outdir` 统一设置为 `circdna.nf/results/<profile_name>/`（如 `results/test_local/`、`results/test_local_gdna/`），不再使用旧式输出目录

### Dependencies

- **eccsplorer**: v2022.01.1.1（无变化）
  - Docker 镜像: `quay.io/bioinfortools/eccsplorer:2022.01.1.1`（无变化）
  - 新增可选运行时依赖: BLAST 注释数据库（由用户提供未压缩 FASTA 格式，通过 `--eccsplorer_database` 参数传入）

### Notes

- gDNA control 完全由 samplesheet 驱动，无需新增任何命令行 control 参数
- `group` 列为可选，无 `group` 列但 samplesheet 含 gDNA 时，若 gDNA 仅 1 个则所有 eccDNA 共用该 control（向后兼容），若 gDNA 多于 1 个则报错要求用户提供 `group` 列
- 注释数据库需为未压缩 FASTA 格式（.fa/.fasta/.fna），不支持 .gz/.bz2/.xz/.zip 等压缩格式

## v4.2.3 - [2026-08-03]

### Credits

Special thanks to the following for their input and contributions:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **清理 Nextflow lint 警告**: 修复 `nextflow lint .` 输出的 8 条警告（4 个文件）。(1) 删除 `circle_map_pipeline/main.nf` 中未使用变量 `ch_qname_sorted_bai`；(2) `eccdna_mode/main.nf` 和 `reference_mode/main.nf` 中 4 处闭包参数 `meta` → `_meta` 抑制未使用参数警告；(3) `input_check/main.nf` 中 3 处 `Channel.fromPath` → `channel.fromPath` 适配 Nextflow DSL2 推荐的小写 channel factory；(4) `reference_mode/main.nf` take 参数 `repeat_gff` → `_repeat_gff` 抑制未使用参数警告（保留位置参数供未来 repeat annotation 功能使用）

## v4.2.2 - [2026-08-03]

### Credits

Special thanks to the following for their input and contributions:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **移除 eccdna_mode 子工作流中冗余的 `.first()` 操作符**: `subworkflows/local/eccdna_mode/main.nf` 第 50 行 `ch_eccsplorer_fasta = fasta_meta.map { meta, fasta -> fasta }.first()` 对已经是 value channel 的 `fasta_meta.map{...}` 结果再次调用 `.first()`，触发 Nextflow 警告 `The operator 'first' is useless when applied to a value channel which returns a single value by definition`。由于 `fasta_meta` 已在 `workflows/circdna.nf` 第 50 行通过 `.first()` 转换为 value channel，`value.map{...}` 仍为 value channel，无需再次 `.first()`。移除后 channel 类型与广播语义不变，ECCSPLORER 仍正确处理所有样本

## v4.2.1 - [2026-08-03]

### Credits

Special thanks to the following for their input and contributions:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **修复 ECCSPLORER 模块输出文件映射错误**: `modules/local/eccsplorer/main.nf` 的 script 块原先使用 `mv ${prefix}_output/*_candidates.bed` 和 `mv ${prefix}_output/*_junction_reads.txt` 重命名 ECCsplorer 输出，但 ECCsplorer 从不生成这两个文件名。实际输出文件位于 `${prefix}_output/eccpipe_results/mapping_results/` 下，文件名为 `TR_hiconf-ECC-REGIONS.bed`、`TR.trns.txt` 等。由于 glob 匹配不到任何文件，`|| touch` 兜底创建了 0 字节空文件，导致 `eccsplorer/` 目录下所有候选结果文件为空（实际工作目录中 ECCsplorer 正常生成了 78 个高置信度 eccDNA 区域和 2388 个低置信度区域）。现将映射修正为：`*_hiconf-ECC-REGIONS.bed` → `${prefix}_candidates.bed`（高置信度候选区域），`*.trns.txt` → `${prefix}_junction_reads.txt`（junction reads），并将 `mv` 改为 `cp` 以保留原始结果树。同步修复 `bio.nf/modules/eccsplorer/main.nf` 保持两处一致
- **ECCSPLORER 模块新增完整结果输出**: 模块新增 4 个输出通道以发布所有正确的 ECCsplorer 分析结果：`lowconf_ecc_regions`（低置信度 eccDNA 区域 `*_lowconf-ECC-regions.bed`）、`alignment_stats`（segemehl 比对统计 `*_alignment-stats.txt`）、`ecc_sequences`（提取的 eccDNA 序列 `*_ECC-SEQUENCES.fasta`）、`eccpipe_results`（完整结果树目录，含 `mapping_results/`、`eccMap_summary.html`、per-candidate 分析、manhattan plot 可视化等）。所有新增输出通过现有 publishDir 配置自动发布到 `${params.outdir}/eccsplorer/`。同步更新 `meta.yml` 补充输出描述

## v4.2.0 - [2026-08-02]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **ECCSPLORER 模块新增 BAM 输入支持**: 模块现在同时接受 BAM 和 FASTQ 两种输入格式。当输入为 BAM 时，模块自动使用 `samtools fastq` 将 BAM 转换为配对 FASTQ 后再调用 ECCsplorer。输入类型通过文件扩展名（`.bam` vs `.fq/.fastq`）自动检测，无需额外参数
- **eccdna_mode 子工作流支持 BAM 输入路由**: `subworkflows/local/eccdna_mode/main.nf` 新增 `input_format` 参数，根据输入格式自动路由：FASTQ 模式传递原始 reads 至 ECCSPLORER，BAM 模式传递 BAM_PREPROCESSING 产出的 sorted BAM 至 ECCSPLORER
- **主工作流支持 BAM 模式下的 eccdna 分析**: `workflows/circdna.nf` 移除了 eccdna 模式仅限 FASTQ 的限制，BAM 输入现在也可以运行 eccdna 模式
- **ECCsplorer 构建产物统一至源码目录**: `eccsplorer-recipe/` 目录已移动至 `ECCsplorer/` 源码目录内（`conda-recipe/` 子目录 + 根级 Dockerfile），消除分散的 recipe 目录
- **Conda 包适配本地源码构建**: `ECCsplorer/conda-recipe/meta.yaml` 的 source 从 `git_url` 改为 `path: ..`，支持基于本地源码构建 conda 包
- **Docker 镜像适配本地源码构建**: `ECCsplorer/Dockerfile` 从 `git clone` 改为 `COPY . /opt/eccsplorer`，支持基于本地源码构建 Docker 镜像
- **修复 BAM_PREPROCESSING 子工作流 BAM 输入模式 bug**: `subworkflows/local/bam_preprocessing/main.nf` 中 `run_bwa = false`（BAM 输入模式）分支未调用 SAMTOOLS_INDEX_BAM，导致 `ch_bam_sorted_bai` 通道未定义。现已在 BAM 输入分支中也对预排序 BAM 执行索引
- **修复 ECCsplorer Docker 镜像 ENTRYPOINT 冲突**: Docker 镜像 `quay.io/bioinfortools/eccsplorer:2022.01.1.1` 原先设置 `ENTRYPOINT ["python", "/opt/eccsplorer/ECCsplorer.py"]`，会拦截 Nextflow 的 `sh -c .command.sh` 命令导致 stub 测试失败（报错 `ambiguous option: -c could match -cnt, -cpu`）。现已将 ENTRYPOINT 改为 `CMD ["python", "/opt/eccsplorer/ECCsplorer.py", "--help"]`，保留基础镜像的 `tini --` 作为 init 进程。镜像已重建并覆盖推送至 quay.io（digest: sha256:1f1667b0ddef8cd902b1eee0620f46be2f0a33916b53efb83c30f56b0b3d9ddf）
- **修复 ECCSPLORER 模块参数传递错误**: `modules/local/eccsplorer/main.nf` 中调用 ECCsplorer.py 时使用了错误的参数名 `-out_dir`，正确参数名为 `-out`（对应 `--output_dir`）。此错误导致真实模式下 ECCSPLORER 任务失败（报错 `unrecognized arguments: -out_dir`）。同步修复 `bio.nf/modules/eccsplorer/main.nf` 保持两处一致
- **修复 ECCsplorer Docker 镜像缺失 haarz.x 工具**: Docker 镜像 `quay.io/bioinfortools/eccsplorer:2022.01.1.1` 原先依赖 bioconda 的 `segemehl=0.2.0`，该版本不包含 `haarz.x` 工具（segemehl 的伴随工具，ECCsplorer 的 basic_checkups 阶段强制依赖），导致真实模式下 ECCSPLORER 任务报错 `haarz not found!`。现将 `segemehl` 版本约束从无限制改为 `>=0.3.4`（bioconda 0.3.4+ 版本包含 haarz.x）。镜像已重建并覆盖推送至 quay.io（digest: sha256:a3a7a099d8bc95af874e7dab91a11ca4b29048ddc0bfc3bc515fb609f5e1ffd5）。同步更新 `ECCsplorer/environment-docker.yml` 和 `ECCsplorer/conda-recipe/meta.yaml`
- **ECCsplorer.py 命令行直接调用支持**: ECCsplorer.py 源码已添加可执行权限（`chmod +x`，shebang `#!/usr/bin/env python3` 已存在）。Dockerfile 新增 PATH 符号链接（`/opt/conda/envs/eccsplorer/bin/ECCsplorer.py` → `/opt/eccsplorer/ECCsplorer.py`，同时提供无后缀的 `ECCsplorer` 入口）。`bio.nf/modules/eccsplorer/main.nf` 与 `circdna.nf/modules/local/eccsplorer/main.nf` 的调用方式从 `python ${ECCSPLORER_HOME:-/opt/eccsplorer}/ECCsplorer.py` 改为直接调用 `ECCsplorer.py`，无需 `python` 前缀和显式路径
- **Docker 和 conda 包依赖列表按 Installation_instructions.md 完善**: 参考 `ECCsplorer/tutorials/Installation_instructions.md` 第 158-173 行"Third party tool required"清单与源码 `ECCsplorer/environment.yml`，在 `ECCsplorer/environment-docker.yml` 与 `ECCsplorer/conda-recipe/meta.yaml` 中补齐以下依赖：第三方工具（`diamond`、`last`、`mafft`、`imagemagick`、`blast-legacy`）、RepeatExplorer2 推荐 R 库（`r-igraph`、`r-data.tree`、`r-stringr`、`r-r2html`、`r-hwriter`、`r-dt`、`r-scales`、`r-plotrix`、`r-png`、`r-plyr`、`r-optparse`、`r-dbi`、`r-rsqlite`、`r-gridbase`）、Bioconductor 包（`bioconductor-biostrings`）。同时将 `r-rserve` 从 Dockerfile 单独安装迁移至 environment-docker.yml 统一管理。Dockerfile 中 RepeatExplorer2 安装步骤保留 stub 兜底逻辑（上游 URL 失效），并在注释中明确说明用户需手动安装
- **Dockerfile 新增 conda 清华镜像源配置**: 为解决从 conda.anaconda.org 下载 R 包网络超时问题，Dockerfile 新增 `CONDA_REMOTE_MAX_RETRIES=10`、`CONDA_REMOTE_CONNECT_TIMEOUT_SECS=30`、`CONDA_REMOTE_READ_TIMEOUT_SECS=120`、`CONDA_REMOTE_BACKOFF_FACTOR=2` 环境变量，以及 `/opt/conda/.condarc` 清华大学镜像源配置（conda-forge 映射至 `mirrors.tuna.tsinghua.edu.cn`），显著提升构建稳定性

### Dependencies

- **eccsplorer**: v2022.01.1.1（无变化）
  - conda 包: `yangmingsi::eccsplorer=2022.01.1.1`（发布于 [anaconda.org/yangmingsi/eccsplorer](https://anaconda.org/yangmingsi/eccsplorer)）
  - Docker 镜像: `quay.io/bioinfortools/eccsplorer:2022.01.1.1`（重建覆盖，新 digest: sha256:04a21cf181793a91a0f5f28977609d60e6566c10a7ca07cb79dff39452a305c3）
  - 新增运行时依赖: samtools（用于 BAM→FASTQ 转换，已在 environment.yml 中声明）
  - Docker 镜像新增依赖（参考 Installation_instructions.md）: diamond、last、mafft、imagemagick、blast-legacy、r-igraph、r-data.tree、r-stringr、r-r2html、r-hwriter、r-dt、r-scales、r-plotrix、r-png、r-plyr、r-optparse、r-dbi、r-rsqlite、r-gridbase、bioconductor-biostrings、r-rserve
- **segemehl**: 0.2.0 → >=0.3.4（修复 haarz.x 缺失问题，0.3.4+ 包含 haarz.x）

### Notes

- BAM 输入支持使 ECCsplorer 可灵活接入不同上游产物（如三代测序预处理后的 BAM）
- conda 包与 Docker 镜像版本号保持一致（`2022.01.1.1`）
- 构建流程遵循 [AGENTS.md](../AGENTS.md) 第 12 章 "第三方模块构建工作流程"
- conda 包上传至 anaconda.org/yangmingsi（用户 anaconda.org 用户名为 `YangmingSi`，channel 不区分大小写为 `yangmingsi`），Docker 镜像上传至 quay.io/bioinfortools（用户 quay.io 登录账户）

## v4.1.0 - [2026-08-02]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **ECCsplorer 真实检测实现**: 替换 `modules/local/eccsplorer/main.nf` 占位模块（原仅产出硬编码假数据），改为调用真实 ECCsplorer v2022.01.1.1 软件进行 eccDNA 检测。模块从 [bio.nf/modules/eccsplorer/](https://github.com/SiYangming/bio.nf) 拷贝接入，遵循 nf-core 模块标准（main.nf、meta.yml、environment.yml）
- **ECCSPLORER 输入接口变更**: ECCsplorer 内部使用 segemehl 自行比对，不接受预比对的 BAM。`subworkflows/local/eccdna_mode/main.nf` 中 ECCSPLORER 的输入从 `BAM + BAI` 调整为 `FASTQ R1 + R2 + FASTA`，直接消费 `reads` 通道（与 BAM_PREPROCESSING 共享同一输入源）
- **新增 `--eccsplorer_trim_reads` 参数**: 启用 Trimmomatic 质量过滤（默认 false）。通过 `conf/modules.config` 的 `ext.args` 传递给 ECCsplorer
- **ECCsplorer 资源配置**: `conf/modules.config` 添加 ECCSPLORER 的 `publishDir` 配置（输出至 `${params.outdir}/eccsplorer`）
- **versions emit 标准化**: ECCSPLORER 模块的 versions emit 从旧的 tuple 模式（`val, val, val`）改为 nf-core 标准的 `path "versions.yml"` 模式，与 BAM_PREPROCESSING、MOSDEPTH 等模块一致
- **大基因组 CSI 索引匹配修复**: `conf/large_genome.config` 的 `SAMTOOLS_INDEX` 匹配改为正则 `.*SAMTOOLS_INDEX.*`，使 `-c`（CSI 索引）覆盖全部 SAMTOOLS_INDEX 实例（含 alias 的 `SAMTOOLS_INDEX_BAM`/`SAMTOOLS_INDEX_FILTERED`/`SAMTOOLS_INDEX_RE`），修复参考序列超过 BAI 上限（约 512 Mb/染色体）时 `samtools index` 报 `Numerical result out of range` 的问题
- **Tragopogon_porrifolius hap1 标注大基因组**: `SERVER_RUN_GUIDE.md` 中 hap1 命令附加 `-c circdna.nf/conf/large_genome.config` 并标注大基因组（hap2 不变）
- **README 大基因组 CSI 用法说明**: `README.md` Usage 部分新增大基因组物种附加 `-c conf/large_genome.config` 的提示（小麦、日本柳杉、Tragopogon_porrifolius hap1）

### Dependencies

- **eccsplorer**: 新增（v2022.01.1.1）
  - conda 包: `yangmingsi::eccsplorer=2022.01.1.1`（发布于 [anaconda.org/yangmingsi/eccsplorer](https://anaconda.org/yangmingsi/eccsplorer)）
  - Docker 镜像: `quay.io/bioinfortools/eccsplorer:2022.01.1.1`
  - 包含依赖: Python 3.7、numpy、biopython、scipy、pyRserve、R (ggplot2/ggrepel/gridExtra/dplyr)、blast+、segemehl、samtools≥1.9、bedtools≥2.28.0、RepeatExplorer2、Trimmomatic、seqtk

### Notes

- ECCsplorer 由 [crimBubble/ECCsplorer](https://github.com/crimBubble/ECCsplorer) 开发，引用: Mann, L., et al. BMC Bioinformatics 23, 40 (2022)
- conda 包与 Docker 镜像版本号保持一致（`2022.01.1.1`），便于追溯
- 构建流程遵循 [AGENTS.md](../AGENTS.md) 第 12 章 "第三方模块构建工作流程"

## v4.0.0 - [2026-08-02]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### BREAKING CHANGES

- **integrated 模式完全移除**: `params.mode` 不再接受 `integrated` 值，仅保留 `reference` 和 `eccdna` 两种模式。原 `integrated` 分支（workflows/circdna.nf）已删除。用户应使用独立的 [eccdna.smk](https://github.com/SiYangming/eccdna.smk) Snakemake 工作流执行综合评分分析
- **CANDIDATE_MERGE 模块移除**: `modules/local/candidate_merge/` 目录及 `bin/merge_candidates.py` 已删除，迁移至 eccdna.smk 仓库。eccdna 模式现在产出原始 `eccsplorer_bed` + `circle_map_bed` 后即终止，不再产出 `merged_bed`
- **ECC_SCORE 模块移除**: `modules/local/ecc_score/` 目录、`bin/calculate_ecc_score.py` 及 `subworkflows/local/integrated_mode/` 已删除，迁移至 eccdna.smk 仓库
- **ecc_score_w1/w2/w3 参数移除**: 这三个参数仅被 ECC_SCORE 使用，ECC_SCORE 迁移后参数失去用途。用户应在 eccdna.smk 的 `config/config.yaml` 中配置这些权重
- **test_integrated profile 移除**: `conf/test_integrated.config` 已删除，`nextflow.config` profiles 块中的 `test_integrated` 引用已移除

### Enhancements & fixes

- **探索性分析迁移至 Snakemake**: 将参数敏感的轻量 Python 步骤（CANDIDATE_MERGE、ECC_SCORE）从 Nextflow 迁移至独立的 Snakemake 工作流 eccdna.smk，解耦"重计算"与"轻探索"。调整 `--max-distance`、`w1/w2/w3` 等探索性参数时，不再需要重新触发上游 CIRCLEMAP_REALIGN（process_high, 96h）等重计算步骤
- **契约接口定义**: Nextflow 产出 mosdepth_bed + eccsplorer_bed + circle_map_bed 作为契约接口，供 eccdna.smk Snakemake 工作流消费

### Migration Guide

从 v3.x 升级到 v4.0.0 的用户：
1. `integrated` 模式不再可用，请改用 `reference` + `eccdna` 两种模式
2. 综合评分分析请使用 [eccdna.smk](https://github.com/SiYangming/eccdna.smk) 仓库
3. Nextflow 产出路径（mosdepth bed、eccsplorer bed、circle_map bed）作为 eccdna.smk 的输入

## v3.2.1 - [2026-08-02]

### Enhancements & fixes

- **CIRCLEFINDER 空结果处理优化**: 参照 suda-huanglab/circlehunter 最佳实践，将"未检测到 eccDNA"从误导性 "ERROR" 改为 "INFO" 提示，并产生空 `microDNA-JT.txt` 文件以保证下游通道完整性。原版 Circle-Finder 工具本身就静默产生空文件，circdna.nf 之前自定义的 `file_exists` 检查过度报错。移除 7 处中间 `file_exists` 检查，仅保留 2 处早期检查（split 文件为空、concordant.id-freq3.txt 为空）

## v3.2.0 - [2026-07-27]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **增量/减量缓存实现（方案3）**: 重构 `input_check/main.nf`，将 SAMPLESHEET_CHECK 验证步骤与 channel 创建解耦，使用 `Channel.fromPath(samplesheet).splitCsv()` 直接从原始 CSV 解析样本，实现样本级增量/减量缓存（增加或减少样本时，其他样本的任务缓存不受影响）
- **自动检测单端/双端**: `create_fastq_channels` 和 `create_long_read_channels` 函数支持自动检测 `single_end` 列，兼容无 `single_end` 列的原始 CSV 格式
- **移除冗余 `.first()` 操作符**: 移除 value channel 上多余的 `.first()` 调用，消除 Nextflow 警告 "The operator `first` is useless when applied to a value channel"
- **配置优化**:
  - `test_local.config` 添加 `fasta_base_path = null` 消除参数未定义警告
  - 添加 `trace.overwrite`、`report.overwrite`、`timeline.overwrite` 配置，支持重复运行覆盖输出
- **代码清理**:
  - 恢复 `bam_preprocessing/main.nf` 到原始样式，移除 `SAMTOOLS_VIEW_DEDUP` 步骤
  - 移除 `--READ_NAME_REGEX null` 参数，测试原生 Picard 处理能力
  - 清理 `SAMTOOLS_VIEW_DEDUP` 相关配置和注释
- **文档更新**: 更新 `testdatasets/README.md`，添加样本表说明、本地测试命令和缓存验证步骤
- **测试文件清理**: 移除冗余测试文件（samplesheet.csv、test_AA_local.csv、test_backcompat.csv、test_incr_lane_*.csv、test_multilane.csv），保留核心缓存测试文件

## v3.1.0 - [2026-07-27]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **样本级增量缓存**: samplesheet 支持可选 `lane` 列（`sample,fastq_1,fastq_2,lane`），使用 sample + lane 明确区分样本与 lane。有 lane 列时按 sample 列值直接分组，不再做隐式 `_T\d+` 归并，实现样本级增量/减量缓存（resume 时未变更样本的任务全部命中缓存）
- **向后兼容**: 无 lane 列时保留原有 `sample_T1`/`sample_T2` 归并逻辑，旧格式 samplesheet 行为不变
- **Picard MarkDuplicates 修复**: 在 BAM 预处理中新增 `SAMTOOLS_VIEW_DEDUP` 步骤（`-F 0x900`），过滤 secondary/supplementary alignments，避免多比对重复 read name 导致的 "Value was put into PairInfoMap more than once" 错误
- **groupTuple 分组修复**: 按 `meta.id` 字段提取分组键，修复按完整 meta map 分组导致同 sample 不同 lane 被错误拆分的问题
- **BWA_INDEX 资源配置**: test_local profile 中为 BWA_INDEX 单独配置内存（4GB），避免本地测试时 OOM kill

## v3.0.1 - [2026-07-22]

### Credits

Special thanks to the following for their input and contributions to the release:

- [siyangming](https://github.com/siyangming)

### Enhancements & fixes

- **Unicycler kmers 配置优化**: 在 `conf/test_local.config` 中添加 UNICYCLER 的 `ext.args` 覆盖配置，测试环境只使用 27kmer 进行组装，减少计算时间和资源消耗
- **参考基因组通道类型修复**: 将参考基因组的 `fasta`/`fai` 通道从 queue channel 转为 value channel（通过 `.first()`），确保所有样本共享的单一参考基因组文件能被无限次消费，修复流程第一次运行只处理一个样本的问题

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
