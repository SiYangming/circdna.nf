# circdna.nf 服务器运行指南

## 目录结构

```
/data1/users/siyangming/
├── FASTA/                           # 参考基因组FASTA文件（直接放在此目录下）
│   ├── Arabidopsis_thaliana.TAIR10.dna.fa.gz
│   ├── Oryza_sativa.IRGSP-1.0.dna.fa.gz
│   ├── Triticum_aestivum.IWGSC.dna.fa.gz
│   ├── Solanum_lycopersicum_gca000188115v5cm.SL4.0.dna.fa.gz
│   ├── Daucus_carota.ASM162521v1.dna.fa.gz
│   ├── Helianthus_annuus.HanXRQr2.0-SUNRISE.dna.fa.gz
│   ├── Alopecurus_myosuroides_v1.fa.gz
│   ├── Amaranthus_palmeri_v01.fa.gz
│   ├── Artemisia_annua_v1.fa.gz
│   ├── Cryptomeria_japonica_1.0.fa.gz
│   ├── Nicotiana_benthamiana_v1.fa.gz
│   ├── Tragopogon_porrifolius_hap1.1.fa.gz
│   ├── Beta_vulgaris.RefBeet-1.2.2.dna.fa.gz
│   ├── Lycium_ruthenicum_ASM4143038v1.fa.gz
│   └── Cynodon_dactylon_ASM4686236v1.fa.gz
├── GENE/                            # 基因注释文件（可选）
├── circdna.nf/                      # Nextflow流程代码（通过GitHub获取）
│   ├── samplesheets/                # 样本表文件
│   └── conf/server.config           # 服务器配置
└── eccDNA_results/                         # 分析结果输出目录
```

## 服务器配置信息

| 配置项 | 值 |
|--------|-----|
| CPU | Intel Xeon Platinum 8352Y @ 2.20GHz, 128 cores |
| 内存 | 503 GB |
| 操作系统 | CentOS Linux 7 |
| Docker | 26.1.4 |
| 数据盘1 | /data1 (146T, 12T可用) |
| 数据盘2 | /data2 (117T, 6.5T可用) |

## 1. 连接服务器并准备环境

```bash
ssh siyangming@192.168.16.65

# 激活Nextflow环境
conda activate nextflow

# 创建目录结构
mkdir -p /data1/users/siyangming/FASTA
mkdir -p /data1/users/siyangming/GENE
mkdir -p /data1/users/siyangming/results
mkdir -p /data1/users/siyangming/reports

# 获取流程代码
cd /data1/users/siyangming
git clone https://github.com/SiYangming/circdna.nf.git
cd circdna.nf
```

## 2. 上传FASTA文件到服务器

```bash
# 在本地执行以下命令上传FASTA文件
rsync -avz --progress /Users/siyangming/nextflow_nf_core/circdnalr.nf/FASTA/*.fa.gz \
    siyangming@192.168.16.65:/data1/users/siyangming/FASTA/
```

## 3. 运行命令

### 3.1 通用运行命令格式（使用 --fasta 直接指定）

```bash
nextflow run main.nf \
    --input samplesheets/<samplesheet.csv> \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/<fasta_file> \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/<species> \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/<species>_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/<species>_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/<species>_trace.txt
```

### 3.2 可用基因组列表

| Genome名称 | FASTA文件 | 物种 |
|------------|-----------|------|
| Arabidopsis_thaliana | Arabidopsis_thaliana.TAIR10.dna.fa.gz | 拟南芥 |
| Oryza_sativa | Oryza_sativa.IRGSP-1.0.dna.fa.gz | 水稻 |
| Triticum_aestivum | Triticum_aestivum.IWGSC.dna.fa.gz | 小麦 |
| Solanum_lycopersicum | Solanum_lycopersicum_gca000188115v5cm.SL4.0.dna.fa.gz | 番茄 |
| Daucus_carota | Daucus_carota.ASM162521v1.dna.fa.gz | 胡萝卜 |
| Helianthus_annuus | Helianthus_annuus.HanXRQr2.0-SUNRISE.dna.fa.gz | 向日葵 |
| Alopecurus_myosuroides | Alopecurus_myosuroides_v1.fa.gz | 黑麦草 |
| Amaranthus_palmeri | Amaranthus_palmeri_v01.fa.gz | 苋 |
| Artemisia_annua | Artemisia_annua_v1.fa.gz | 青蒿 |
| Cryptomeria_japonica | Cryptomeria_japonica_1.0.fa.gz | 日本柳杉 |
| Nicotiana_benthamiana | Nicotiana_benthamiana_v1.fa.gz | 本氏烟草 |
| Tragopogon_porrifolius | Tragopogon_porrifolius_hap1.1.fa.gz | 婆罗门参 |
| Beta_vulgaris | Beta_vulgaris.RefBeet-1.2.2.dna.fa.gz | 甜菜 |
| Lycium_ruthenicum | Lycium_ruthenicum_ASM4143038v1.fa.gz | 黑果枸杞 |
| Cynodon_dactylon | Cynodon_dactylon_ASM4686236v1.fa.gz | 狗牙根 |

