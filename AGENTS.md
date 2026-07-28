# AGENTS.md — nf-core/circdna Pipeline Architecture & Change Rules

> **Purpose**: This document defines the complete architecture, data flow, and change management rules for the `nf-core/circdna` Nextflow pipeline. Any AI assistant making changes to this pipeline MUST follow these rules.

> **UNIVERSAL RULES**: Before reading this document, first check `/Users/siyangming/nextflow_nf_core/AGENTS.md` for universal Nextflow pipeline conventions, CHANGELOG rules, and version bumping policies. This document is the pipeline-specific supplement.

---

## 1. Pipeline Overview

**Pipeline**: `nf-core/circdna` v3.2.0  
**Main Entry**: `main.nf` → `workflows/circdna.nf`  
**Three Modes**:
| Mode | Description |
|------|-------------|
| `reference` | gDNA/WGS variant detection only |
| `eccdna` | eccDNA (circular DNA) detection (legacy + new) |
| `integrated` | Joint gDNA + eccDNA analysis with ECC_SCORE integration |

---

## 2. Directory Architecture

```
circdna.nf/
├── main.nf                          # ENTRY POINT: orchestrates workflow lifecycle
├── nextflow.config                  # GLOBAL CONFIG: params, profiles, manifests
├── nextflow_schema.json             # PARAMETER SCHEMA: auto-generated from params
├── modules.json                     # MODULE MANIFEST: all module dependencies
│
├── workflows/
│   └── circdna.nf                   # TOP-LEVEL WORKFLOW: mode selection + data routing
│
├── subworkflows/local/              # CUSTOM SUBWORKFLOWS
│   ├── input_check/main.nf          #   Samplesheet parsing + validation
│   ├── bam_preprocessing/main.nf    #   FASTQC → TrimGalore → BWA → Picard → SAMtools
│   ├── eccdna_mode/main.nf          #   eccDNA mode: BAM prep + mosdepth + ECCsplorer + Circle-Map + merge
│   ├── reference_mode/main.nf       #   Reference mode: BAM prep + mosdepth only
│   ├── integrated_mode/main.nf      #   Integrated mode: ECC_SCORE calculation
│   ├── circle_finder_pipeline/main.nf  # Legacy: Circle-Finder (SAMBLASTER → BEDTools → CircleFinder)
│   ├── circle_map_pipeline/main.nf     # Legacy/Active: Circle-Map (ReadExtractor → Repeats → Realign)
│   ├── ampliconarchitect_pipeline/main.nf  # Legacy: AmpliconArchitect + CNVkit
│   ├── unicycler_pipeline/main.nf      # Legacy: Unicycler circular assembly
│   └── utils_nfcore_circdna_pipeline/main.nf  # Shared utility: methods description
│
├── subworkflows/nf-core/            # NF-CORE SUBWORKFLOWS (vendored)
│   ├── utils_nfcore_pipeline/main.nf      # Version collection, MultiQC summary
│   ├── bam_markduplicates_picard/main.nf  # Picard MarkDuplicates workflow
│   └── bam_stats_samtools/main.nf         # SAMtools stats collection
│
├── modules/local/                   # CUSTOM MODULES
│   ├── eccsplorer/main.nf           #   ECCsplorer: eccDNA candidate detection
│   ├── ecc_score/main.nf            #   ECC_SCORE: eccDNA grading (w1*junction + w2*depth - w3*TE)
│   ├── candidate_merge/main.nf      #   Merge ECCsplorer + Circle-Map BED outputs
│   ├── circlefinder/main.nf         #   CircleFinder: circular DNA detection
│   ├── circlemap/                   #     Circle-Map sub-modules
│   │   ├── readextractor/main.nf
│   │   ├── realign/main.nf
│   │   └── repeats/main.nf
│   ├── getcircularreads/main.nf     #   Extract circular reads for Unicycler
│   ├── ampliconsuite/main.nf        #   AmpliconArchitect + AmpliconClassifier
│   ├── bedtools/                    #     BEDTools sub-modules
│   │   ├── sortedbam2bed/main.nf
│   │   └── splitbam2bed/main.nf
│   └── samplesheet_check/main.nf    #   Samplesheet validation
│
├── modules/nf-core/                 # NF-CORE MODULES (vendored from nf-core/modules)
│   ├── bwa/                         #     BWA index + mem
│   ├── fastqc/                      #     FastQC quality check
│   ├── trimgalore/                  #     TrimGalore trimming
│   ├── samtools/                    #     SAMtools (sort, index, flagstat, idxstats, faidx, view, stats)
│   ├── picard/markduplicates/       #     Picard MarkDuplicates
│   ├── samblaster/                  #     SAMBLASTER split-read detection
│   ├── bedtools/                    #     BEDTools (vendored copy)
│   ├── circexplorer2/parse/        #     CIRCexplorer2 parse
│   ├── cnvkit/                      #     CNVkit batch + segment
│   ├── minimap2/align/              #     Minimap2 alignment
│   ├── mosdepth/                    #     mosdepth coverage
│   ├── multiqc/                     #     MultiQC aggregation
│   ├── seqtk/seq/                   #     seqtk sequence utilities
│   ├── unicycler/                   #     Unicycler assembly
│   └── cat/fastq/                   #     FASTQ concatenation
│
├── conf/                            # CONFIGURATION FILES
│   ├── base.config                  #   Default resource allocation (cpus/memory/time labels)
│   ├── modules.config               #   Per-module ext.args, ext.prefix, publishDir overrides
│   ├── igenomes.config              #   Reference genome paths (ref genomes)
│   ├── igenomes_ignored.config      #   Skip ref genome paths
│   ├── server.config                #   Server execution profile
│   ├── test.config                  #   GitHub CI test profile (smallest)
│   ├── test_local.config            #   Local test profile (4 CPU, 8GB)
│   ├── test_integrated.config       #   Integrated mode test
│   ├── test_AA.config               #   AmpliconArchitect test
│   ├── test_AA_local.config         #   AmpliconArchitect local test
│   └── test_full.config             #   Full test profile
│
├── samplesheets/                    # ALL SAMPLESHEETS (single source of truth)
│   ├── circdna_ngs_clean.csv       #   **MAIN INPUT**: NGS short-read data (108 samples, 12 species)
│   ├── circdna_tgs_clean.csv        #   **MAIN INPUT**: TGS long-read data
│   ├── circdna_{species}_eccDNA.csv #   Per-species NGS files (auto-generated by script)
│   ├── circdnalr_{species}_long_read.csv # Per-species TGS files
│   ├── circrna_*.csv               #   circRNA samplesheets (cross-project)
│   ├── SraRunInfo_eccDNA_all2.csv   #   SRA Run Info metadata (TaxID, ScientificName, download_path)
│   ├── samplesheet.csv              #   Default test samplesheet
│   ├── samplesheet_local.csv        #   Local test samplesheet
│   ├── samplesheet_integrated.csv   #   Integrated mode test (has "datatype" column)
│   ├── test_*.csv                   #   Additional test samplesheets
│   ├── data_issues.txt              #   Known data issues log
│   └── fastq_stats.tsv              #   FASTQ file statistics
│
├── scripts/                         # UTILITY SCRIPTS
│   ├── update_samplesheets.py       #   Auto-generate per-species samplesheets from clean CSVs
│   ├── convert_sra_to_fastq_parallel.sh  # Parallel SRA → FASTQ download
│   ├── test_incremental_cache.py    #   Incremental cache testing
│   ├── fix_misplaced_files.sh       #   Move misplaced fastq files between species dirs
│   └── 路径问题.txt                   #   Known path issues log
│
├── bin/                             # BIN SCRIPTS (available to Nextflow processes)
│   ├── check_samplesheet.py         #   VALIDATOR: samplesheet format checker
│   ├── Coverage.py                  #   Coverage calculation
│   ├── bam2bam.py                   #   BAM format conversion
│   ├── calculate_ecc_score.py       #   ECC_SCORE calculation
│   ├── circle_map.py                #   Circle-Map integration
│   ├── extract_circle_SV_reads.py   #   SV read extraction
│   ├── merge_candidates.py          #   Candidate merging
│   ├── realigner.py                 #   Read realignment
│   ├── repeats.py                   #   Repeat analysis
│   ├── scrape_software_versions.py  #   Version scraping
│   ├── simulations.py               #   Simulation utilities
│   ├── summarise_aa.py              #   AmpliconArchitect summary
│   └── utils.py                     #   Shared utilities
│
├── lib/                             # GROOVY LIBRARY
│   ├── WorkflowMain.groovy          #   Main workflow helpers (citation, initialise, getGenomeAttribute)
│   ├── WorkflowCircdna.groovy       #   Pipeline-specific helpers
│   ├── NfcoreTemplate.groovy        #   nf-core template utilities (logo, email, summary)
│   └── Utils.groovy                 #   General utilities
│
├── assets/                          # STATIC ASSETS
│   ├── multiqc_config.yml           #   MultiQC custom config
│   ├── schema_input.json            #   Input schema
│   ├── samplesheet.csv              #   Example samplesheet
│   └── methods_description_template.yml  # Methods description template
│
├── testdatasets/                    # TEST DATA (FASTQ files + reference)
│   ├── testdata/                    #   Test FASTQ files
│   ├── reference/                   #   Test reference genome
│   ├── cnvkit/                      #   CNVkit reference
│   ├── mosek/                       #   Mosek license
│   └── README.md                    #   Test dataset documentation
│
└── docs/                            # DOCUMENTATION
    ├── README.md                    #   Pipeline documentation
    ├── usage.md                     #   Usage guide
    └── output.md                    #   Output description
```

