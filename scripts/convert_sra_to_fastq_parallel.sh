#!/bin/bash

SRA_TOOLS_BIN="/data1/users/siyangming/biosoft/sratoolkit.3.2.0-centos_linux64/bin"

INPUT_DIR="${1:-/data2/users/liuqi/eccdna}"
OUTPUT_DIR="${2:-/data1/users/siyangming/eccDNA}"
MAX_PARALLEL="${3:-4}"
THREADS="${4:-8}"
MIN_FILE_SIZE="${5:-1024}"
MAX_RETRIES="${6:-3}"

COMPLETED_FILE="$OUTPUT_DIR/sra.completed"
BROKEN_FILE="$OUTPUT_DIR/sra.broken"

echo "========================================"
echo "SRA to FASTQ Parallel Converter"
echo "========================================"
echo "Input directory:  $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Max parallel:     $MAX_PARALLEL"
echo "Threads per task: $THREADS"
echo "Min file size:    $MIN_FILE_SIZE bytes"
echo "Max retries:      $MAX_RETRIES"
echo "Completed file:   $COMPLETED_FILE"
echo "Broken file:      $BROKEN_FILE"
echo "========================================"

mkdir -p "$OUTPUT_DIR"
touch "$COMPLETED_FILE"
touch "$BROKEN_FILE"

export SRA_TOOLS_BIN
export THREADS
export OUTPUT_DIR
export MIN_FILE_SIZE
export MAX_RETRIES
export COMPLETED_FILE
export BROKEN_FILE

is_completed() {
    local sra_name="$1"
    grep -q "^$sra_name$" "$COMPLETED_FILE" 2>/dev/null
    return $?
}

mark_completed() {
    local sra_name="$1"
    if ! is_completed "$sra_name"; then
        echo "$sra_name" >> "$COMPLETED_FILE"
    fi
}

is_broken() {
    local sra_name="$1"
    grep -q "^$sra_name$" "$BROKEN_FILE" 2>/dev/null
    return $?
}

mark_broken() {
    local sra_name="$1"
    if ! is_broken "$sra_name"; then
        echo "$sra_name" >> "$BROKEN_FILE"
    fi
}

validate_sra() {
    local sra_file="$1"
    local sra_name=$(basename "$sra_file" .sra)
    local sra_dir=$(dirname "$sra_file")
    local species=$(basename "$(dirname "$sra_dir")")

    if is_broken "$sra_name"; then
        echo "[SKIP] $species/$sra_name (in broken list)"
        return 1
    fi

    local file_size=$(stat -c%s "$sra_file" 2>/dev/null || stat -f%z "$sra_file" 2>/dev/null)
    if [ -z "$file_size" ] || [ "$file_size" -lt 1024 ]; then
        echo "[BROKEN] $species/$sra_name (file too small or missing)"
        mark_broken "$sra_name"
        return 1
    fi

    "$SRA_TOOLS_BIN/vdb-validate" "$sra_file" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "[BROKEN] $species/$sra_name (vdb-validate failed)"
        mark_broken "$sra_name"
        return 1
    fi

    return 0
}

is_fastq_valid() {
    local fastq_file="$1"

    if [ ! -f "$fastq_file" ]; then
        return 1
    fi

    local file_size=$(stat -c%s "$fastq_file" 2>/dev/null || stat -f%z "$fastq_file" 2>/dev/null)
    if [ -z "$file_size" ] || [ "$file_size" -lt "$MIN_FILE_SIZE" ]; then
        return 1
    fi

    if ! gunzip -t "$fastq_file" 2>/dev/null; then
        return 1
    fi

    local line_count=$(gunzip -c "$fastq_file" 2>/dev/null | head -4 | wc -l)
    if [ "$line_count" -ne 4 ]; then
        return 1
    fi

    return 0
}

