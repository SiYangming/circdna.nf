# circdna.nf 服务器运行指南

## 连接服务器

```bash
ssh siyangming@192.168.16.65
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
```

## 同步FASTA文件到服务器

```bash
rsync -avz --progress /Users/siyangming/nextflow_nf_core/circdnalr.nf/FASTA/*.fa.gz \
    siyangming@192.168.16.65:/data1/users/siyangming/FASTA/
```

## 按物种运行命令

### 拟南芥 (Arabidopsis_thaliana)

```bash
screen -S circdna_Arabidopsis
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir /data1/users/siyangming/eccDNA_results/Arabidopsis_thaliana \
    -profile server
```

### 水稻 (Oryza_sativa)

```bash
screen -S circdna_Oryza
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Oryza_sativa_eccDNA.csv \
    --genome Oryza_sativa \
    --outdir /data1/users/siyangming/eccDNA_results/Oryza_sativa \
    -profile server
```

### 番茄 (Solanum_lycopersicum)

```bash
screen -S circdna_Solanum
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Solanum_lycopersicum_eccDNA.csv \
    --genome Solanum_lycopersicum \
    --outdir /data1/users/siyangming/eccDNA_results/Solanum_lycopersicum \
    -profile server
```

### 胡萝卜 (Daucus_carota)

```bash
screen -S circdna_Daucus
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Daucus_carota_eccDNA.csv \
    --genome Daucus_carota \
    --outdir /data1/users/siyangming/eccDNA_results/Daucus_carota \
    -profile server
```

### 向日葵 (Helianthus_annuus)

```bash
screen -S circdna_Helianthus
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Helianthus_annuus_eccDNA.csv \
    --genome Helianthus_annuus \
    --outdir /data1/users/siyangming/eccDNA_results/Helianthus_annuus \
    -profile server
```

### 本氏烟草 (Nicotiana_benthamiana)

```bash
screen -S circdna_Nicotiana
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Nicotiana_benthamiana_eccDNA.csv \
    --genome Nicotiana_benthamiana \
    --outdir /data1/users/siyangming/eccDNA_results/Nicotiana_benthamiana \
    -profile server
```

### 甜菜 (Beta_vulgaris)

```bash
screen -S circdna_Beta
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Beta_vulgaris_eccDNA.csv \
    --genome Beta_vulgaris \
    --outdir /data1/users/siyangming/eccDNA_results/Beta_vulgaris \
    -profile server
```

### 黑果枸杞 (Lycium_ruthenicum)

```bash
screen -S circdna_Lycium
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Lycium_ruthenicum_eccDNA.csv \
    --genome Lycium_ruthenicum \
    --outdir /data1/users/siyangming/eccDNA_results/Lycium_ruthenicum \
    -profile server
```

### 婆罗门参 (Tragopogon_porrifolius)

```bash
screen -S circdna_Tragopogon
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --genome Tragopogon_porrifolius \
    --outdir /data1/users/siyangming/eccDNA_results/Tragopogon_porrifolius \
    -profile server
```

### 狗牙根 (Cynodon_dactylon)

```bash
screen -S circdna_Cynodon
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Cynodon_dactylon_eccDNA.csv \
    --genome Cynodon_dactylon \
    --outdir /data1/users/siyangming/eccDNA_results/Cynodon_dactylon \
    -profile server
```

### 青蒿 (Artemisia_annua)

```bash
screen -S circdna_Artemisia
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Artemisia_annua_eccDNA.csv \
    --genome Artemisia_annua \
    --outdir /data1/users/siyangming/eccDNA_results/Artemisia_annua \
    -profile server
```

### 苋 (Amaranthus_palmeri)

```bash
screen -S circdna_Amaranthus
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Amaranthus_palmeri_eccDNA.csv \
    --genome Amaranthus_palmeri \
    --outdir /data1/users/siyangming/eccDNA_results/Amaranthus_palmeri \
    -profile server
```

### 黑麦草 (Alopecurus_myosuroides) — 大基因组

```bash
screen -S circdna_Alopecurus
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Alopecurus_myosuroides_eccDNA.csv \
    --genome Alopecurus_myosuroides \
    --outdir /data1/users/siyangming/eccDNA_results/Alopecurus_myosuroides \
    -profile server \
    -c conf/large_genome.config
```

### 日本柳杉 (Cryptomeria_japonica) — 大基因组

```bash
screen -S circdna_Cryptomeria
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Cryptomeria_japonica_eccDNA.csv \
    --genome Cryptomeria_japonica \
    --outdir /data1/users/siyangming/eccDNA_results/Cryptomeria_japonica \
    -profile server \
    -c conf/large_genome.config
```

### 小麦 (Triticum_aestivum) — 大基因组

```bash
screen -S circdna_Triticum
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_Triticum_aestivum_eccDNA.csv \
    --genome Triticum_aestivum \
    --outdir /data1/users/siyangming/eccDNA_results/Triticum_aestivum \
    -profile server \
    -c conf/large_genome.config
```

## 常用操作

```bash
screen -ls

screen -r <session_name>

# Ctrl+A+D 退出screen

tail -f /data1/users/siyangming/eccDNA_results/reports/<species>_trace.txt

screen -S circdna_<species>
conda activate nextflow
cd /data1/users/siyangming/nextflow_nf_core/circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_<species>_eccDNA.csv \
    --genome <species> \
    --outdir /data1/users/siyangming/eccDNA_results/<species> \
    -profile server \
    -resume
```

## 注意事项

- FASTA文件需已上传至 `/data1/users/siyangming/FASTA/`
- 样本数据需存在于样本表指定路径 `/data1/users/siyangming/eccDNA/`
- 大基因组（小麦、日本柳杉、黑麦草）需添加 `-c conf/large_genome.config` 参数
- `circle_identifier`、`input_format` 等参数已在 `conf/server.config` 中配置，无需在命令中指定