---

## 3. Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        INPUT LAYER                                  │
│                                                                     │
│  samplesheet.csv ──► INPUT_CHECK ──► ch_fastq ──► CAT_FASTQ        │
│  (sample,fastq_1, │  (validate +   (meta, reads)  (merge lanes)    │
│   fastq_2,        │  add metadata)                                │
│   data_type)      │                                                │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     QC & TRIMMING LAYER                              │
│                                                                     │
│  ch_cat_fastq ──► FASTQC ──► TRIMGALORE ──► ch_trimmed_reads       │
│                       │                       │                     │
│                       ▼                       ▼                     │
│                  ch_fastqc_multiqc      ch_trimgalore_multiqc       │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       ALIGNMENT LAYER                                │
│                                                                     │
│  ch_trimmed_reads ──► BWA_INDEX ──► BWA_MEM ──► BAM_PREPROCESSING   │
│                                               │                     │
│                                               ▼                     │
│                              (Picard MarkDup + SAMtools sort/index) │
│                                               │                     │
│                                               ▼                     │
│                            ch_bam_sorted + ch_bam_sorted_bai         │
└────────────────────────────┬────────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────────┐
│ REFERENCE_MODE │  │  ECCDNA_MODE  │  │  INTEGRATED_MODE   │
│               │  │               │  │                   │
│ MOSDEPTH      │  │ MOSDEPTH      │  │ ECC_SCORE         │
│ (gDNA depth)  │  │ ECCSPLORER    │  │  w1*junction_reads│
│               │  │ CIRCLE_MAP    │  │  w2*depth_ratio   │
│               │  │ CANDIDATE_MERGE│  │  w3*TE_penalty    │
└───────┬───────┘  └───────┬───────┘  └─────────┬─────────┘
        │                  │                     │
        ▼                  ▼                     ▼
  mosdepth_bed      merged_bed            scored_bed
  (gDNA)            (eccDNA candidates)  (final eccDNA calls)
