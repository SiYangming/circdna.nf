# circdna.nf 服务器运行指南

## Screen 会话管理

> **首次使用 screen 只需配置一次**，后续通过 `screen -r eccdna` 恢复

```bash
# 创建 screen 会话 (首次)
screen -S eccdna

# 恢复 screen 会话 (每次登录服务器后)
screen -r eccdna

# 列出所有 screen 会话
screen -ls

# 从 screen 会话分离 (保持运行)
# 快捷键: Ctrl+A+D

# 重新连接到已分离的会话
screen -r eccdna
```

## 环境先决条件

> **每次进入 screen 会话后必须执行**，否则会出现 `nextflow: 未找到命令` 错误

```bash
# 1. 激活 conda 环境 (nextflow 命令仅在此环境中可用)
conda activate nextflow

# 2. 进入父目录 (所有操作在此目录下执行)
cd /data1/users/siyangming/PlanteccDNADB/

# 3. 验证环境
which nextflow    # 应输出 conda 环境中的 nextflow 路径
nextflow -version # 应显示 Nextflow 版本

# 4. 确认目录结构
ls
# 应包含: circdna.nf/  eccDNA/  eccDNA_results/
```

### 首次完整设置（仅需一次）

```bash
# Step 1: 创建并进入 screen
screen -S eccdna

# Step 2: 激活环境并进入目录
conda activate nextflow
cd /data1/users/siyangming/PlanteccDNADB/

# Step 3: 保存环境变量到 screen 会话 (可选，避免每次重复)
# conda env config set auto_activate_base false
# echo 'conda activate nextflow' >> ~/.bashrc
# echo 'cd /data1/users/siyangming/PlanteccDNADB/' >> ~/.bashrc

# Step 4: 分离会话
# Ctrl+A+D

# Step 5: 验证恢复
screen -r eccdna
# 应该自动在 nextflow 环境和 PlanteccDNADB 目录中
```

## 路径约定

所有命令在 `/data1/users/siyangming/PlanteccDNADB/` 父目录下执行，使用 `circdna.nf/` 前缀引用 pipeline 文件：

```bash
# 父目录结构
PlanteccDNADB/
├── circdna.nf/          # Pipeline 代码 (nextflow run ./circdna.nf/main.nf)
│   ├── main.nf
│   ├── nextflow.config
│   ├── samplesheets/    # circdna.nf/samplesheets/*.csv
│   ├── conf/            # circdna.nf/conf/server.config
│   └── ...
├── eccDNA/              # 测序数据
└── eccDNA_results/      # 输出结果
```

## 恢复运行

```bash
# 必须指定具体的 run name，否则 -resume 会尝试恢复最近一次运行
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_<species>_eccDNA.csv \
    --genome <species> \
    --outdir eccDNA_results/<species> \
    -profile server \
    -resume <run_name>

# 查看历史 run name
ls -lat circdna.nf/work/ | head -5
# 或查看 .nextflow.log 开头
head -5 circdna.nf/.nextflow.log
```

## 按物种运行命令

> 假设已在 `PlanteccDNADB/` 目录内，且 `conda activate nextflow` 已执行

### 拟南芥 (Arabidopsis_thaliana)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Arabidopsis_thaliana_eccDNA.csv \
    --genome Arabidopsis_thaliana \
    --outdir eccDNA_results/Arabidopsis_thaliana \
    -profile server
```

### 水稻 (Oryza_sativa)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Oryza_sativa_eccDNA.csv \
    --genome Oryza_sativa \
    --outdir eccDNA_results/Oryza_sativa \
    -profile server
```

### 番茄 (Solanum_lycopersicum)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Solanum_lycopersicum_eccDNA.csv \
    --genome Solanum_lycopersicum \
    --outdir eccDNA_results/Solanum_lycopersicum \
    -profile server
```

### 胡萝卜 (Daucus_carota)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Daucus_carota_eccDNA.csv \
    --genome Daucus_carota \
    --outdir eccDNA_results/Daucus_carota \
    -profile server
```

