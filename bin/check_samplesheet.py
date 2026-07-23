#!/usr/bin/env python
# This script is based on the example at: https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/samplesheet/samplesheet_test_illumina_amplicon.csv

import os
import sys
import errno
import argparse


def parse_args(args=None):
    Description = "Reformat nf-core/circleseq samplesheet file and check its contents."
    Epilog = "Example usage: python check_samplesheet.py <FILE_IN> <FILE_OUT> <INPUT_FORMAT> <PROTOCOL>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input samplesheet file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("INPUT_FORMAT", help="'FASTQ' or 'BAM' File Format.")
    parser.add_argument("PROTOCOL", help="'short_read', 'pacbio', or 'ont' Sequencing Protocol.")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        try:
            os.makedirs(path)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise exception


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check samplesheet -> {}".format(error)
    if context != "" and context_str != "":
        error_str = "ERROR: Please check samplesheet -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
    print(error_str)
    sys.exit(1)


def check_samplesheet(file_in, file_out, input_format, protocol):
    """
    This function checks that the samplesheet follows the following structure:

    short_read FASTQ:
    sample,fastq_1,fastq_2
    SAMPLE_PE,SAMPLE_PE_RUN1_1.fastq.gz,SAMPLE_PE_RUN1_2.fastq.gz
    SAMPLE_SE,SAMPLE_SE_RUN1_1.fastq.gz,

    short_read BAM:
    sample,bam_file
    SAMPLE,SAMPLE.bam

    long-read (pacbio/ont):
    sample,fastq_1,input_bam,entrypoint
    SAMPLE,SAMPLE.fastq.gz,,cleaned_fastq
    SAMPLE,,SAMPLE.subreads.bam,subreads
    """

    sample_mapping_dict = {}
    with open(file_in, "r") as fin:
        if protocol == "short_read" and input_format == "FASTQ":
            MIN_COLS = 2
            HEADER = ["sample", "fastq_1", "fastq_2"]
            header = [x.strip('"') for x in fin.readline().strip().split(",")]
            if header[: len(HEADER)] != HEADER:
                print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
                sys.exit(1)

            for line in fin:
                lspl = [x.strip().strip('"') for x in line.strip().split(",")]

                if len(lspl) < len(HEADER):
                    print_error(
                        "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                        "Line",
                        line,
                    )
                num_cols = len([x for x in lspl if x])
                if num_cols < MIN_COLS:
                    print_error(
                        "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                        "Line",
                        line,
                    )

                sample, fastq_1, fastq_2 = lspl[: len(HEADER)]
                sample = sample.replace(" ", "_")
                if not sample:
                    print_error("Sample entry has not been specified!", "Line", line)

                for fastq in [fastq_1, fastq_2]:
                    if fastq:
                        if fastq.find(" ") != -1:
                            print_error("FastQ file contains spaces!", "Line", line)
                        if not fastq.endswith(".fastq.gz") and not fastq.endswith(".fq.gz"):
                            print_error(
                                "FastQ file does not have extension '.fastq.gz' or '.fq.gz'!",
                                "Line",
                                line,
                            )

                sample_info = []
                if sample and fastq_1 and fastq_2:
                    sample_info = ["0", fastq_1, fastq_2]
                elif sample and fastq_1 and not fastq_2:
                    sample_info = ["1", fastq_1, fastq_2]
                else:
                    print_error("Invalid combination of columns provided!", "Line", line)

                if sample not in sample_mapping_dict:
                    sample_mapping_dict[sample] = [sample_info]
                else:
                    if sample_info in sample_mapping_dict[sample]:
                        print_error("Samplesheet contains duplicate rows!", "Line", line)
                    else:
                        sample_mapping_dict[sample].append(sample_info)

        elif protocol == "short_read" and input_format == "BAM":
            MIN_COLS = 2
            HEADER = ["sample", "bam"]
            header = [x.strip('"') for x in fin.readline().strip().split(",")]
            if header[: len(HEADER)] != HEADER:
                print("ERROR: Please check samplesheet header -> {} != {}".format(",".join(header), ",".join(HEADER)))
                sys.exit(1)

            for line in fin:
                lspl = [x.strip().strip('"') for x in line.strip().split(",")]

                if len(lspl) < len(HEADER):
                    print_error(
                        "Invalid number of columns (minimum = {})!".format(len(HEADER)),
                        "Line",
                        line,
                    )
                num_cols = len([x for x in lspl if x])
                if num_cols < MIN_COLS:
                    print_error(
                        "Invalid number of populated columns (minimum = {})!".format(MIN_COLS),
                        "Line",
                        line,
                    )

                sample, bam = lspl[: len(HEADER)]
                sample = sample.replace(" ", "_")
                if not sample:
                    print_error("Sample entry has not been specified!", "Line", line)

                if bam:
                    if bam.find(" ") != -1:
                        print_error("BAM file contains spaces!", "Line", line)
                    if not bam.endswith(".bam"):
                        print_error(
                            "Bam file does not have extension '.bam'!",
                            "Line",
                            line,
                        )
                sample_info = ["1", bam]

                if sample not in sample_mapping_dict:
                    sample_mapping_dict[sample] = [sample_info]
                else:
                    if sample_info in sample_mapping_dict[sample]:
                        print_error("Samplesheet contains duplicate rows!", "Line", line)
                    else:
                        sample_mapping_dict[sample].append(sample_info)

        elif protocol in ["pacbio", "ont"]:
            MIN_COLS = 1
            HEADER = ["sample", "fastq_1", "input_bam", "entrypoint"]
            header = [x.strip('"') for x in fin.readline().strip().split(",")]
            if header[:1] != ["sample"]:
                print("ERROR: Please check samplesheet header -> {} should start with 'sample'".format(",".join(header)))
                sys.exit(1)

            for line in fin:
                lspl = [x.strip().strip('"') for x in line.strip().split(",")]

                while len(lspl) < len(HEADER):
                    lspl.append("")

                sample, fastq_1, input_bam, entrypoint = lspl[: len(HEADER)]
                sample = sample.replace(" ", "_")
                if not sample:
                    print_error("Sample entry has not been specified!", "Line", line)

                if fastq_1:
                    if fastq_1.find(" ") != -1:
                        print_error("FastQ file contains spaces!", "Line", line)
                    if not fastq_1.endswith(".fastq.gz") and not fastq_1.endswith(".fq.gz"):
                        print_error(
                            "FastQ file does not have extension '.fastq.gz' or '.fq.gz'!",
                            "Line",
                            line,
                        )

                if input_bam:
                    if input_bam.find(" ") != -1:
                        print_error("BAM file contains spaces!", "Line", line)
                    if not input_bam.endswith(".bam"):
                        print_error(
                            "BAM file does not have extension '.bam'!",
                            "Line",
                            line,
                        )

                if entrypoint and entrypoint not in ["cleaned_fastq", "raw_fastq", "subreads", "hifi_bam"]:
                    print_error(
                        "Invalid entrypoint '{}'! Must be one of: cleaned_fastq, raw_fastq, subreads, hifi_bam".format(entrypoint),
                        "Line",
                        line,
                    )

                if not fastq_1 and not input_bam:
                    print_error("Either fastq_1 or input_bam must be provided!", "Line", line)

                sample_info = ["1", fastq_1, input_bam, entrypoint]

                if sample not in sample_mapping_dict:
                    sample_mapping_dict[sample] = [sample_info]
                else:
                    if sample_info in sample_mapping_dict[sample]:
                        print_error("Samplesheet contains duplicate rows!", "Line", line)
                    else:
                        sample_mapping_dict[sample].append(sample_info)

        else:
            print_error("INPUT_FORMAT needs to be either 'FASTQ' or 'BAM' and PROTOCOL needs to be 'short_read', 'pacbio', or 'ont'")
            sys.exit(1)

        if len(sample_mapping_dict) > 0:
            out_dir = os.path.dirname(file_out)
            make_dir(out_dir)
            with open(file_out, "w") as fout:
                if protocol == "short_read" and input_format == "FASTQ":
                    fout.write(",".join(["sample", "single_end", "fastq_1", "fastq_2"]) + "\n")
                    for sample in sorted(sample_mapping_dict.keys()):
                        if not all(x[0] == sample_mapping_dict[sample][0][0] for x in sample_mapping_dict[sample]):
                            print_error(
                                "Multiple runs of a sample must be of the same datatype!",
                                "Sample: {}".format(sample),
                            )

                        for idx, val in enumerate(sample_mapping_dict[sample]):
                            fout.write(",".join(["{}_T{}".format(sample, idx + 1)] + val) + "\n")
                elif protocol == "short_read" and input_format == "BAM":
                    fout.write(",".join(["sample", "idx", "bam"]) + "\n")
                    for sample in sorted(sample_mapping_dict.keys()):
                        for idx, val in enumerate(sample_mapping_dict[sample]):
                            fout.write(",".join(["{}".format(sample)] + val) + "\n")
                elif protocol in ["pacbio", "ont"]:
                    fout.write(",".join(["sample", "single_end", "fastq_1", "input_bam", "entrypoint"]) + "\n")
                    for sample in sorted(sample_mapping_dict.keys()):
                        for idx, val in enumerate(sample_mapping_dict[sample]):
                            fout.write(",".join(["{}_T{}".format(sample, idx + 1)] + val) + "\n")

        else:
            print_error("No entries to process!", "Samplesheet: {}".format(file_in))


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT, args.INPUT_FORMAT, args.PROTOCOL)


if __name__ == "__main__":
    sys.exit(main())
