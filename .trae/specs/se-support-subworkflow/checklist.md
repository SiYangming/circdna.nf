# SE Support & Subworkflow Splitting - Verification Checklist

- [x] Checkpoint 1: SE samplesheet with only `fastq_1` column can be parsed correctly
- [x] Checkpoint 2: PE samplesheet with `fastq_1` and `fastq_2` columns continues to work
- [x] Checkpoint 3: CAT_FASTQ processes SE data without errors
- [x] Checkpoint 4: TRIMGALORE processes SE data with --single flag
- [x] Checkpoint 5: BWA_MEM aligns SE data correctly with paired=false
- [x] Checkpoint 6: CIRCLEMAP_READEXTRACTOR processes SE BAM files without errors
- [x] Checkpoint 7: bam_preprocessing subworkflow runs successfully
- [x] Checkpoint 8: circle_map_pipeline subworkflow runs successfully
- [x] Checkpoint 9: circle_finder_pipeline subworkflow runs successfully
- [x] Checkpoint 10: ampliconarchitect_pipeline subworkflow runs successfully
- [x] Checkpoint 11: unicycler_pipeline subworkflow runs successfully
- [x] Checkpoint 12: Main workflow uses subworkflows instead of individual modules
- [x] Checkpoint 13: Pipeline output structure is the same for SE and PE data
- [x] Checkpoint 14: CHANGELOG.md is updated with all changes
- [x] Checkpoint 15: CHANGES&FIX document is created with detailed changes
