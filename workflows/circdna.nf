/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'
include { INPUT_CHECK           } from '../subworkflows/local/input_check/main'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline/main'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline/main'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_circdna_pipeline/main'
include { CAT_FASTQ     }     from '../modules/nf-core/cat/fastq/main'
include { FASTQC        }     from '../modules/nf-core/fastqc/main'
include { TRIMGALORE    }    from '../modules/nf-core/trimgalore/main'
include { BWA_INDEX     }   from '../modules/nf-core/bwa/index/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_BAM        }   from '../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_BAM      }   from '../modules/nf-core/samtools/index/main'
include { SAMTOOLS_FAIDX                            }   from '../modules/nf-core/samtools/faidx/main'
include { CIRCEXPLORER2_PARSE       }     from '../modules/nf-core/circexplorer2/parse/main'
include { MULTIQC }     from '../modules/nf-core/multiqc/main'

include { BAM_PREPROCESSING              } from '../subworkflows/local/bam_preprocessing/main'
include { CIRCLE_MAP_PIPELINE            } from '../subworkflows/local/circle_map_pipeline/main'
include { CIRCLE_FINDER_PIPELINE         } from '../subworkflows/local/circle_finder_pipeline/main'
include { AMPLICONARCHITECT_PIPELINE     } from '../subworkflows/local/ampliconarchitect_pipeline/main'
include { UNICYCLER_PIPELINE             } from '../subworkflows/local/unicycler_pipeline/main'

