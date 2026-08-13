#!/bin/bash
# =============================================================================
# extract_test_data.sh – 从真实 ONT / PacBio 数据中提取三档测试子集
#
# 用法: bash extract_test_data.sh
# 前提: seqkit 已在 PATH 中，源文件路径存在
# 产出: ont/ 和 pacbio/ 目录下的 fastq.gz 测试数据
# =============================================================================
set -euo pipefail

# ---- 固定随机种子，保证重现性 ----
SEED=42

# ---- 源文件路径 ----
ONT_SRC="/data1/users/siyangming/PlanteccDNADB/eccDNA/Arabidopsis_thaliana/SRR24335762.fastq.gz"
PACBIO_SRC="/data1/users/siyangming/PlanteccDNADB/eccDNA/Oryza_sativa/ERR11838731.fastq.gz"

# ---- 输出目录 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONT_DIR="${SCRIPT_DIR}/ont"
PACBIO_DIR="${SCRIPT_DIR}/pacbio"
mkdir -p "${ONT_DIR}" "${PACBIO_DIR}"

# ---- 提取函数 ----
extract_tier() {
    local src="$1"
    local out="$2"
    local n="$3"
    local label="$4"

    if [ -f "${out}" ]; then
        echo "[${label}] ${out} 已存在，跳过"
        return 0
    fi

    echo "[${label}] 从 $(basename "${src}") 抽取 ${n} 条 read → $(basename "${out}")"
    seqkit sample -n "${n}" -s "${SEED}" "${src}" -o "${out}"

    local size
    size=$(du -h "${out}" | cut -f1)
    echo "        → 完成，文件大小: ${size}"
}

# =============================================================================
# ONT (Arabidopsis eccDNA, SRR24335762) — 196,317 reads, avg 4,587 bp
# =============================================================================
echo "========== ONT (Arabidopsis eccDNA) =========="

extract_tier "${ONT_SRC}" "${ONT_DIR}/ont_eccdna_smoke.fastq.gz"     1500  "smoke"
extract_tier "${ONT_SRC}" "${ONT_DIR}/ont_eccdna_regular.fastq.gz"   7500  "regular"
extract_tier "${ONT_SRC}" "${ONT_DIR}/ont_eccdna_consistency.fastq.gz" 30000 "consistency"

# =============================================================================
# PacBio (Rice HiFi WGS, ERR11838731)
# =============================================================================
echo ""
echo "========== PacBio (Rice HiFi WGS) =========="

extract_tier "${PACBIO_SRC}" "${PACBIO_DIR}/pacbio_eccdna_smoke.fastq.gz"     1500  "smoke"
extract_tier "${PACBIO_SRC}" "${PACBIO_DIR}/pacbio_eccdna_regular.fastq.gz"   2500  "regular"
extract_tier "${PACBIO_SRC}" "${PACBIO_DIR}/pacbio_eccdna_consistency.fastq.gz" 15000 "consistency"

echo ""
echo "========== 提取完毕 =========="
echo ""
echo "产出文件:"
find "${ONT_DIR}" "${PACBIO_DIR}" -name "*.fastq.gz" -exec ls -lh {} \;

echo ""
echo "Read 条数验证:"
for f in "${ONT_DIR}"/*.fastq.gz "${PACBIO_DIR}"/*.fastq.gz; do
    if [ -f "$f" ]; then
        n=$(seqkit stats -T "$f" 2>/dev/null | tail -1 | cut -f4)
        echo "  $(basename "$f"): ${n} reads"
    fi
done
