# test-datasets: `circdna`

This branch contains test data to be used for automated testing with the [nf-core/circdna](https://github.com/nf-core/circdna) pipeline.

## Content of this repository

`reference/`: Genome reference files (iGenomes R64-1-1 Ensembl release)

`testdata/` : 200,000 FastQ paired-end reads

`samplesheet/` : Sample sheet CSV files for testing

### Sample sheet files

| File | Description |
|------|-------------|
| `samplesheet_local.csv` | Default local test input (3 samples) |
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
  --input testdatasets/samplesheet/test_3.csv \
  --outdir results_testdata/run1 \
  -work-dir ./nextflow_work \
  -with-trace results_testdata/trace_run1.txt

# Run 2: Incremental cache test (4 samples, resume)
nextflow run main.nf \
  -profile test_local \
  --input testdatasets/samplesheet/test_4.csv \
  --outdir results_testdata/run2 \
  -work-dir ./nextflow_work \
  -resume \
  -with-trace results_testdata/trace_run2.txt

# Run 3: Decremental cache test (2 samples, resume)
nextflow run main.nf \
  -profile test_local \
  --input testdatasets/samplesheet/test_2.csv \
  --outdir results_testdata/run3 \
  -work-dir ./nextflow_work \
  -resume \
  -with-trace results_testdata/trace_run3.txt

# Run 4: Mixed cache test (3 samples, -1+1, resume)
nextflow run main.nf \
  -profile test_local \
  --input testdatasets/samplesheet/test_mixed.csv \
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
