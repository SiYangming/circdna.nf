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
│   ├── Amaranthus_palmeri_hap1_v01.fa.gz       # 双单倍型1
│   ├── Amaranthus_palmeri_hap2_v01.fa.gz       # 双单倍型2
│   ├── Artemisia_annua_v1.fa.gz
│   ├── Cryptomeria_japonica_1.0.fa.gz
│   ├── Nicotiana_benthamiana_v1.fa.gz
│   ├── Tragopogon_porrifolius_hap1.1.fa.gz     # 双单倍型1
│   ├── Tragopogon_porrifolius_hap2.1.fa.gz     # 双单倍型2
│   ├── Beta_vulgaris.RefBeet-1.2.2.dna.fa.gz
│   ├── Lycium_ruthenicum_ASM4143038v1.fa.gz
│   └── Cynodon_dactylon_ASM4686236v1.fa.gz
├── GENE/                            # 基因注释文件（可选）
├── circdna.nf/                      # Nextflow流程代码（通过GitHub获取）
│   ├── samplesheets/                # 样本表文件
│   └── conf/server.config           # 服务器配置
└── eccDNA_results/                  # 分析结果输出目录
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

conda activate nextflow

mkdir -p /data1/users/siyangming/FASTA
mkdir -p /data1/users/siyangming/GENE
mkdir -p /data1/users/siyangming/eccDNA_results
mkdir -p /data1/users/siyangming/eccDNA_results/reports
mkdir -p /data1/users/siyangming/eccDNA_results/logs