### 本氏烟草 (Nicotiana_benthamiana)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Nicotiana_benthamiana_eccDNA.csv \
    --genome Nicotiana_benthamiana \
    --outdir eccDNA_results/Nicotiana_benthamiana \
    -profile server
```

### 甜菜 (Beta_vulgaris)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Beta_vulgaris_eccDNA.csv \
    --genome Beta_vulgaris \
    --outdir eccDNA_results/Beta_vulgaris \
    -profile server
```

### 黑果枸杞 (Lycium_ruthenicum)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Lycium_ruthenicum_eccDNA.csv \
    --genome Lycium_ruthenicum \
    --outdir eccDNA_results/Lycium_ruthenicum \
    -profile server
```

### 婆罗门参 (Tragopogon_porrifolius) — 双单倍型 (hap1/hap2)，hap1 为大基因组

> 该物种存在 hap1、hap2 两个单倍型基因组，需分别运行；`--genome` 值必须为 `Tragopogon_porrifolius_hap1` / `Tragopogon_porrifolius_hap2`（对应 server.config 中的 genome 键）
> hap1 参考序列长度超过 BAI 索引上限（约 512 Mb/染色体），**必须**附加 `-c circdna.nf/conf/large_genome.config`（启用 CSI 索引）；hap2 无需附加

```bash
# hap1 (大基因组，需 CSI 索引)
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --genome Tragopogon_porrifolius_hap1 \
    --outdir eccDNA_results/Tragopogon_porrifolius_hap1 \
    -profile server \
    -c circdna.nf/conf/large_genome.config

# hap2
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Tragopogon_porrifolius_eccDNA.csv \
    --genome Tragopogon_porrifolius_hap2 \
    --outdir eccDNA_results/Tragopogon_porrifolius_hap2 \
    -profile server
```

### 狗牙根 (Cynodon_dactylon)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Cynodon_dactylon_eccDNA.csv \
    --genome Cynodon_dactylon \
    --outdir eccDNA_results/Cynodon_dactylon \
    -profile server
```

### 青蒿 (Artemisia_annua)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Artemisia_annua_eccDNA.csv \
    --genome Artemisia_annua \
    --outdir eccDNA_results/Artemisia_annua \
    -profile server
```

### 日本柳杉 (Cryptomeria_japonica) — 大基因组

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Cryptomeria_japonica_eccDNA.csv \
    --genome Cryptomeria_japonica \
    --outdir eccDNA_results/Cryptomeria_japonica \
    -profile server \
    -c circdna.nf/conf/large_genome.config
```

### 小麦 (Triticum_aestivum) — 大基因组

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_Triticum_aestivum_eccDNA.csv \
    --genome Triticum_aestivum \
    --outdir eccDNA_results/Triticum_aestivum \
    -profile server \
    -c circdna.nf/conf/large_genome.config
```

## 三代长读长物种 (circdnalr) — 占位

> 以下物种仅有 long_read 长读长 samplesheet（`circdnalr_*_long_read.csv`），circdnalr 流程尚未就绪，命令为占位，待后续实现

### 向日葵 (Helianthus_annuus)

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdnalr_Helianthus_annuus_long_read.csv \
    --genome Helianthus_annuus \
    --outdir eccDNA_results/Helianthus_annuus \
    -profile server
```

### 苋 (Amaranthus_palmeri) — 双单倍型 (hap1/hap2)

> 该物种存在 hap1、hap2 两个单倍型基因组，需分别运行；`--genome` 值必须为 `Amaranthus_palmeri_hap1` / `Amaranthus_palmeri_hap2`（对应 server.config 中的 genome 键）

```bash
# hap1
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdnalr_Amaranthus_palmeri_long_read.csv \
    --genome Amaranthus_palmeri_hap1 \
    --outdir eccDNA_results/Amaranthus_palmeri_hap1 \
    -profile server

# hap2
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdnalr_Amaranthus_palmeri_long_read.csv \
    --genome Amaranthus_palmeri_hap2 \
    --outdir eccDNA_results/Amaranthus_palmeri_hap2 \
    -profile server
```

