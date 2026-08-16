# Fix Legacy Mode Downstream Single-Sample Spec

## Why

在 legacy mode（`circle_identifier` 模式）下运行多样本时，BWA_MEM 正确处理了所有 45 个样本，但下游的 CIRCLE_FINDER_PIPELINE（CIRCLEFINDER）、CIRCLE_MAP_PIPELINE（所有步骤）和 CIRCEXPLORER2_PARSE 只处理了第一个样本（ERR1830498）。根因是 `bam_preprocessing/main.nf` 中的 `ch_fasta_fai` 在移除 `.first()` 后变成了 queue channel（1 个元素），导致下游 process 的多 queue channel 输入做 one-to-one 匹配时只处理 1 个样本。

## What Changes

- 在 `bam_preprocessing/main.nf` 中，将 `ch_fasta_fai` 的构造方式从 `.join().map()` 改为 `.join().map().collect().map { it[0] }`，确保结果为 value channel
- 不使用 `.first()`（避免 Nextflow "first is useless on value channel" 误报警告），而是用 `.collect().map { it[0] }` 实现等效的 queue→value 转换

## Impact

- Affected specs: fix-fasta-value-channel（前序修复的补充和完善）
- Affected code:
  - `subworkflows/local/bam_preprocessing/main.nf` — `ch_fasta_fai` 构造逻辑

## Root Cause Analysis

### Channel 类型推导

```
fasta_meta (value, from .first())
    .join(SAMTOOLS_FAIDX.out.fai)    ← SAMTOOLS_FAIDX.out.fai 是 process 输出 = queue channel
    .map { ... }                      ← value.join(queue) = queue channel (1 个元素)
```

- **有 `.first()` 时**：queue(1) → value ✔ 下游 process 广播正确
- **无 `.first()` 时**：queue(1) → queue(1) ✗ 下游 process one-to-one 匹配只处理 1 个

### 为什么 BWA_MEM 不受影响

`ch_bwa_index` 来自 `BWA_INDEX.out.index.map{...}`，是直接的 process 输出。Nextflow 对 process 输出可能有自动优化（当 process 只运行 1 次时），将其作为 value channel 传播。但 `join` 操作的结果不受此优化影响。

### Nextflow 警告误报

Nextflow 警告 "first is useless when applied to a value channel" 是因为 `fasta_meta` 是 value channel，Nextflow 错误推断 `fasta_meta.join(queue)` 也是 value channel。但实际运行表明它是 queue channel。这是 Nextflow 类型推断的误报。

## ADDED Requirements

### Requirement: ch_fasta_fai Must Be Value Channel

`BAM_PREPROCESSING` subworkflow 中的 `ch_fasta_fai` channel 必须是 value channel，以确保下游所有 process（BAM_STATS_SAMTOOLS、BAM_MARKDUPLICATES_PICARD、SAMTOOLS_VIEW_FILTER、SAMTOOLS_SORT_FILTERED）以及 emit 给外部 subworkflow（CIRCLE_FINDER_PIPELINE、CIRCLE_MAP_PIPELINE）使用时，fasta_fai 被正确广播到所有样本。

#### Scenario: 多样本 legacy mode 运行

- **WHEN** 用户在 legacy mode 下运行 45 个样本
- **THEN** CIRCLE_FINDER_PIPELINE 的所有步骤（SAMTOOLS_SORT_QNAME_CF、SAMBLASTER、BEDTOOLS_SPLITBAM2BED、BEDTOOLS_SORTEDBAM2BED、CIRCLEFINDER）都处理 45 个样本
- **AND** CIRCLE_MAP_PIPELINE 的所有步骤（SAMTOOLS_SORT_QNAME_CM、CIRCLEMAP_READEXTRACTOR、SAMTOOLS_SORT_RE、CIRCLEMAP_REPEATS、CIRCLEMAP_REALIGN）都处理 45 个样本
- **AND** CIRCEXPLORER2_PARSE 处理 45 个样本

#### Scenario: 无 Nextflow 警告

- **WHEN** 使用 test_local profile 运行 pipeline
- **THEN** Nextflow 日志中不出现 "first is useless when applied to a value channel" 警告

## MODIFIED Requirements

### Requirement: ch_fasta_fai Construction

`ch_fasta_fai` 的构造方式从：

```groovy
def ch_fasta_fai = fasta_meta
    .join(SAMTOOLS_FAIDX.out.fai)
    .map { meta, fasta, fai -> [meta, fasta, fai] }
```

改为：

```groovy
def ch_fasta_fai = fasta_meta
    .join(SAMTOOLS_FAIDX.out.fai)
    .map { meta, fasta, fai -> [meta, fasta, fai] }
    .collect()
    .map { it[0] }
```

- `.collect()` 将 queue channel（1 个元素）收集为 value channel（包含 1 元素 List）
- `.map { it[0] }` 从 List 中提取第一个元素，保持 value channel 类型
- 不使用 `.first()`，避免 Nextflow 误报警告