### 3.3 按物种运行命令（二代数据）

#### Arabidopsis_thaliana (拟南芥)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Arabidopsis_thaliana.TAIR10.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_trace.txt
```

#### Artemisia_annua (青蒿)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Artemisia_annua_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Artemisia_annua_v1.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Artemisia_annua \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Artemisia_annua_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Artemisia_annua_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Artemisia_annua_trace.txt
```

#### Cryptomeria_japonica (日本柳杉)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Cryptomeria_japonica_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Cryptomeria_japonica_1.0.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Cryptomeria_japonica \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Cryptomeria_japonica_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Cryptomeria_japonica_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Cryptomeria_japonica_trace.txt
```

#### Daucus_carota (胡萝卜)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Daucus_carota_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Daucus_carota.ASM162521v1.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Daucus_carota \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Daucus_carota_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Daucus_carota_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Daucus_carota_trace.txt
```

#### Nicotiana_benthamiana (本氏烟草)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Nicotiana_benthamiana_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Nicotiana_benthamiana_v1.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Nicotiana_benthamiana \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Nicotiana_benthamiana_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Nicotiana_benthamiana_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Nicotiana_benthamiana_trace.txt
```

#### Oryza_sativa (水稻)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Oryza_sativa_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Oryza_sativa.IRGSP-1.0.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Oryza_sativa \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Oryza_sativa_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Oryza_sativa_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Oryza_sativa_trace.txt
```

#### Tragopogon_porrifolius (婆罗门参)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Tragopogon_porrifolius_hap1.1.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Tragopogon_porrifolius \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_trace.txt
```

#### Triticum_aestivum (小麦)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Triticum_aestivum_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Triticum_aestivum.IWGSC.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Triticum_aestivum \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Triticum_aestivum_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Triticum_aestivum_timeline.html \
    --with-trace /data1/users/siyangming/eccDNA_results/reports/Triticum_aestivum_trace.txt
```

#### Beta_vulgaris (甜菜)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Beta_vulgaris_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Beta_vulgaris.RefBeet-1.2.2.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Beta_vulgaris \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Beta_vulgaris_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Beta_vulgaris_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Beta_vulgaris_trace.txt
```

#### Lycium_ruthenicum (黑果枸杞)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Lycium_ruthenicum_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Lycium_ruthenicum_ASM4143038v1.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Lycium_ruthenicum \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Lycium_ruthenicum_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Lycium_ruthenicum_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Lycium_ruthenicum_trace.txt
```

#### Cynodon_dactylon (狗牙根)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Cynodon_dactylon_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Cynodon_dactylon_ASM4686236v1.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Cynodon_dactylon \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Cynodon_dactylon_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Cynodon_dactylon_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Cynodon_dactylon_trace.txt
```

## 4. 后台运行

### 4.1 使用nohup

```bash
nohup nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Arabidopsis_thaliana.TAIR10.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_trace.txt \
    > /data1/users/siyangming/eccDNA_results/logs/Arabidopsis_thaliana.log 2>&1 &
```

### 4.2 使用screen

```bash
screen -S circdna_Arabidopsis
conda activate nextflow
cd /data1/users/siyangming/circdna.nf

nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/Arabidopsis_thaliana.TAIR10.dna.fa.gz \
    --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server

# 按 Ctrl+A+D 退出screen
# 重新连接: screen -r circdna_Arabidopsis
```

## 5. 监控运行状态

```bash
# 查看Nextflow日志
tail -f .nextflow.log

# 查看运行日志
tail -f /data1/users/siyangming/eccDNA_results/logs/<species>.log

# 查看任务状态
nextflow log

