# test-datasets: `circdna`

This branch contains test data to be used for automated testing with the [nf-core/circdna](https://github.com/nf-core/circdna) pipeline.

## Content of this repository

`reference/`: Genome reference files (iGenomes R64-1-1 Ensembl release)

`testdata/` : 200,000 FastQ paired-end reads

`samplesheet/` : Sample sheet CSV files for testing

### Sample sheet files

| File | Description |
|------|-------------|
| `test_local_eccdna.csv` | Default local test input (3 samples) |
| `test_3.csv` | 3 samples - baseline test |
| `test_4.csv` | 4 samples - incremental cache test (+1 sample) |
| `test_2.csv` | 2 samples - decremental cache test (-1 sample) |
| `test_mixed.csv` | 3 samples - mixed cache test (-1+1 sample) |

## Local Testing

### Prerequisites

- Conda environment with Nextflow and required tools
- Execute: `conda activate nextflow`

### Test Commands

```bash
# Navigate to project directory
cd /Users/siyangming/nextflow_nf_core/circdna.nf

# Clean previous results
rm -rf results_testdata nextflow_work

# Run 1: Initial run (3 samples)
nextflow run main.nf \
  -profile test_local \
  --input samplesheets/test_3.csv \
  --outdir results_testdata/run1 \
  -work-dir ./nextflow_work \
  -with-trace results_testdata/trace_run1.txt

# Run 2: Incremental cache test (4 samples, resume)
nextflow run main.nf \
  -profile test_local \
  --input samplesheets/test_4.csv \
  --outdir results_testdata/run2 \
  -work-dir ./nextflow_work \
  -resume \
  -with-trace results_testdata/trace_run2.txt

# Run 3: Decremental cache test (2 samples, resume)
nextflow run main.nf \
  -profile test_local \
  --input samplesheets/test_2.csv \
  --outdir results_testdata/run3 \
  -work-dir ./nextflow_work \
  -resume \
  -with-trace results_testdata/trace_run3.txt

# Run 4: Mixed cache test (3 samples, -1+1, resume)
nextflow run main.nf \
  -profile test_local \
  --input samplesheets/test_mixed.csv \
  --outdir results_testdata/run4 \
  -work-dir ./nextflow_work \
  -resume \
  -with-trace results_testdata/trace_run4.txt
```

### Cache Verification

```bash
# Analyze cache behavior across runs
for i in 1 2 3 4; do
  echo "=== Run $i ==="
  echo "CACHED: $(grep -c 'CACHED' results_testdata/trace_run${i}.txt 2>/dev/null || echo 0)"
  echo "NEW: $(grep -c 'COMPLETED' results_testdata/trace_run${i}.txt 2>/dev/null || echo 0)"
done
```

### Expected Cache Behavior

| Run | Change | Expected Cached | Expected New |
|-----|--------|-----------------|--------------|
| Run 1 | Initial 3 samples | - | All tasks |
| Run 2 | +1 sample | circdna_1/2/3 tasks | circdna_4 + summary tasks |
| Run 3 | -1 sample | circdna_1/2 tasks | Summary tasks |
| Run 4 | -1+1 samples | circdna_1 tasks | circdna_3/4 + summary tasks |

## Slim Mode Testing (ECCsplorer_slim + ecc_finder_slim)

Slim 模式将 ECCsplorer 和 ecc_finder 拆分为原子化模块（Docker 独立），外部工具（bwa/samtools/segemehl/genrich/tidehunter/unicycler）使用 nf-core 标准镜像，专有逻辑脚本使用最小化 slim 镜像。

### Docker 镜像

| 镜像 | 大小 | 用途 |
|------|------|------|
| `quay.io/bioinfortools/eccsplorer_slim:1.0.0` | 1.25 GB | ECCsplorer 6 个专有分析脚本（Python+R） |
| `quay.io/bioinfortools/ecc_finder_slim:1.0.0` | 1.06 GB | ecc_finder merge_score + asm_filter 脚本 |
| `quay.io/biocontainers/genrich:0.6.1--h577a1d6_5` | ~6 MB | Genrich peak calling |
| `quay.io/biocontainers/tidehunter:1.5.6--h7f5d12c_0` | ~15 MB | TideHunter split-read 检测 |
| `quay.io/biocontainers/segemehl:0.3.4--hc2ea5fd_5` | ~50 MB | Segemehl + haarz（共用镜像） |

### Conda 包

```bash
conda install -c yangmingsi eccsplorer_slim=1.0.0 ecc_finder_slim=1.0.0
```

### circle_identifier 参数

| 值 | 含义 |
|------|------|
| `eccsplorer_map_slim` | ECCsplorer MAP 模式（segemehl → haarz → peak_detect → 完整分析链） |
| `ecc_finder_map_sr_slim` | ecc_finder MAP_SR 模式（Genrich → TideHunter → merge_score） |
| `ecc_finder_asm_sr_slim` | ecc_finder ASM_SR 模式（unicycler → asm_filter） |

可逗号组合，例如 `--circle_identifier 'eccsplorer_map_slim,ecc_finder_map_sr_slim,ecc_finder_asm_sr_slim'`

### Docker 测试命令

```bash
cd /Users/siyangming/nextflow_nf_core/circdna.nf

# 确保所有镜像已拉取
docker pull quay.io/bioinfortools/eccsplorer_slim:1.0.0
docker pull quay.io/bioinfortools/ecc_finder_slim:1.0.0
docker pull quay.io/biocontainers/genrich:0.6.1--h577a1d6_5
docker pull quay.io/biocontainers/tidehunter:1.5.6--h7f5d12c_0

# 运行 slim 完整测试
nextflow run main.nf \
  -profile test_local,docker \
  --input samplesheets/test_3.csv \
  --circle_identifier 'eccsplorer_map_slim,ecc_finder_map_sr_slim,ecc_finder_asm_sr_slim' \
  --outdir results_testdata/slim_run
```

### Stub 验证命令

```bash
# 快速编译验证（无需工具安装）
nextflow run main.nf \
  -profile test_local -stub \
  --input samplesheets/test_3.csv \
  --circle_identifier 'eccsplorer_map_slim,ecc_finder_map_sr_slim,ecc_finder_asm_sr_slim'

# 验证 slim 进程是否正确创建（预期 16 个）
grep "Creating process.*SLIM" .nextflow.log | awk -F"'" '{print $2}' | awk -F":" '{print $NF}' | sort -u
```

预期输出 16 个进程：`ECCSPLORER_PEAK_DETECT`, `ECCSPLORER_CANDIDATE_EXTRACT`, `ECCSPLORER_COVERAGE_PROFILE`, `ECCSPLORER_NORMALIZE`, `ECCSPLORER_VISUALIZE`, `ECCSPLORER_HTML_REPORT`, `ECC_FINDER_MERGE_SCORE`, `ECC_FINDER_ASM_FILTER`, `GENRICH`, `TIDEHUNTER`, `HAARZ`, `SEGEMEHL_INDEX`, `SEGEMEHL_ALIGN`, `SAMTOOLS_SORT_NAME`, `SAMTOOLS_INDEX`, `UNICYCLER`

### 模块位置

Slim 自定义模块位于 `circdna.nf/modules/local/`：

```
modules/local/
├── genrich/           # Genrich peak calling
├── tidehunter/        # TideHunter split-read
├── haarz/             # HaarZ split-read (segemehl 子工具)
├── ecc_finder_slim/
│   ├── merge_score/   # 富集+split-read 合并打分
│   └── asm_filter/    # 组装过滤
└── eccsplorer_slim/
    ├── peak_detect/   # scipy 峰检测
    ├── candidate_extract/  # bedtools 候选区求交
    ├── coverage_profile/   # per-base 覆盖度
    ├── normalize/     # RPM + fold enrichment (R)
    ├── visualize/     # Manhattan + candidate plots (R)
    └── html_report/   # HTML 报告
```

## Minimal test dataset origin

The data set was generated using Circle-Map Simulate (see [Circle-Map](https://github.com/iprada/Circle-Map). Circle-Map simulated 400,000 paired-end reads originated from circle-seq data of the reference genome.

### Data Generation

The example below was used to generate the raw paired-end FastQ files.

```bash
Circle-Map Simulate -c 50 -g genome.fa -N 400000 -r 150 -b cm_1 -p 10
mv simulated.bed circdna_1_simulated.bed
Circle-Map Simulate -c 50 -g genome.fa -N 400000 -r 150 -b cm_2 -p 10
mv simulated.bed circdna_2_simulated.bed
Circle-Map Simulate -c 50 -g genome.fa -N 400000 -r 150 -b cm_3 -p 10
mv simulated.bed circdna_3_simulated.bed
gzip *.fastq
```

#### Modification of Read IDs

Circle-Map sometimes creates read ids multiple times. Therefore, the read ids were made unique using awk.

```bash
zcat cm_1_1.fastq.gz | awk '{a++; if((a-1)%4==0){print $1 "|READ:ID=" a } else if(a==1){print $1 "|" a} else {print $0}}' | gzip > circdna_1_R1.fastq.gz
zcat cm_1_2.fastq.gz | awk '{a++; if((a-1)%4==0){print $1 "|READ:ID=" a } else if(a==1){print $1 "|" a} else {print $0}}' | gzip > circdna_1_R2.fastq.gz
zcat cm_2_1.fastq.gz | awk '{a++; if((a-1)%4==0){print $1 "|READ:ID=" a } else if(a==1){print $1 "|" a} else {print $0}}' | gzip > circdna_2_R1.fastq.gz
zcat cm_2_2.fastq.gz | awk '{a++; if((a-1)%4==0){print $1 "|READ:ID=" a } else if(a==1){print $1 "|" a} else {print $0}}' | gzip > circdna_2_R2.fastq.gz
zcat cm_3_1.fastq.gz | awk '{a++; if((a-1)%4==0){print $1 "|READ:ID=" a } else if(a==1){print $1 "|" a} else {print $0}}' | gzip > circdna_3_R1.fastq.gz
zcat cm_3_2.fastq.gz | awk '{a++; if((a-1)%4==0){print $1 "|READ:ID=" a } else if(a==1){print $1 "|" a} else {print $0}}' | gzip > circdna_3_R2.fastq.gz
```

### Expected output

To track and test the reproducibility of the pipeline with default parameters below are some of the expected outputs.

### Number of `Circle-Map Realign` circles

| sample    | circles |
| --------- | ------- |
| circdna_1 | 9404    |
| circdna_2 | 8697    |
| circdna_3 | 9195    |

### Number of `Circle-Map Repeats` circles

| sample    | circles |
| --------- | ------- |
| circdna_1 | 13      |
| circdna_2 | 11      |
| circdna_3 | 8       |

### Number of `Circexplorer2` circles

| sample    | circles |
| --------- | ------- |
| circdna_1 | 10125   |
| circdna_2 | 9423    |
| circdna_3 | 9894    |

### Number of `circle_finder` circles

| sample    | circles |
| --------- | ------- |
| circdna_1 | 8227    |
| circdna_2 | 7681    |
| circdna_3 | 8075    |

### Number of `unicycler` lines

Minimap2 generates a `paf` file from the unicycler output. Here are the number of lines in each `paf` file generated from the test-data. A `paf` file contains output mapping information of the circular DNAs identified by Unicycler.

| sample    | lines |
| --------- | ----- |
| circdna_1 | 70    |
| circdna_2 | 68    |
| circdna_3 | 64    |

These are just guidelines and will change with the use of different software, and with any restructuring of the pipeline away from the current defaults.


---

## Long-Read Test Datasets (v4.1+)

真实 ONT 和 PacBio 长读长 eccDNA 测试数据，用于验证长读长流水线模块（minimap2 比对、TideHunter/Genrich 串联重复检测、cd-hit 聚类等）。

### 数据来源

| 平台 | 样本 | 物种 | 基因组大小 | 来源 SRA | 实验类型 |
|------|------|------|-----------|----------|----------|
| ONT | SRR24335762 | *Arabidopsis thaliana* | ~135 Mb | PRJNA961124 | mobilome-seq eccDNA |
| PacBio | ERR11838731 | *Oryza sativa* | ~430 Mb | PRJEB59090 | HiFi WGS (reference) |

ONT 样本为 eccDNA 富集实验（RCA 扩增后测序）；PacBio 样本为水稻 HiFi WGS 背景数据，用于验证长读长比对/索引路径。

### 三档测试数据

基于本地环境（macOS arm64 + Docker 仿真 amd64，性能约降 2-3 倍）与长读长工具特性（minimap2 快、TideHunter/Genrich 中等、cd-hit 快）设计三档：

#### ONT 测试数据

| 档位 | 文件名 | 提取量 | 文件大小 | 本地预计耗时 | 用途 |
|------|--------|--------|----------|-------------|------|
| 冒烟 | `ont/ont_eccdna_smoke.fastq.gz` | 1,500 条 | ~6.5 MB | 5-15 分钟 | 验证流水线跑通、模块接线、输出非空 |
| 常规验证 | `ont/ont_eccdna_regular.fastq.gz` | 7,500 条 | ~32 MB | 30-90 分钟 | 验证能检出串联重复候选 |
| 一致性对比 | `ont/ont_eccdna_consistency.fastq.gz` | 30,000 条 | ~127 MB | 2-6 小时 | 完整版产物对比（本地生成） |

源文件: 196,317 reads, avg 4,587 bp, max 115 kb

#### PacBio 测试数据

| 档位 | 文件名 | 提取量 | 文件大小 | 本地预计耗时 | 用途 |
|------|--------|--------|----------|-------------|------|
| 冒烟 | `pacbio/pacbio_eccdna_smoke.fastq.gz` | 1,500 条 | ~25 MB | 5-15 分钟 | 验证流水线跑通、模块接线、输出非空 |
| 常规验证 | `pacbio/pacbio_eccdna_regular.fastq.gz` | 2,500 条 | ~41 MB | 30-90 分钟 | 验证长读长比对/索引路径 |
| 一致性对比 | `pacbio/pacbio_eccdna_consistency.fastq.gz` | 15,000 条 | ~246 MB | 2-6 小时 | 完整版产物对比（本地生成） |

源文件: ERR11838731 (6.4 GB gzipped), PacBio HiFi WGS, avg ~18.6 kb

### 提取方式

使用 `seqkit sample` 从源文件中随机抽样，保留整条 read，按条数控制规模。固定随机种子 `-s 42` 保证可重现。

```bash
# 重新提取（如需调整档位）
bash circdna.nf/testdatasets/extract_test_data.sh
```

脚本 [`extract_test_data.sh`](extract_test_data.sh) 包含完整提取逻辑，支持跳过已存在的文件。

### 样本表 (Samplesheet)

| 文件 | 描述 |
|------|------|
| `samplesheets/test_ont.csv` | ONT 三档测试样本表（单端 long_read） |
| `samplesheets/test_pacbio.csv` | PacBio 三档测试样本表（单端 long_read） |

格式兼容 `check_samplesheet.py`，自动检测 `single_end=1`（fastq_2 为空）。

```csv
sample,fastq_1,fastq_2,platform,protocol
ont_eccdna_smoke,/path/to/ont_eccdna_smoke.fastq.gz,,ont,long_read
```

### 本地测试命令

```bash
# ONT 冒烟测试（推荐起步）
nextflow run main.nf \
  -profile test_local \
  --input samplesheets/test_ont.csv \
  --outdir results_ont_smoke \
  --mode eccdna

# PacBio 冒烟测试
nextflow run main.nf \
  -profile test_local \
  --input samplesheets/test_pacbio.csv \
  --outdir results_pacbio_smoke \
  --mode eccdna
```

### 注意事项

- 完整版 map-ont 对 read 有最小长度过滤（`-q/-a` 默认 200 bp），真实 ONT/PacBio read 全长均满足，无需预处理
- 样本量过小（<500 条）可能因串联重复 reads 太少而检不出候选，建议至少 1,000 条起步
- PacBio CIDER-seq reads 来自 Amaranthus palmeri（基因组 ~700 Mb），比 Arabidopsis 大，但 eccDNA circles 大小不受基因组限制
- 若需对照 WGS 背景，可使用已有的 Illumina 短读测试数据（`testdata/` 目录下 `gdna_1` 样本）

---

## 服务器全量测试命令（circdnalr 分支）

服务器环境：192.168.16.65，项目路径 `/data1/users/siyangming/PlanteccDNADB/circdna.nf`，nextflow 26.04.6（conda env `nextflow`），docker 26.1.4。

### 注意事项（重要）

- **SSH 执行命令必须先加载 conda 再 cd**：服务器 `~/.bashrc` 第 12 行含 `cd /data1/users/siyangming`，若先 `cd` 再 `source ~/.bashrc` 会被切走目录导致 `Cannot find script file: main.nf`。正确顺序：
  ```bash
  ssh 192.168.16.65 "source ~/.bashrc 2>/dev/null; conda activate nextflow; cd /data1/users/siyangming/PlanteccDNADB/circdna.nf && nextflow run ..."
  ```
- **`ps` 硬依赖**：nextflow ≥26 的 `.command.run` 每个任务硬检查容器内 `command -v ps`。黑盒镜像（`ecc_finder:1.0.0`）必须含 `procps`，否则 stub 与真实运行都会失败（exit 1）。
- **不要改 master 分支**：以下测试均在 `circdnalr` 分支进行。

### 1. 同步服务器代码到最新

```bash
ssh 192.168.16.65
cd /data1/users/siyangming/PlanteccDNADB/circdna.nf
git fetch origin
git checkout circdnalr
git merge --ff-only origin/circdnalr
```

### 2. Stub 全量测试（slim 链，68 任务，~1 分钟）

覆盖 eccsplorer_map_slim + ecc_finder 短读，快速编译验证整条链路：

```bash
ssh 192.168.16.65 "source ~/.bashrc 2>/dev/null; conda activate nextflow; cd /data1/users/siyangming/PlanteccDNADB/circdna.nf && nextflow run main.nf -profile test_local,docker -stub-run --input samplesheets/test_local_gdna_single.csv --fasta testdatasets/reference/genome.fa --outdir results/test_stub_full"
```

预期：`Pipeline completed successfully`，68 个任务全部 Succeeded。

### 3. 真实数据测试（slim ECCsplorer gdna 对照，单样本，62 任务，~7 分钟）

```bash
ssh 192.168.16.65 "source ~/.bashrc 2>/dev/null; conda activate nextflow; cd /data1/users/siyangming/PlanteccDNADB/circdna.nf && nextflow run main.nf -profile test_local_gdna,docker --circle_identifier eccsplorer_map_slim --input samplesheets/test_local_gdna_single.csv --fasta testdatasets/reference/genome.fa --eccsplorer_database testdatasets/eccsplorer_db/eccsplorer_db.fa --outdir results/test_real_slim"
```

预期：62 任务全部 Succeeded；候选结果 `results/test_real_slim/eccsplorer_slim/candidates/circdna_1_hiconf-ECC-REGIONS.bed`（81 行）。

### 4. 黑盒 ecc_finder stub 测试（map_sr，修复 ps 后）

```bash
ssh 192.168.16.65 "source ~/.bashrc 2>/dev/null; conda activate nextflow; cd /data1/users/siyangming/PlanteccDNADB/circdna.nf && nextflow run main.nf -profile test_local,docker -stub-run --circle_identifier ecc_finder_map_sr --input samplesheets/test_local_gdna_single.csv --fasta testdatasets/reference/genome.fa --outdir results/test_stub_blackbox"
```

### 5. 长读链 stub 测试（PacBio / ONT）

```bash
# PacBio
ssh 192.168.16.65 "source ~/.bashrc 2>/dev/null; conda activate nextflow; cd /data1/users/siyangming/PlanteccDNADB/circdna.nf && nextflow run main.nf -profile test_pacbio_lr,docker -stub-run --outdir results/test_stub_pacbio"

# ONT (Nanopore)
ssh 192.168.16.65 "source ~/.bashrc 2>/dev/null; conda activate nextflow; cd /data1/users/siyangming/PlanteccDNADB/circdna.nf && nextflow run main.nf -profile test_nanopore_lr,docker -stub-run --outdir results/test_stub_nanopore"
```

### 6. 重建并推送黑盒 ecc_finder 镜像（含 procps）

仅在修改 `/data1/users/siyangming/ecc_finder_orig_build/Dockerfile` 后需要（如 apt 依赖变更）：

```bash
ssh 192.168.16.65 "cd /data1/users/siyangming/ecc_finder_orig_build && docker build -t quay.io/bioinfortools/ecc_finder:1.0.0 . && docker push quay.io/bioinfortools/ecc_finder:1.0.0"
```

Dockerfile 对应本地文件：`.trae/build/ecc_finder_apt/Dockerfile`。当前版本 apt 安装含 `procps`（解决 nextflow 任务 `ps` 缺失）。

### 7. 已修复问题记录

| 问题 | 现象 | 修复 |
|------|------|------|
| 黑盒镜像缺 `ps` | 所有 ecc_finder 黑盒模块（map_sr/asm_sr/map_ont/asm_ont）exit 1，报 `Command 'ps' required by nextflow` | Dockerfile apt 加 `procps`，重建推送镜像 |
| bwa_index meta 非 Map | `ECC_FINDER_MAP_SR` finalizing 报 `No such property: id for class: java.lang.String` | `workflows/circdna.nf` 3 处改为 `[[id: 'bwa_index'], index]` |
| FLED 缺 stub 块 | stub 模式仍真实运行 minimap2（71s） | 补充 stub 块 |
| FLED cat 不健壮 | 无多片段 eccDNA 时 `MulsegFullJunction.out` 不存在，`cat` exit 1 | 分两次 `cat` 加 `2>/dev/null` 容错 |
| FLED output 依赖 script 局部变量 | stub 模式 `No such variable: prefix` | output 路径改内联 `task.ext.prefix ?: meta.id` |
| `.bashrc` 含 `cd` | 先 cd 再 source 会切走目录，`Cannot find script file` | SSH 命令先 source 再 cd |

### 8. 测试日志位置（服务器 /tmp）

| 日志 | 内容 | 结果 |
|------|------|------|
| `/tmp/stub_full.log` | slim stub 全量 | 68 任务成功 |
| `/tmp/real_slim.log` | 真实 slim gdna 对照 | 62 任务成功 |
| `/tmp/stub_blackbox.log` | 黑盒 stub（修复前） | 失败（ps 缺失） |
| `/tmp/stub_blackbox2.log` | 黑盒 stub（修复后） | 成功 |
| `/tmp/stub_pacbio2.log` | PacBio 长读 stub（修复后） | 成功 |
| `/tmp/stub_nanopore2.log` | ONT 长读 stub（修复后） | 成功 |
| `/tmp/ecc_finder_build.log` | 镜像构建 | 成功 |
| `/tmp/ecc_finder_push.log` | 镜像推送 | 成功 |