workflow CIRCDNA {
    if (params.fasta) { 
        ch_fasta = channel.fromPath(params.fasta) 
    } else {
        def genome_fasta = WorkflowMain.getGenomeAttribute(params, 'fasta')
        if (genome_fasta) {
            params.fasta = genome_fasta
            ch_fasta = channel.fromPath(genome_fasta)
        } else {
            exit 1, 'Fasta reference genome not specified!' 
        }
    }
    if (!(params.input_format == "FASTQ" | params.input_format == "BAM")) {
    exit 1, 'Please specifiy --input_format "FASTQ" or "BAM" in capital letters, depending on the input file format.'
    }
    ch_fasta_meta = ch_fasta.map{ fasta -> [[id: fasta.baseName], fasta] }.collect()

    def branch = params.circle_identifier.split(",")
    def run_circexplorer2 = ("circexplorer2" in branch)
    def run_circle_map_realign = ("circle_map_realign" in branch)
    def run_circle_map_repeats = ("circle_map_repeats" in branch)
    def run_circle_finder = ("circle_finder" in branch)
    def run_ampliconarchitect = ("ampliconarchitect" in branch)
    def run_unicycler = ("unicycler" in branch)
    if (!(run_unicycler | run_circle_map_realign | run_circle_map_repeats | run_circle_finder | run_ampliconarchitect | run_circexplorer2)) {
    exit 1, 'circle_identifier param not valid. Please check!'
    }
    if (run_unicycler && !params.input_format == "FASTQ") {
        exit 1, 'Unicycler needs FastQ input. Please specify input_format == "FASTQ", if possible, or don`t run unicycler.'
    }
    if (!params.input) { exit 1, 'Input samplesheet not specified!' }
    def bwa_index_exists = false
    def ch_bwa_index = channel.empty()
    if (params.bwa_index) {
    ch_bwa_index = channel.fromPath(params.bwa_index, type: 'dir').collect()
    ch_bwa_index = ch_bwa_index.map{ index -> ["bwa_index", index] }.collect()
    bwa_index_exists = true
    } else {
    ch_bwa_index = channel.empty()
    bwa_index_exists = false
    }
    def mosek_license_dir = null
    def ch_cnvkit_reference = channel.empty()
    if (run_ampliconarchitect) {
    mosek_license_dir = params.mosek_license_dir
    if (!params.mosek_license_dir) {
        exit 1, "Mosek License Directory is missing! Please specifiy directory containing mosek license using --mosek_license_dir and rename license to 'mosek.lic'."
    } else {
        mosek_license_dir = file(params.mosek_license_dir)
    }
    if (!params.aa_data_repo) { exit 1, "AmpliconArchitect Data Repository Missing! Please see https://github.com/jluebeck/AmpliconArchitect for more information and specify its absolute path using --aa_data_repo." }
    if (params.reference_build != "hg19" & params.reference_build != "GRCh38" & params.reference_build != "GRCh37" & params.reference_build != "mm10"){
        exit 1, "Reference Build not given! Please specify --reference_build 'mm10', 'hg19', 'GRCh38', or 'GRCh37'."
    }
    if (!params.cnvkit_cnn) {
        ch_cnvkit_reference = file(params.aa_data_repo + "/" + params.reference_build + "/" + params.reference_build + "_cnvkit_filtered_ref.cnn", checkIfExists: true)
    } else {
        ch_cnvkit_reference = file(params.cnvkit_cnn)
    }
    }
    // CONFIG FILES
    def ch_multiqc_config          = channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    def ch_multiqc_custom_config   = params.multiqc_config ? channel.fromPath( params.multiqc_config, checkIfExists: true ) : channel.empty()
    def _ch_multiqc_logo            = params.multiqc_logo   ? channel.fromPath( params.multiqc_logo, checkIfExists: true ) : channel.empty()
    def ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

    // IMPORT LOCAL MODULES/SUBWORKFLOWS
    // IMPORT NF-CORE MODULES/SUBWORKFLOWS & LOCAL MODULES/SUBWORKFLOWS

    // RUN MAIN WORKFLOW
    def multiqc_report = []

    ch_versions = channel.empty()

    // Define Empty Channels for MultiQC
    ch_samtools_stats           = channel.empty()
    ch_samtools_flagstat        = channel.empty()
    ch_samtools_idxstats        = channel.empty()
    ch_markduplicates_stats     = channel.empty()
    ch_markduplicates_flagstat  = channel.empty()
    ch_markduplicates_idxstats  = channel.empty()
    ch_markduplicates_multiqc   = channel.empty()

    // Check file format
    if (params.input_format == "FASTQ") {
        //
        // SUBWORKFLOW: Read in samplesheet, validate and stage input files
        //
        INPUT_CHECK (
            file(params.input)
        )
        .reads
        .map {
            meta, fastq ->
                meta.id = meta.id.split('_')[0..-2].join('_')
                [ meta, fastq ] }
        .groupTuple(by: [0])
        .branch {
            meta, fastq ->
                single  : fastq.size() == 1 && meta.single_end
                    return [ meta, fastq.flatten() ]
                multiple: fastq.size() > 1 || !meta.single_end
                    return [ meta, fastq.flatten() ]
        }
        .set { ch_fastq }
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

        //
        // MODULE: Concatenate FASTQs from the same samples
        //
        CAT_FASTQ (
            ch_fastq.multiple
        )
        .reads
        .mix(ch_fastq.single)
        .set { ch_cat_fastq }

        ch_versions = ch_versions.mix(CAT_FASTQ.out.versions_cat)


        //
        // MODULE: Run FastQC
        //
        ch_fastqc_multiqc = channel.empty()
        if ( ! params.skip_qc ) {
            FASTQC (
                ch_cat_fastq
            )
            ch_versions         = ch_versions.mix(FASTQC.out.versions_fastqc)
            ch_fastqc_multiqc   = FASTQC.out.zip
        }

        //
        // MODULE: Run trimgalore
        //
        if ( ! params.skip_trimming ) {
            TRIMGALORE (
                ch_cat_fastq
            )
            ch_trimmed_reads            = TRIMGALORE.out.reads
            ch_trimgalore_multiqc       = TRIMGALORE.out.zip
            ch_trimgalore_multiqc_log   = TRIMGALORE.out.log
            ch_versions                 = ch_versions.mix(TRIMGALORE.out.versions_trimgalore)
        } else {
            ch_trimmed_reads            = ch_cat_fastq
            ch_trimgalore_multiqc       = channel.empty()
            ch_trimgalore_multiqc_log   = channel.empty()
        }

        //
        // MODULE: Run bwa index
        //
        if (!bwa_index_exists & (run_ampliconarchitect | run_circexplorer2 |
                                run_circle_finder | run_circle_map_realign |
                                run_circle_map_repeats)) {
            BWA_INDEX (
                ch_fasta_meta
            )
            ch_bwa_index = BWA_INDEX.out.index.map{ _meta, index -> ["bwa_index", index] }.collect()
            ch_versions = ch_versions.mix(BWA_INDEX.out.versions_bwa)
        }
    } else if (params.input_format == "BAM") {
        INPUT_CHECK (
            file(params.input)
        )
        if (!params.bam_sorted){
            SAMTOOLS_SORT_BAM (
                INPUT_CHECK.out.reads,
                channel.value([]),
                'bai'
            )
            ch_versions         = ch_versions.mix(SAMTOOLS_SORT_BAM.out.versions_samtools)
            ch_bam_sorted       = SAMTOOLS_SORT_BAM.out.bam
        } else {
            ch_bam_sorted       = INPUT_CHECK.out.reads
        }
        ch_fastqc_multiqc           = channel.empty()
        ch_trimgalore_multiqc       = channel.empty()
        ch_trimgalore_multiqc_log   = channel.empty()
    }

    if (run_ampliconarchitect | run_circexplorer2 | run_circle_finder |
        run_circle_map_realign | run_circle_map_repeats) {
        BAM_PREPROCESSING (
            params.input_format == "FASTQ" ? ch_trimmed_reads : ch_bam_sorted,
            ch_bwa_index,
            ch_fasta_meta,
            params.input_format == "FASTQ"
        )
        ch_bam_sorted               = BAM_PREPROCESSING.out.bam_sorted
        ch_bam_sorted_bai           = BAM_PREPROCESSING.out.bam_sorted_bai
        ch_full_bam_sorted          = BAM_PREPROCESSING.out.full_bam_sorted
        ch_full_bam_sorted_bai      = BAM_PREPROCESSING.out.full_bam_sorted_bai
        ch_samtools_stats           = BAM_PREPROCESSING.out.samtools_stats
        ch_samtools_flagstat        = BAM_PREPROCESSING.out.samtools_flagstat
        ch_samtools_idxstats        = BAM_PREPROCESSING.out.samtools_idxstats
        ch_markduplicates_stats     = BAM_PREPROCESSING.out.markduplicates_stats
        ch_markduplicates_flagstat  = BAM_PREPROCESSING.out.markduplicates_flagstat
        ch_markduplicates_idxstats  = BAM_PREPROCESSING.out.markduplicates_idxstats
        ch_markduplicates_multiqc   = BAM_PREPROCESSING.out.markduplicates_multiqc
        ch_versions = ch_versions.mix(BAM_PREPROCESSING.out.versions)
    }

    if (run_ampliconarchitect) {
        def ch_fasta_fai = ch_fasta_meta.join(SAMTOOLS_FAIDX.out.fai)
        AMPLICONARCHITECT_PIPELINE (
            ch_bam_sorted,
            ch_bam_sorted_bai,
            ch_fasta_fai,
            ch_cnvkit_reference,
            file(params.mosek_license_dir),
            file(params.aa_data_repo)
        )
        ch_versions = ch_versions.mix(AMPLICONARCHITECT_PIPELINE.out.versions)
    }

    //
    // SUBWORKFLOW - RUN CIRCLE_FINDER PIPELINE
    //
    if (run_circle_finder) {
        CIRCLE_FINDER_PIPELINE (
            ch_bam_sorted,
            ch_bam_sorted_bai,
            ch_full_bam_sorted,
            ch_full_bam_sorted_bai
        )
        ch_versions = ch_versions.mix(CIRCLE_FINDER_PIPELINE.out.versions)
    }

    //
    // SUBWORKFLOW: RUN CIRCLE-MAP REALIGN or REPEATS PIPELINE
    //
    if (run_circle_map_realign || run_circle_map_repeats) {
        CIRCLE_MAP_PIPELINE (
            ch_bam_sorted,
            ch_bam_sorted_bai,
            ch_fasta,
            run_circle_map_realign,
            run_circle_map_repeats
        )
        ch_versions = ch_versions.mix(CIRCLE_MAP_PIPELINE.out.versions)
    }


    if (run_circexplorer2) {
        CIRCEXPLORER2_PARSE (
            ch_bam_sorted
        )
        ch_versions = ch_versions.mix(CIRCEXPLORER2_PARSE.out.versions_circexplorer2)
    }

    if (run_unicycler && params.input_format == "FASTQ") {
        UNICYCLER_PIPELINE (
            ch_trimmed_reads,
            ch_fasta_meta
        )
        ch_versions = ch_versions.mix(UNICYCLER_PIPELINE.out.versions)
    }

    //
    // MODULE: Pipeline reporting
    //
    ch_versions_for_multiqc = softwareVersionsToYAML(ch_versions)
        .collectFile(name: 'software_versions_mqc.yml')

    //
    // MODULE: MultiQC
    //
    if (!params.skip_multiqc) {
        ch_multiqc_config                     = channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
        ch_multiqc_custom_config              = params.multiqc_config ? channel.fromPath(params.multiqc_config, checkIfExists: true) : channel.empty()
        ch_multiqc_logo                       = params.multiqc_logo ? channel.fromPath(params.multiqc_logo, checkIfExists: true) : channel.empty()
        summary_params                        = paramsSummaryMap(workflow)
        ch_workflow_summary                   = channel.value(paramsSummaryMultiqc(summary_params))
        ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
        ch_methods_description                = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))

        ch_multiqc_files = channel.empty()
            .mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
            .mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
            .mix(ch_versions_for_multiqc)
            .mix(ch_fastqc_multiqc.map { _meta, zip -> zip })
            .mix(ch_trimgalore_multiqc.map { _meta, zip -> zip })
            .mix(ch_trimgalore_multiqc_log.map { _meta, log -> log })
            .mix(ch_samtools_stats.map { _meta, stats -> stats })
            .mix(ch_samtools_flagstat.map { _meta, flagstat -> flagstat })
            .mix(ch_samtools_idxstats.map { _meta, idxstats -> idxstats })
            .mix(ch_markduplicates_stats.map { _meta, stats -> stats })
            .mix(ch_markduplicates_flagstat.map { _meta, flagstat -> flagstat })
            .mix(ch_markduplicates_idxstats.map { _meta, idxstats -> idxstats })
            .mix(ch_markduplicates_multiqc.map { _meta, metrics -> metrics })

        MULTIQC (
            ch_multiqc_files.collect().ifEmpty([]),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            [],
            []
        )
        multiqc_report = MULTIQC.out.report.toList()
    }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// No top-level statements allowed here in strict DSL2.
// The onComplete and onError event handlers must be moved to main.nf or be placed outside module scope if not causing errors.
// Wait, if we keep them here, we get "Statements cannot be mixed". Let's move them to main.nf!

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