```

---

## 4. Samplesheet Specification

### 4.1 NGS (FASTQ) Format
```csv
sample,fastq_1,fastq_2,data_type
ERR1830502,/data1/users/siyangming/eccDNA/Oryza_sativa/ERR1830502_1.fastq.gz,/data1/users/siyangming/eccDNA/Oryza_sativa/ERR1830502_2.fastq.gz,eccDNA
SRR5051136,/data1/users/siyangming/eccDNA/Oryza_sativa/SRR5051136_1.fastq.gz,/data1/users/siyangming/eccDNA/Oryza_sativa/SRR5051136_2.fastq.gz,eccDNA
```
- **Required columns**: `sample`, `fastq_1`, `fastq_2`
- **Optional columns**: `lane`, `datatype`, `platform`, `protocol`
- **`data_type` values**: `eccDNA` or `gDNA` (used by integrated mode to split channels)
- **`datatype` values**: `eccdna` or `gdna` (used by `check_samplesheet.py` for validation)
- **`platform` values**: `illumina`, `pacbio`, `ont`
- **`protocol` values**: `short_read`, `long_read`
- **File path convention**: `/data1/users/siyangming/eccDNA/{Species}/{sample}_{1,2}.fastq.gz`

### 4.2 TGS (BAM) Format
```csv
sample,bam
SAMPLE_A,/path/to/SAMPLE_A.bam
```

### 4.3 Key Samplesheet Files

| File | Purpose | Notes |
|------|---------|-------|
| `circdna_ngs_clean.csv` | **Master NGS input** | 108 samples, 12 species, `data_type` column |
| `circdna_tgs_clean.csv` | **Master TGS input** | Long-read data |
| `circdna_{species}_eccDNA.csv` | Per-species NGS | Auto-generated by `update_samplesheets.py` |
| `circdnalr_{species}_long_read.csv` | Per-species TGS | Hand-maintained |
| `SraRunInfo_eccDNA_all2.csv` | SRA metadata | TaxID, ScientificName, download_path |
| `samplesheet_local.csv` | Local test | Small test dataset |
| `samplesheet_integrated.csv` | Integrated test | Has `datatype` column |

### 4.4 Data Consistency Rules

1. **Path → Species Consistency**: File paths in the samplesheet MUST match actual filesystem locations
   - **Always verify** with `SraRunInfo_eccDNA_all2.csv` (check `TaxID` and `ScientificName`)
   - Common issue: fastq files downloaded to wrong species directory → fix by moving files, not by changing species in samplesheet

2. **No Duplicates**: `circdna_ngs_clean.csv` must not have duplicate sample names

3. **Master File is Source of Truth**: Species-specific files are auto-generated from master files — never edit them directly

---

## 5. Change Management Rules

### 5.1 When Changing Samplesheet Data

**Files to update (MANDATORY)**:
1. `samplesheets/circdna_ngs_clean.csv` (master NGS)
2. `samplesheets/circdna_tgs_clean.csv` (master TGS, if applicable)
3. Run `scripts/update_samplesheets.py` to regenerate all per-species files
4. `samplesheets/fastq_stats.tsv` (re-run stats if adding/removing samples)

**Files to verify**:
- `bin/check_samplesheet.py` — ensure column compatibility (supports `data_type`/`datatype` columns)
- `scripts/update_samplesheets.py` — ensure it handles new columns correctly

### 5.2 When Changing Pipeline Parameters

**Files to update (MANDATORY)**:
1. `nextflow.config` (add/modify params)
2. `nextflow_schema.json` (run `nf-core schema build` to regenerate)
3. `assets/schema_input.json` (if input schema changes)
4. `conf/modules.config` (if new process needs resource/publishDir config)
5. `conf/test_local.config` (update test params)
6. `conf/test_integrated.config` (update integrated mode params)

### 5.3 When Adding/Modifying Modules

**Files to update (MANDATORY)**:
1. `modules/local/{module}/main.nf` (module logic)
2. `modules/local/{module}/meta.yml` (module metadata)
3. `modules/local/{module}/environment.yml` (conda env, if new dependencies)
4. `modules.json` (module manifest — add entry)
5. `conf/modules.config` (add resource/publishDir config for new processes)
6. `workflows/circdna.nf` (include new module in appropriate subworkflow)

**Files to update (if test profiles changed)**:
- `conf/test_local.config`
- `conf/test.config`

### 5.4 When Adding/Modifying Subworkflows

**Files to update (MANDATORY)**:
1. `subworkflows/local/{subworkflow}/main.nf` (subworkflow logic)
2. `subworkflows/local/{subworkflow}/meta.yml` (metadata)
3. `workflows/circdna.nf` (include + wire into mode selection)
4. `conf/modules.config` (resource overrides for new processes)

### 5.5 When Adding New Pipeline Mode

**Files to update (MANDATORY)**:
1. `nextflow.config` (add mode to `mode` param options)
2. `workflows/circdna.nf` (add mode to `valid_modes`, create branch)
3. `conf/test_local.config` (add test config for new mode)
4. `docs/usage.md` (document new mode)
5. `nextflow_schema.json` (regenerate)

### 5.6 When Changing BAM Processing Logic

**Files to update (MANDATORY)**:
1. `subworkflows/local/bam_preprocessing/main.nf`
2. `subworkflows/local/eccdna_mode/main.nf` (uses BAM_PREPROCESSING)
3. `subworkflows/local/reference_mode/main.nf` (uses BAM_PREPROCESSING)
4. `subworkflows/local/integrated_mode/main.nf` (uses both)
5. `subworkflows/local/circle_finder_pipeline/main.nf` (legacy path)
6. `subworkflows/local/circle_map_pipeline/main.nf` (legacy path)
7. `conf/modules.config` (update resource/publishDir for affected processes)

### 5.7 When Changing the Check Script

**Files to update (MANDATORY)**:
1. `bin/check_samplesheet.py` — update validation logic
2. `subworkflows/local/input_check/main.nf` — verify compatibility
3. `samplesheets/samplesheet_local.csv` — ensure test samplesheet passes validation
4. Run: `python bin/check_samplesheet.py samplesheets/samplesheet_local.csv /tmp/test_out.csv FASTQ`

---

## 6. Mode & Circle Identifier Mapping

### Mode Selection (in `workflows/circdna.nf`)
```groovy
params.mode == 'reference'   → REFERENCE_MODE
params.mode == 'eccdna'      → ECCDNA_MODE (+ optional legacy branches)
params.mode == 'integrated'  → REFERENCE_MODE + ECCDNA_MODE + INTEGRATED_MODE
```

### Legacy Circle Identifiers (only when `mode='eccdna'` + `circle_identifier` is set)
| Identifier | Module | Description |
|------------|--------|-------------|
| `circexplorer2` | CIRCEXPLORER2_PARSE | CIRCexplorer2 parse |
| `circle_map_realign` | CIRCLE_MAP_PIPELINE (realign) | Circle-Map realignment |
| `circle_map_repeats` | CIRCLE_MAP_PIPELINE (repeats) | Circle-Map repeat analysis |
| `circle_finder` | CIRCLE_FINDER_PIPELINE | Circle-Finder detection |
| `ampliconarchitect` | AMPLICONARCHITECT_PIPELINE | AmpliconArchitect + CNVkit |
| `unicycler` | UNICYCLER_PIPELINE | Unicycler circular assembly |

### New Mode Behavior (no `circle_identifier`)
| Mode | Subworkflows Run |
|------|-----------------|
| `reference` | BAM_PREPROCESSING → MOSDEPTH |
| `eccdna` | BAM_PREPROCESSING → MOSDEPTH + ECCSPLORER + CIRCLE_MAP → CANDIDATE_MERGE |
| `integrated` | gDNA: REFERENCE_MODE; eccDNA: ECCDNA_MODE; then INTEGRATED_MODE (ECC_SCORE) |

---

## 7. Key Conventions

### 7.1 Naming Conventions
- **Process names**: UPPER_CASE (e.g., `BWA_MEM`, `TRIMGALORE`, `CIRCLEFINDER`)
- **Channel names**: `ch_` prefix (e.g., `ch_fastq`, `ch_bam_sorted`)
- **Subworkflow names**: UPPER_CASE (e.g., `BAM_PREPROCESSING`, `ECCDNA_MODE`)
- **Custom modules**: snake_case in path, UPPER_CASE in include
- **Species files**: `circdna_{Species}_eccDNA.csv` (underscore-separated species name)

### 7.2 Resource Labels (from `conf/base.config`)
| Label | CPUs | Memory | Time |
|-------|------|--------|------|
| `process_single` | 1 | 6 GB | 4h |
| `process_low` | 2 | 12 GB | 4h |
| `process_medium` | 6 | 36 GB | 8h |
| `process_high` | 12 | 72 GB | 16h |
| `process_long` | — | — | 20h |
| `process_maximum_time` | — | — | max_time |
| `process_high_memory` | — | 200 GB | — |
| `process_max` | max_cpus | max_memory | max_time |

### 7.3 Samplesheet Column Names
- **Production files** (`circdna_ngs_clean.csv`): `data_type` (camelCase)
- **Test files** (`samplesheet_integrated.csv`): `datatype` (lowercase)
- **`check_samplesheet.py`** validates: `datatype` column name (lowercase), accepts values `eccdna`/`gdna`
- **Both conventions work**: `check_samplesheet.py` reads by column name, and `data_type` is accepted as a valid column name via `OPTIONAL_FIELDS`

### 7.4 Data Type Values
| Column Name | Valid Values | Usage |
|------------|-------------|-------|
| `data_type` | `eccDNA`, `gDNA` | Production files, filter in `workflows/circdna.nf` |
| `datatype` | `eccdna`, `gdna` | Test files, validation in `check_samplesheet.py` |

### 7.5 Pipeline Modes
- `reference` → gDNA/WGS only (mosdepth)
- `eccdna` → eccDNA detection (ECCsplorer + Circle-Map + merge)
- `integrated` → gDNA + eccDNA joint analysis (ECC_SCORE with configurable weights)

### 7.6 Circle Identifier
- Only active when `mode='eccdna'` AND `circle_identifier` is explicitly set
- Values: `circexplorer2`, `circle_map_realign`, `circle_map_repeats`, `circle_finder`, `ampliconarchitect`, `unicycler`
- New mode path (no `circle_identifier`): uses ECCDNA_MODE subworkflow by default

### 7.7 ECC_SCORE Weights
- `ecc_score_w1`: Junction reads weight (default: 1.0)
- `ecc_score_w2`: Depth ratio weight (default: 1.0)
- `ecc_score_w3`: TE repeat penalty weight (default: 0.5)
- Score formula: `score = w1 * junction_reads + w2 * depth_ratio - w3 * TE_penalty`

### 7.8 Platform Values
- `illumina`: Short-read sequencing (NGS)
- `pacbio`: Long-read sequencing (TGS)
- `ont`: Oxford Nanopore

### 7.9 Protocol Values
- `short_read`: Short-read sequencing
- `long_read`: Long-read sequencing

---

## 8. Validation & Testing Commands

### 8.1 Schema Validation
```bash
# Regenerate schema after param changes
conda activate nextflow
nf-core schema build
```

### 8.2 Samplesheet Validation
```bash
# Validate a samplesheet
conda activate nextflow
python bin/check_samplesheet.py samplesheets/samplesheet.csv /tmp/test_out.csv FASTQ