# 查看资源使用
nextflow stats
```

## 6. 重新运行

```bash
# 继续上次失败的运行
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server \
    -resume
```

## 7. 批量运行脚本

```bash
#!/bin/bash

declare -A SPECIES_MAP=(
    ["Arabidopsis_thaliana"]="Arabidopsis_thaliana.TAIR10.dna.fa.gz"
    ["Artemisia_annua"]="Artemisia_annua_v1.fa.gz"
    ["Cryptomeria_japonica"]="Cryptomeria_japonica_1.0.fa.gz"
    ["Daucus_carota"]="Daucus_carota.ASM162521v1.dna.fa.gz"
    ["Helianthus_annuus"]="Helianthus_annuus.HanXRQr2.0-SUNRISE.dna.fa.gz"
    ["Nicotiana_benthamiana"]="Nicotiana_benthamiana_v1.fa.gz"
    ["Oryza_sativa"]="Oryza_sativa.IRGSP-1.0.dna.fa.gz"
    ["Tragopogon_porrifolius"]="Tragopogon_porrifolius_hap1.1.fa.gz"
    ["Triticum_aestivum"]="Triticum_aestivum.IWGSC.dna.fa.gz"
    ["Solanum_lycopersicum"]="Solanum_lycopersicum_gca000188115v5cm.SL4.0.dna.fa.gz"
    ["Alopecurus_myosuroides"]="Alopecurus_myosuroides_v1.fa.gz"
    ["Amaranthus_palmeri"]="Amaranthus_palmeri_v01.fa.gz"
    ["Beta_vulgaris"]="Beta_vulgaris.RefBeet-1.2.2.dna.fa.gz"
    ["Lycium_ruthenicum"]="Lycium_ruthenicum_ASM4143038v1.fa.gz"
    ["Cynodon_dactylon"]="Cynodon_dactylon_ASM4686236v1.fa.gz"
)

mkdir -p /data1/users/siyangming/eccDNA_results/logs
mkdir -p /data1/users/siyangming/eccDNA_results/reports

for species in "${!SPECIES_MAP[@]}"; do
    fasta_file="${SPECIES_MAP[$species]}"

    echo "========================================="
    echo "Running ${species}..."
    echo "FASTA: ${fasta_file}"
    echo "========================================="

    nextflow run main.nf \
        --input "samplesheets/circdna_${species}_eccDNA.csv" \
        --input_format FASTQ \
        --fasta "/data1/users/siyangming/FASTA/${fasta_file}" \
        --circle_identifier 'circexplorer2,circle_finder,circle_map_realign,circle_map_repeats,unicycler' \
        --outdir "/data1/users/siyangming/eccDNA_results/${species}" \
        -profile server \
        -with-report "/data1/users/siyangming/eccDNA_results/reports/${species}_report.html" \
        -with-timeline "/data1/users/siyangming/eccDNA_results/reports/${species}_timeline.html" \
        -with-trace "/data1/users/siyangming/eccDNA_results/reports/${species}_trace.txt"

    echo ""
    echo "========================================="
    echo "${species} completed!"
    echo "========================================="
    echo ""
done

echo "All species processed!"
```

## 8. 注意事项

1. **FASTA文件必需**：流程运行前确保FASTA文件已上传到 `/data1/users/siyangming/FASTA/`
2. **样本数据路径**：样本表中指定的路径 `/data2/users/liuqi/eccdna/` 需要确保数据存在于服务器上
3. **资源配置**：服务器配置为128核CPU、503GB内存，`conf/server.config` 中已优化资源分配
4. **容器选择**：使用 `-profile server`，启用Docker运行
5. **大型基因组**：小麦(Triticum_aestivum)和日本柳杉(Cryptomeria_japonica)基因组较大，需要更多内存和时间
6. **NCBI物种**：Alopecurus_myosuroides、Amaranthus_palmeri等NCBI物种没有基因注释文件，流程可能无法进行基因注释相关的分析步骤

## 9. 输出结果

运行完成后，结果将保存在 `--outdir` 指定的目录中：

```
eccDNA_results/<species>/
├── multiqc_report.html      # 综合质量报告
├── pipeline_info/           # 流程信息
├── bam/                     # BAM文件
├── circle_map/              # Circle-Map结果
├── circexplorer2/           # CIRCexplorer2结果
└── fastqc/                  # FastQC报告
```