cd /data1/users/siyangming
git clone https://github.com/SiYangming/circdna.nf.git
cd circdna.nf
```

## 2. 上传FASTA文件到服务器

```bash
rsync -avz --progress /Users/siyangming/nextflow_nf_core/circdnalr.nf/FASTA/*.fa.gz \
    siyangming@192.168.16.65:/data1/users/siyangming/FASTA/
```

## 3. 运行命令

### 3.1 通用运行命令格式

**使用 `--genome` 参数（推荐，简化）**：

```bash
screen -S circdna_Arabidopsis_thaliana
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/<samplesheet.csv> \
    --genome <genome_name> \
    --outdir /data1/users/siyangming/eccDNA_results/<species> \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/<species>_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/<species>_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/<species>_trace.txt \
    -resume
```

**使用 `--fasta` 参数（手动指定路径）**：

```bash
screen -S circdna_Arabidopsis_thaliana
nextflow run main.nf \
    --input samplesheets/<samplesheet.csv> \
    --input_format FASTQ \
    --fasta /data1/users/siyangming/FASTA/<fasta_file> \
    --outdir /data1/users/siyangming/eccDNA_results/<species> \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/<species>_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/<species>_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/<species>_trace.txt \
    -resume
```

**大基因组（>512Mb 染色体，如黑麦草、小麦）需追加 `-c conf/large_genome.config`**：

```bash
screen -S circdna_Arabidopsis_thaliana
nextflow run main.nf \
    --input samplesheets/<samplesheet.csv> \
    --genome <genome_name> \
    --outdir /data1/users/siyangming/eccDNA_results/<species> \
    -profile server \
    -c conf/large_genome.config \
    -with-report /data1/users/siyangming/eccDNA_results/reports/<species>_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/<species>_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/<species>_trace.txt \
    -resume
```

### 3.2 可用基因组列表

| Genome名称 | FASTA文件 | 物种 |
|------------|-----------|------|
| Arabidopsis_thaliana | Arabidopsis_thaliana.TAIR10.dna.fa.gz | 拟南芥 |
| Oryza_sativa | Oryza_sativa.IRGSP-1.0.dna.fa.gz | 水稻 |
| Triticum_aestivum ⚠️ | Triticum_aestivum.IWGSC.dna.fa.gz | 小麦 |
| Solanum_lycopersicum | Solanum_lycopersicum_gca000188115v5cm.SL4.0.dna.fa.gz | 番茄 |
| Daucus_carota | Daucus_carota.ASM162521v1.dna.fa.gz | 胡萝卜 |
| Helianthus_annuus | Helianthus_annuus.HanXRQr2.0-SUNRISE.dna.fa.gz | 向日葵 |
| Alopecurus_myosuroides ⚠️ | Alopecurus_myosuroides_v1.fa.gz | 黑麦草 |
| Amaranthus_palmeri_hap1 | Amaranthus_palmeri_hap1_v01.fa.gz | 苋（单倍型1） |
| Amaranthus_palmeri_hap2 | Amaranthus_palmeri_hap2_v01.fa.gz | 苋（单倍型2） |
| Artemisia_annua | Artemisia_annua_v1.fa.gz | 青蒿 |
| Cryptomeria_japonica | Cryptomeria_japonica_1.0.fa.gz | 日本柳杉 |
| Nicotiana_benthamiana | Nicotiana_benthamiana_v1.fa.gz | 本氏烟草 |
| Tragopogon_porrifolius_hap1 | Tragopogon_porrifolius_hap1.1.fa.gz | 婆罗门参（单倍型1） |
| Tragopogon_porrifolius_hap2 | Tragopogon_porrifolius_hap2.1.fa.gz | 婆罗门参（单倍型2） |
| Beta_vulgaris | Beta_vulgaris.RefBeet-1.2.2.dna.fa.gz | 甜菜 |
| Lycium_ruthenicum | Lycium_ruthenicum_ASM4143038v1.fa.gz | 黑果枸杞 |
| Cynodon_dactylon | Cynodon_dactylon_ASM4686236v1.fa.gz | 狗牙根 |

> ⚠️ 标记为大基因组物种（染色体 >512Mb），运行时需追加 `-c conf/large_genome.config` 启用 CSI 索引。

### 3.3 按物种运行命令（二代数据）

#### Arabidopsis_thaliana (拟南芥)

```bash
screen -S circdna_Arabidopsis_thaliana
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_trace.txt \
    -resume
```

#### Alopecurus_myosuroides (黑麦草) ⚠️ 大基因组

```bash
screen -S circdna_Alopecurus_myosuroides
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Alopecurus_myosuroides_eccDNA.csv \
    --genome Alopecurus_myosuroides \
    --outdir /data1/users/siyangming/eccDNA_results/Alopecurus_myosuroides \
    -profile server \
    -c conf/large_genome.config \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Alopecurus_myosuroides_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Alopecurus_myosuroides_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Alopecurus_myosuroides_trace.txt \
    -resume
```

#### Amaranthus_palmeri (苋) - 双单倍型

**hap1（单倍型1）**：

```bash
screen -S circdna_Amaranthus_palmeri_hap1
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Amaranthus_palmeri_eccDNA.csv \
    --genome Amaranthus_palmeri_hap1 \
    --outdir /data1/users/siyangming/eccDNA_results/Amaranthus_palmeri_hap1 \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Amaranthus_palmeri_hap1_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Amaranthus_palmeri_hap1_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Amaranthus_palmeri_hap1_trace.txt \
    -resume
```

**hap2（单倍型2）**：

```bash
screen -S circdna_Amaranthus_palmeri_hap2
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Amaranthus_palmeri_eccDNA.csv \
    --genome Amaranthus_palmeri_hap2 \
    --outdir /data1/users/siyangming/eccDNA_results/Amaranthus_palmeri_hap2 \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Amaranthus_palmeri_hap2_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Amaranthus_palmeri_hap2_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Amaranthus_palmeri_hap2_trace.txt \
    -resume
```

#### Artemisia_annua (青蒿)

```bash
screen -S circdna_Artemisia_annua
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Artemisia_annua_eccDNA.csv \
    --genome Artemisia_annua \
    --outdir /data1/users/siyangming/eccDNA_results/Artemisia_annua \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Artemisia_annua_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Artemisia_annua_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Artemisia_annua_trace.txt \
    -resume
```

#### Beta_vulgaris (甜菜)

```bash
screen -S circdna_Beta_vulgaris
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Beta_vulgaris_eccDNA.csv \
    --genome Beta_vulgaris \
    --outdir /data1/users/siyangming/eccDNA_results/Beta_vulgaris \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Beta_vulgaris_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Beta_vulgaris_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Beta_vulgaris_trace.txt \
    -resume
```

#### Cryptomeria_japonica (日本柳杉)

```bash
screen -S circdna_Cryptomeria_japonica
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Cryptomeria_japonica_eccDNA.csv \
    --genome Cryptomeria_japonica \
    --outdir /data1/users/siyangming/eccDNA_results/Cryptomeria_japonica \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Cryptomeria_japonica_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Cryptomeria_japonica_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Cryptomeria_japonica_trace.txt \
    -resume
```

#### Cynodon_dactylon (狗牙根)

```bash
screen -S circdna_Cynodon_dactylon
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Cynodon_dactylon_eccDNA.csv \
    --genome Cynodon_dactylon \
    --outdir /data1/users/siyangming/eccDNA_results/Cynodon_dactylon \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Cynodon_dactylon_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Cynodon_dactylon_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Cynodon_dactylon_trace.txt \
    -resume
```

#### Daucus_carota (胡萝卜)

```bash
screen -S circdna_Daucus_carota
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Daucus_carota_eccDNA.csv \
    --genome Daucus_carota \
    --outdir /data1/users/siyangming/eccDNA_results/Daucus_carota \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Daucus_carota_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Daucus_carota_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Daucus_carota_trace.txt \
    -resume
```

#### Helianthus_annuus (向日葵)

```bash
screen -S circdna_Helianthus_annuus
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Helianthus_annuus_eccDNA.csv \
    --genome Helianthus_annuus \
    --outdir /data1/users/siyangming/eccDNA_results/Helianthus_annuus \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Helianthus_annuus_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Helianthus_annuus_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Helianthus_annuus_trace.txt \
    -resume
```

#### Lycium_ruthenicum (黑果枸杞)

```bash
screen -S circdna_Lycium_ruthenicum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Lycium_ruthenicum_eccDNA.csv \
    --genome Lycium_ruthenicum \
    --outdir /data1/users/siyangming/eccDNA_results/Lycium_ruthenicum \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Lycium_ruthenicum_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Lycium_ruthenicum_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Lycium_ruthenicum_trace.txt \
    -resume
```

#### Nicotiana_benthamiana (本氏烟草)

```bash
screen -S circdna_Nicotiana_benthamiana
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Nicotiana_benthamiana_eccDNA.csv \
    --genome Nicotiana_benthamiana \
    --outdir /data1/users/siyangming/eccDNA_results/Nicotiana_benthamiana \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Nicotiana_benthamiana_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Nicotiana_benthamiana_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Nicotiana_benthamiana_trace.txt \
    -resume
```

#### Oryza_sativa (水稻)

```bash
screen -S circdna_Oryza_sativa
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Oryza_sativa_eccDNA.csv \
    --genome Oryza_sativa \
    --outdir /data1/users/siyangming/eccDNA_results/Oryza_sativa \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Oryza_sativa_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Oryza_sativa_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Oryza_sativa_trace.txt \
    -resume
```

#### Solanum_lycopersicum (番茄)

```bash
screen -S circdna_Solanum_lycopersicum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Solanum_lycopersicum_eccDNA.csv \
    --genome Solanum_lycopersicum \
    --outdir /data1/users/siyangming/eccDNA_results/Solanum_lycopersicum \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Solanum_lycopersicum_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Solanum_lycopersicum_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Solanum_lycopersicum_trace.txt \
    -resume
```

#### Tragopogon_porrifolius (婆罗门参) - 双单倍型

**hap1（单倍型1）**：

```bash
screen -S circdna_Tragopogon_porrifolius_hap1
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --genome Tragopogon_porrifolius_hap1 \
    --outdir /data1/users/siyangming/eccDNA_results/Tragopogon_porrifolius_hap1 \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_hap1_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_hap1_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_hap1_trace.txt \
    -resume
```

**hap2（单倍型2）**：

```bash
screen -S circdna_Tragopogon_porrifolius_hap2
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --genome Tragopogon_porrifolius_hap2 \
    --outdir /data1/users/siyangming/eccDNA_results/Tragopogon_porrifolius_hap2 \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_hap2_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_hap2_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Tragopogon_porrifolius_hap2_trace.txt \
    -resume
```

#### Triticum_aestivum (小麦) ⚠️ 大基因组

```bash
screen -S circdna_Triticum_aestivum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Triticum_aestivum_eccDNA.csv \
    --genome Triticum_aestivum \
    --outdir /data1/users/siyangming/eccDNA_results/Triticum_aestivum \
    -profile server \
    -c conf/large_genome.config \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Triticum_aestivum_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Triticum_aestivum_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Triticum_aestivum_trace.txt \
    -resume
```

## 4. 后台运行

### 4.1 使用nohup

```bash
screen -S circdna_Triticum_aestivum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
```

### 4.2 使用screen

```bash
screen -S circdna_Triticum_aestivum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server \
    -with-report /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_report.html \
    -with-timeline /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_timeline.html \
    -with-trace /data1/users/siyangming/eccDNA_results/reports/Arabidopsis_thaliana_trace.txt \
    -resume
# Ctrl+A+D 退出screen
# screen -r circdna_Arabidopsis 重新连接
```

## 5. 监控运行状态

```bash
screen -S circdna_Triticum_aestivum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
```

## 6. 重新运行

```bash
screen -S circdna_Triticum_aestivum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server \
    -resume
```

## 7. 批量运行脚本

```bash
screen -S circdna_Triticum_aestivum
cd nextflow_nf_core/circdna.nf/
conda activate nextflow
    nextflow run main.nf \
        --input "samplesheets/circdna_${species}_eccDNA.csv" \
        --genome "${genome}" \
        --outdir "/data1/users/siyangming/eccDNA_results/${genome}" \
        -profile server \
        -c conf/large_genome.config \
        -with-report "/data1/users/siyangming/eccDNA_results/reports/${genome}_report.html" \
        -with-timeline "/data1/users/siyangming/eccDNA_results/reports/${genome}_timeline.html" \
        -with-trace "/data1/users/siyangming/eccDNA_results/reports/${genome}_trace.txt" \
        -resume
    echo ""
    echo "========================================="
    echo "${genome} completed!"
    echo "========================================="
    echo ""
done
echo "All species processed!"
```

## 8. 注意事项

1. **FASTA文件必需**：流程运行前确保FASTA文件已上传到 `/data1/users/siyangming/FASTA/`
2. **样本数据路径**：样本表中指定的路径 `/data1/users/siyangming/eccDNA/` 需要确保数据存在于服务器上
3. **资源配置**：服务器配置为128核CPU、503GB内存，`conf/server.config` 中已优化资源分配
4. **容器选择**：使用 `-profile server`，启用Docker运行
5. **大型基因组**：小麦(Triticum_aestivum)和日本柳杉(Cryptomeria_japonica)基因组较大，需要更多内存和时间
6. **NCBI物种**：Alopecurus_myosuroides、Amaranthus_palmeri_hap1/hap2、Tragopogon_porrifolius_hap1/hap2等NCBI物种没有基因注释文件，流程可能无法进行基因注释相关的分析步骤
7. **双单倍型物种**：Amaranthus_palmeri 和 Tragopogon_porrifolius 各有 hap1 和 hap2 两个基因组版本，共用同一份样本表，但需要分别运行（`--genome` 参数和 `--outdir` 路径不同）
8. **多用户共享环境**：服务器为多人共享环境，同时运行超过2个流程可能导致线程资源耗尽（`pthread_create failed (EAGAIN)`），建议用户之间协调运行时间，或使用 `-resume` 参数错开运行
9. **进程管理规范**：禁止使用 `Ctrl+Z` 暂停流程，暂停后的进程会持续占用内存和线程资源但不工作，导致资源泄漏。应使用 `Ctrl+C` 优雅退出，Nextflow 会保存状态以便后续恢复

## 9. 僵尸进程清理指南

当流程异常退出或被暂停后，可能会产生僵尸进程占用系统资源。

### 9.1 检查僵尸进程

```bash
# 查看所有 Nextflow Java 进程
ps aux | grep nextflow | grep -v grep

# 查看进程状态（状态为 T/Tl 表示暂停/停止）
ps aux | grep nextflow | grep -v grep | awk '{print $2, $8, $11}'
```

### 9.2 终止僵尸进程

```bash
# 终止所有 Nextflow Java 进程（请谨慎使用）
kill -9 $(ps aux | grep nextflow | grep -v grep | awk '{print $2}')

# 终止特定进程
kill -9 <pid1> <pid2> <pid3>
```

### 9.3 验证清理结果

```bash
ps aux | grep nextflow | grep -v grep
```

> ⚠️ **注意**：终止进程前，请确认这些进程确实是僵尸进程，而非正在运行的流程。正常运行的流程状态应为 `R`（运行中）或 `S`（睡眠中）。

## 10. 输出结果

运行完成后，结果将保存在 `--outdir` 指定的目录中：

```
eccDNA_results/<species>/
├── multiqc_report.html      # 综合质量报告
├── pipeline_info/           # 流程信息
├── bam/                     # BAM文件
├── circle_map/              # Circle-Map结果
├── circexplorer2/           # CIRCexplorer2结果
└── fastqc/                  # FastQC报告