# Validate with data_type column
python bin/check_samplesheet.py samplesheets/circdna_ngs_clean.csv /tmp/test_out.csv FASTQ
```

### 8.3 Regenerate Species Files
```bash
# Auto-generate per-species samplesheets
python scripts/update_samplesheets.py
```

### 8.4 Local Test Run
```bash
# Run local test
conda activate nextflow
nextflow run main.nf -profile test_local

# Run integrated mode test
nextflow run main.nf -profile test_integrated
```

### 8.5 Full Pipeline Run (Example)
```bash
# eccDNA mode with specific circle identifiers
nextflow run main.nf \
    -profile docker \
    --input samplesheets/circdna_Oryza_sativa_eccDNA.csv \
    --input_format FASTQ \
    --genome Oryza_sativa \
    --mode eccdna \
    --circle_identifier circexplorer2,circle_map_realign,circle_map_repeats \
    --outdir results

# Integrated mode with custom weights
nextflow run main.nf \
    -profile docker \
    --input samplesheets/samplesheet_integrated.csv \
    --input_format FASTQ \
    --genome GRCh38 \
    --mode integrated \
    --ecc_score_w1 1.0 \
    --ecc_score_w2 1.0 \
    --ecc_score_w3 0.5 \
    --outdir results
```

---

## 9. Common Issues & Fixes

### 9.1 File Not Found in Species Directory
**Symptom**: `ERROR: /path/to/{species}/{sample}.fastq.gz not found`
**Root Cause**: Fastq files downloaded to wrong species directory
**Fix**: 
1. Check `SraRunInfo_eccDNA_all2.csv` for correct `ScientificName` and `TaxID`
2. Move files to correct directory using `scripts/fix_misplaced_files.sh`
3. Verify and update samplesheet paths

### 9.2 Duplicate Samples
**Symptom**: `Samplesheet contains duplicate rows!`
**Root Cause**: Same sample listed multiple times in same samplesheet
**Fix**: Check `circdna_ngs_clean.csv` for duplicates, remove them

### 9.3 Column Name Mismatch
**Symptom**: Validation fails on `data_type` vs `datatype`
**Root Cause**: Production files use `data_type`, test files use `datatype`
**Fix**: `check_samplesheet.py` supports both — ensure column name matches expected convention

### 9.4 Module Not Found
**Symptom**: `Include of module failed`
**Root Cause**: Module not properly vendored or path incorrect
**Fix**: Check `modules.json`, verify file paths, ensure `meta.yml` exists

---

## 10. Cross-Project Dependencies

This pipeline is part of a three-project system:

| Project | Path | Purpose |
|---------|------|---------|
| **circdna.nf** | `/Users/siyangming/nextflow_nf_core/circdna.nf` | eccDNA detection (main) |
| **circrna.nf** | `/Users/siyangming/nextflow_nf_core/circrna.nf` | circRNA detection |
| **bio.nf** | `/Users/siyangming/nextflow_nf_core/bio.nf` | General bioinformatics |

**Shared Resources**:
- `SraRunInfo_eccDNA_all2.csv` — metadata shared across projects
- `circrna_*.csv` — circRNA samplesheets may be referenced by circdna.nf
- `scripts/` — utility scripts may be shared

---

## 11. Git Branch Strategy

| Branch | Purpose |
|--------|---------|
| `master` | Production-ready code, stable |
| `circdnalr` | Long-read (TGS) development branch |
| Feature branches | Feature-specific development |

**Sync Rules**:
- Samplesheet changes: Copy files directly (avoid cherry-pick due to frequent conflicts)
- Only sync `samplesheets/` and `scripts/` when explicitly requested
- Always verify with `SraRunInfo_eccDNA_all2.csv` before syncing species classifications

---

*Last updated: 2026-07-28*
*Generated based on actual pipeline structure and verified conventions*