is_conversion_complete() {
    local species="$1"
    local sra_name="$2"

    if is_completed "$sra_name"; then
        return 0
    fi

    local output_species_dir="$OUTPUT_DIR/$species"

    if [ -f "$output_species_dir/${sra_name}_1.fastq.gz" ] && [ -f "$output_species_dir/${sra_name}_2.fastq.gz" ]; then
        if is_fastq_valid "$output_species_dir/${sra_name}_1.fastq.gz" && is_fastq_valid "$output_species_dir/${sra_name}_2.fastq.gz"; then
            mark_completed "$sra_name"
            return 0
        fi
    fi

    if [ -f "$output_species_dir/${sra_name}.fastq.gz" ]; then
        if is_fastq_valid "$output_species_dir/${sra_name}.fastq.gz"; then
            mark_completed "$sra_name"
            return 0
        fi
    fi

    return 1
}

clean_incomplete() {
    local species="$1"
    local sra_name="$2"

    local output_species_dir="$OUTPUT_DIR/$species"
    local output_sra_dir="$output_species_dir/$sra_name"

    rm -f "$output_species_dir/${sra_name}"*.fastq.gz 2>/dev/null
    rm -rf "$output_sra_dir" 2>/dev/null
}

rename_fastq_files() {
    local output_species_dir="$1"
    local sra_name="$2"

    local f1_patterns=("${sra_name}_f1.fq.gz" "${sra_name}_f1.fastq.gz" "${sra_name}_R1.fq.gz" "${sra_name}_R1.fastq.gz" "${sra_name}_1.fq.gz")
    local f2_patterns=("${sra_name}_r2.fq.gz" "${sra_name}_r2.fastq.gz" "${sra_name}_R2.fq.gz" "${sra_name}_R2.fastq.gz" "${sra_name}_2.fq.gz")

    for f1 in "${f1_patterns[@]}"; do
        if [ -f "$output_species_dir/$f1" ]; then
            mv "$output_species_dir/$f1" "$output_species_dir/${sra_name}_1.fastq.gz"
            break
        fi
    done

    for f2 in "${f2_patterns[@]}"; do
        if [ -f "$output_species_dir/$f2" ]; then
            mv "$output_species_dir/$f2" "$output_species_dir/${sra_name}_2.fastq.gz"
            break
        fi
    done

    if [ -f "$output_species_dir/${sra_name}.fq.gz" ]; then
        mv "$output_species_dir/${sra_name}.fq.gz" "$output_species_dir/${sra_name}.fastq.gz"
    fi
}

run_fastq_dump() {
    local sra_name="$1"
    local output_sra_dir="$2"

    "$SRA_TOOLS_BIN/fastq-dump" \
        --split-3 \
        --gzip \
        "$sra_name.sra"

    return $?
}

