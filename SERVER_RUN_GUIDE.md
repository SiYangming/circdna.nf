# circdna.nf 服务器运行指南

## 首次运行准备（仅需一次）

```bash
# 创建 screen 会话并激活环境
screen -S eccdna
conda activate nextflow
cd /data1/users/siyangming/PlanteccDNADB/circdna.nf/
```

## 按物种运行命令

> 后续操作只需 `screen -r eccdna` 恢复会话，直接运行以下命令即可（conda 环境和路径已保留）。

### 拟南芥 (Arabidopsis_thaliana)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Arabidopsis_thaliana \
    -profile server
```

### 水稻 (Oryza_sativa)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Oryza_sativa_eccDNA.csv \
    --genome Oryza_sativa \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Oryza_sativa \
    -profile server
```

### 番茄 (Solanum_lycopersicum)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Solanum_lycopersicum_eccDNA.csv \
    --genome Solanum_lycopersicum \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Solanum_lycopersicum \
    -profile server
```

### 胡萝卜 (Daucus_carota)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Daucus_carota_eccDNA.csv \
    --genome Daucus_carota \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Daucus_carota \
    -profile server
```

### 向日葵 (Helianthus_annuus)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Helianthus_annuus_eccDNA.csv \
    --genome Helianthus_annuus \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Helianthus_annuus \
    -profile server
```

### 本氏烟草 (Nicotiana_benthamiana)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Nicotiana_benthamiana_eccDNA.csv \
    --genome Nicotiana_benthamiana \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Nicotiana_benthamiana \
    -profile server
```

### 甜菜 (Beta_vulgaris)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Beta_vulgaris_eccDNA.csv \
    --genome Beta_vulgaris \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Beta_vulgaris \
    -profile server
```

### 黑果枸杞 (Lycium_ruthenicum)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Lycium_ruthenicum_eccDNA.csv \
    --genome Lycium_ruthenicum \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Lycium_ruthenicum \
    -profile server
```

### 婆罗门参 (Tragopogon_porrifolius)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --genome Tragopogon_porrifolius \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Tragopogon_porrifolius \
    -profile server
```

### 狗牙根 (Cynodon_dactylon)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Cynodon_dactylon_eccDNA.csv \
    --genome Cynodon_dactylon \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Cynodon_dactylon \
    -profile server
```

### 青蒿 (Artemisia_annua)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Artemisia_annua_eccDNA.csv \
    --genome Artemisia_annua \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Artemisia_annua \
    -profile server
```

### 苋 (Amaranthus_palmeri)

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Amaranthus_palmeri_eccDNA.csv \
    --genome Amaranthus_palmeri \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Amaranthus_palmeri \
    -profile server
```

### 黑麦草 (Alopecurus_myosuroides) — 大基因组

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Alopecurus_myosuroides_eccDNA.csv \
    --genome Alopecurus_myosuroides \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Alopecurus_myosuroides \
    -profile server \
    -c conf/large_genome.config
```

### 日本柳杉 (Cryptomeria_japonica) — 大基因组

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Cryptomeria_japonica_eccDNA.csv \
    --genome Cryptomeria_japonica \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Cryptomeria_japonica \
    -profile server \
    -c conf/large_genome.config
```

### 小麦 (Triticum_aestivum) — 大基因组

```bash
nextflow run main.nf \
    --input samplesheets/circdna_Triticum_aestivum_eccDNA.csv \
    --genome Triticum_aestivum \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/Triticum_aestivum \
    -profile server \
    -c conf/large_genome.config
```

## 常用操作

```bash
# 查看所有 screen 会话
screen -ls

# 恢复会话（后续操作只需这一步，conda 环境和路径已保留）
screen -r eccdna

# Ctrl+A+D 退出 screen（会话保持运行）

# 查看运行日志
tail -f /data1/users/siyangming/PlanteccDNADB/eccDNA_results/reports/<species>_trace.txt

# 恢复运行示例
screen -r eccdna
nextflow run main.nf \
    --input samplesheets/circdna_<species>_eccDNA.csv \
    --genome <species> \
    --outdir /data1/users/siyangming/PlanteccDNADB/eccDNA_results/<species> \
    -profile server \
    -resume
```

## 注意事项

- FASTA文件需已上传至 `/data1/users/siyangming/FASTA/`
- 样本数据需存在于样本表指定路径 `/data1/users/siyangming/PlanteccDNADB/eccDNA/`
- 大基因组（小麦、日本柳杉、黑麦草）需添加 `-c conf/large_genome.config` 参数
- `circle_identifier`、`input_format` 等参数已在 `conf/server.config` 中配置，无需在命令中指定
- **screen 会话和 conda 环境仅需首次设置一次**，后续 `screen -r eccdna` 恢复即可直接运行命令
- **清理旧 work 目录权限问题**: 如果之前运行未配置 `-u` 参数，work 目录中可能存在 root 权限文件无法删除。使用以下命令清理：
  ```bash
  sudo rm -rf work/
  # 或无需 sudo（通过 Docker 容器删除）：
  docker run --rm -v $(pwd):/work -w /work alpine rm -rf work/
  ```