### 黑麦草 (Alopecurus_myosuroides) — 大基因组

```bash
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdnalr_Alopecurus_myosuroides_long_read.csv \
    --genome Alopecurus_myosuroides \
    --outdir eccDNA_results/Alopecurus_myosuroides \
    -profile server \
    -c circdna.nf/conf/large_genome.config
```

## 常用操作

### Screen 会话

```bash
# 查看所有 screen 会话
screen -ls

# 恢复会话
screen -r eccdna

# 新建会话
screen -S <name>

# 从当前会话分离 (保持进程运行)
# Ctrl+A+D

# 终止会话 (在会话内执行)
exit

# 远程 detached 会话 (会话在后台)
screen -d -r eccdna
```

### Pipeline 操作

```bash
# 查看运行日志
tail -f circdna.nf/.nextflow.log

# 查看最近 run name
head -3 circdna.nf/.nextflow.log

# 查看运行进度
nextflow log <run_name> -f

# 清理 work 目录 (解决 root 权限问题)
docker run --rm -v $(pwd):/work -w /work alpine rm -rf circdna.nf/work/

# 快速重启某个物种
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_<species>_eccDNA.csv \
    --genome <species> \
    --outdir eccDNA_results/<species> \
    -profile server
```

## 注意事项

- **必须执行 `conda activate nextflow`**：`nextflow` 命令仅在 `nextflow` conda 环境中可用
- **`-resume` 必须指定 run name**：使用 `-resume`（不带参数）会恢复最近一次运行，可能不是你想要的
- **FASTA 文件**：需已上传至 `/data1/users/siyangming/FASTA/`
- **样本数据**：需存在于 `eccDNA/` 目录
- **大基因组**（小麦、日本柳杉、Tragopogon_porrifolius hap1）需添加 `-c circdna.nf/conf/large_genome.config`；三代长读长中黑麦草同为大型基因组，章节内已单独标注
- **`circle_identifier`、`input_format`** 等参数已在 `circdna.nf/conf/server.config` 中配置，无需在命令中指定
- **清理旧 work 目录**：root 权限文件需用 Docker 删除

## 常见错误

### `bash: nextflow: 未找到命令`

```bash
# 原因: 未激活 conda 环境
# 解决:
conda activate nextflow
which nextflow  # 验证
```

### `-resume` 恢复了错误的运行

```bash
# 原因: -resume 不带参数时默认恢复最近一次运行
# 解决: 指定 run name
nextflow run ./circdna.nf/main.nf ... -resume <具体的run_name>

# 查看可用的 run names
head -10 circdna.nf/.nextflow.log | grep "Launching\|run name"
```

### `WARN: Access to undefined parameter 'fasta'`

```bash
# 已在 circdna.nf/workflows/circdna.nf#L37 修复:
# 使用 params.containsKey('fasta') 检查而非直接访问
# 如果仍出现警告，确保 --genome 参数正确指定
```

### `Remote resource not found: nextflow-io/circdna.nf`

```bash
# 原因: Nextflow 把 circdna.nf 误解析为 GitHub 远程仓库（org/repo 格式）
# 因为没有路径前缀，被识别为远程仓库名

# 错误命令:
nextflow run ./circdna.nf/main.nf ...

# 解决方案 1: 使用 ./ 前缀（推荐）
nextflow run ./circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_<species>_eccDNA.csv \
    --genome <species> \
    --outdir eccDNA_results/<species> \
    -profile server

# 解决方案 2: 使用绝对路径
nextflow run /data1/users/siyangming/PlanteccDNADB/circdna.nf/main.nf \
    --input circdna.nf/samplesheets/circdna_<species>_eccDNA.csv \
    ...

# 解决方案 3: 进入 circdna.nf 目录内运行
cd circdna.nf/
nextflow run main.nf \
    --input samplesheets/circdna_<species>_eccDNA.csv \
    --genome <species> \
    --outdir ../eccDNA_results/<species> \
    -profile server
```