copy_existing_fastq() {
    local input_species_dir="$1"
    local species=$(basename "$input_species_dir")
    local output_species_dir="$OUTPUT_DIR/$species"
    mkdir -p "$output_species_dir"

    local fq_files=($(find "$input_species_dir" -maxdepth 1 -type f \( -name "*.fq.gz" -o -name "*.fastq.gz" \) 2>/dev/null | sort))
    local total_files=${#fq_files[@]}

    if [ $total_files -eq 0 ]; then
        return
    fi

    echo "[COPY-FQ] $species (found $total_files FASTQ files)"

    declare -A sample_files

    for fq_file in "${fq_files[@]}"; do
        local filename=$(basename "$fq_file")
        local sample_name=""
        local read_num=""

        if [[ $filename =~ ^(.+)_f1\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="1"
        elif [[ $filename =~ ^(.+)_r1\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="1"
        elif [[ $filename =~ ^(.+)_R1\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="1"
        elif [[ $filename =~ ^(.+)_1\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="1"
        elif [[ $filename =~ ^(.+)_f2\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="2"
        elif [[ $filename =~ ^(.+)_r2\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="2"
        elif [[ $filename =~ ^(.+)_R2\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="2"
        elif [[ $filename =~ ^(.+)_2\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="2"
        elif [[ $filename =~ ^(.+)\.(fastq|fq)\.gz$ ]]; then
            sample_name="${BASH_REMATCH[1]}"
            read_num="single"
        fi

        if [ -n "$sample_name" ]; then
            if [ "$read_num" = "single" ]; then
                sample_files["$sample_name"]="$fq_file"
            else
                sample_files["$sample_name,$read_num"]="$fq_file"
            fi
        fi
    done

    local processed_count=0
    declare -A processed_samples

    for key in "${!sample_files[@]}"; do
        IFS=',' read -r sample_name read_num <<< "$key"
        local source_file="${sample_files[$key]}"

        if [ -n "${processed_samples[$sample_name]}" ]; then
            continue
        fi

        if is_completed "$sample_name"; then
            echo "[SKIP] $species/$sample_name (already in completed list)"
            continue
        fi

        if [ "$read_num" = "single" ]; then
            local output_file="$output_species_dir/${sample_name}.fastq.gz"

            if [ -f "$output_file" ] && is_fastq_valid "$output_file"; then
                echo "[SKIP] $species/$sample_name (output already exists and valid)"
                mark_completed "$sample_name"
                processed_samples["$sample_name"]=1
                continue
            fi

            echo "[COPY] $species/$sample_name (single-end)"
            cp "$source_file" "$output_file"

            if is_fastq_valid "$output_file"; then
                mark_completed "$sample_name"
                echo "[DONE] $species/$sample_name"
            else
                echo "[FAIL] $species/$sample_name (copy failed or invalid)"
                rm -f "$output_file"
            fi
            processed_samples["$sample_name"]=1
            processed_count=$((processed_count + 1))
        else
            local f1_file="${sample_files["$sample_name,1"]}"
            local f2_file="${sample_files["$sample_name,2"]}"

            if [ -n "$f1_file" ] && [ -n "$f2_file" ]; then
                local output_f1="$output_species_dir/${sample_name}_1.fastq.gz"
                local output_f2="$output_species_dir/${sample_name}_2.fastq.gz"

                if [ -f "$output_f1" ] && [ -f "$output_f2" ] && is_fastq_valid "$output_f1" && is_fastq_valid "$output_f2"; then
                    echo "[SKIP] $species/$sample_name (output already exists and valid)"
                    mark_completed "$sample_name"
                    processed_samples["$sample_name"]=1
                    continue
                fi

                echo "[COPY] $species/$sample_name (paired-end)"
                cp "$f1_file" "$output_f1"
                cp "$f2_file" "$output_f2"

                if is_fastq_valid "$output_f1" && is_fastq_valid "$output_f2"; then
                    mark_completed "$sample_name"
                    echo "[DONE] $species/$sample_name"
                else
                    echo "[FAIL] $species/$sample_name (copy failed or invalid)"
                    rm -f "$output_f1" "$output_f2"
                fi
                processed_samples["$sample_name"]=1
                processed_count=$((processed_count + 1))
            fi
        fi
    done

    if [ $processed_count -gt 0 ]; then
        echo "[INFO] $species: copied $processed_count samples"
    fi
}

process_species() {
    local input_species_dir="$1"
    local species=$(basename "$input_species_dir")

    local has_fq=$(find "$input_species_dir" -maxdepth 1 -type f \( -name "*.fq.gz" -o -name "*.fastq.gz" \) 2>/dev/null | head -1)
    if [ -n "$has_fq" ]; then
        copy_existing_fastq "$input_species_dir"
    fi

    local has_sra=$(find "$input_species_dir" -type f -name "*.sra" 2>/dev/null | head -1)
    if [ -n "$has_sra" ]; then
        find "$input_species_dir" -type f -name "*.sra" | parallel -j "$MAX_PARALLEL" process_sra {}
    fi
}

process_sra() {
    local sra_file="$1"

    sra_dir=$(dirname "$sra_file")
    sra_name=$(basename "$sra_file" .sra)
    species=$(basename "$(dirname "$sra_dir")")

    output_species_dir="$OUTPUT_DIR/$species"
    output_sra_dir="$output_species_dir/$sra_name"
    mkdir -p "$output_species_dir"

    if is_completed "$sra_name"; then
        echo "[SKIP] $species/$sra_name (in completed list)"
        rm -rf "$output_sra_dir" 2>/dev/null
        return
    fi

    if is_conversion_complete "$species" "$sra_name"; then
        echo "[SKIP] $species/$sra_name (already complete)"
        rm -rf "$output_sra_dir" 2>/dev/null
        return
    fi

    if ! validate_sra "$sra_file"; then
        echo "[SKIP] $species/$sra_name (validation failed)"
        return
    fi

    echo "[START] $species/$sra_name"

    clean_incomplete "$species" "$sra_name"
    mkdir -p "$output_sra_dir"
    cp "$sra_file" "$output_sra_dir/"
    echo "[COPY] $species/$sra_name (copied SRA to working directory)"

    pushd "$output_sra_dir" > /dev/null

    local success=false
    local retry_count=0

    while [ $retry_count -lt $MAX_RETRIES ] && [ "$success" = false ]; do
        retry_count=$((retry_count + 1))

        if [ $retry_count -gt 1 ]; then
            echo "[RETRY $retry_count/$MAX_RETRIES] $species/$sra_name"
            sleep $((retry_count * 10))
        fi

        rm -f *.fastq 2>/dev/null
        rm -f *.fastq.gz 2>/dev/null
        rm -f fasterq.tmp.* 2>/dev/null

        run_fastq_dump "$sra_name" "$output_sra_dir"

        if [ $? -eq 0 ] && ls *.fastq.gz 1>/dev/null 2>&1; then
            success=true
            continue
        fi
    done

    if [ "$success" = false ]; then
        echo "[FAIL] $species/$sra_name (after $MAX_RETRIES retries)"
        popd > /dev/null
        clean_incomplete "$species" "$sra_name"
        return
    fi

    cp *.fastq.gz "$output_species_dir/"

    rm -f "$sra_name.sra"
    rm -f *.fastq 2>/dev/null
    rm -f fasterq.tmp.* 2>/dev/null

    popd > /dev/null

    rm -rf "$output_sra_dir"

    rename_fastq_files "$output_species_dir" "$sra_name"

    if is_conversion_complete "$species" "$sra_name"; then
        mark_completed "$sra_name"
        echo "[DONE] $species/$sra_name"
    else
        echo "[WARN] $species/$sra_name (conversion finished but validation failed)"
    fi
}

export -f is_completed
export -f mark_completed
export -f is_broken
export -f mark_broken
export -f validate_sra
export -f is_fastq_valid
export -f is_conversion_complete
export -f clean_incomplete
export -f rename_fastq_files
export -f run_fastq_dump
export -f copy_existing_fastq
export -f process_species
export -f process_sra

echo "[INIT] Setting up NCBI VDB configuration..."
"$SRA_TOOLS_BIN/vdb-config" --restore 2>/dev/null || true

echo "[INFO] Starting parallel conversion..."
echo "[INFO] Found $(find "$INPUT_DIR" -type f -name "*.sra" | wc -l) SRA files"
echo "[INFO] Found $(find "$INPUT_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l) species directories"
echo "[INFO] Already completed: $(wc -l < "$COMPLETED_FILE") files"
echo "[INFO] Already broken: $(wc -l < "$BROKEN_FILE") files"

find "$INPUT_DIR" -mindepth 1 -maxdepth 1 -type d | parallel -j 1 process_species {}

echo "========================================"
echo "[FINISH] All processing completed."
echo "[INFO] Source SRA files preserved in: $INPUT_DIR"
echo "[INFO] FASTQ files in: $OUTPUT_DIR"
echo "[INFO] Completed list: $COMPLETED_FILE"
echo "[INFO] Broken list: $BROKEN_FILE"
echo "========================================"
