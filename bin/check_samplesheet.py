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
    OPTIONAL_FIELDS = ["lane", "datatype", "platform", "protocol"]
    VALID_DATATYPES = ["gdna", "eccdna"]
    VALID_PLATFORMS = ["illumina", "pacbio", "ont"]
    VALID_PROTOCOLS = ["short_read", "long_read"]

    with open(file_in, "r") as fin:
        if protocol == "short_read" and input_format == "FASTQ":
            MIN_COLS = 2
            HEADER = ["sample", "fastq_1", "fastq_2"]
            header = [x.strip('"') for x in fin.readline().strip().split(",")]

            has_lane = "lane" in header
            has_datatype = "datatype" in header
            has_platform = "platform" in header
            has_protocol = "protocol" in header

            if header[:3] != HEADER:
                print("ERROR: Please check samplesheet header -> first 3 columns must be sample,fastq_1,fastq_2")
                sys.exit(1)

            for line in fin:
                lspl = [x.strip().strip('"') for x in line.strip().split(",")]

                # Check valid number of columns per row
                min_cols = 3
                if len(lspl) < min_cols:
                    print_error(
                        "Invalid number of columns (minimum = {})!".format(min_cols),
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

                ## Parse row as dictionary
                row = dict(zip(header, lspl + [''] * (len(header) - len(lspl))))

                ## Check sample name entries
                sample = row["sample"].replace(" ", "_")
                fastq_1 = row["fastq_1"]
                fastq_2 = row["fastq_2"]
                if not sample:
                    print_error("Sample entry has not been specified!", "Line", line)

                lane = ""
                if has_lane:
                    lane = row["lane"].strip()
                    if not lane:
                        print_error("Lane entry has not been specified!", "Line", line)

                datatype = ""
                if has_datatype:
                    datatype = row["datatype"].strip().lower()
                    if datatype and datatype not in VALID_DATATYPES:
                        print_error(
                            "Invalid datatype '{}'! Must be one of: {}".format(datatype, ", ".join(VALID_DATATYPES)),
                            "Line",
                            line,
                        )

                platform = ""
                if has_platform:
                    platform = row["platform"].strip().lower()
                    if platform and platform not in VALID_PLATFORMS:
                        print_error(
                            "Invalid platform '{}'! Must be one of: {}".format(platform, ", ".join(VALID_PLATFORMS)),
                            "Line",
                            line,
                        )

                protocol = ""
                if has_protocol:
                    protocol = row["protocol"].strip().lower()
                    if protocol and protocol not in VALID_PROTOCOLS:
                        print_error(
                            "Invalid protocol '{}'! Must be one of: {}".format(protocol, ", ".join(VALID_PROTOCOLS)),
                            "Line",
                            line,
                        )

                ## Check FastQ file extension
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
                ## Auto-detect paired-end/single-end
                sample_info = []  ## [single_end, fastq_1, fastq_2, lane, datatype, platform, protocol]
                if sample and fastq_1 and fastq_2:  ## Paired-end short reads
                    sample_info = ["0", fastq_1, fastq_2, lane, datatype, platform, protocol]
                elif sample and fastq_1 and not fastq_2:  ## Single-end short reads
                    sample_info = ["1", fastq_1, fastq_2, lane, datatype, platform, protocol]
                else:
                    print_error("Invalid combination of columns provided!", "Line", line)

                ## Create sample mapping dictionary = { sample: [ single_end, fastq_1, fastq_2, lane, datatype, platform, protocol ] }
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
                if protocol in ["pacbio", "ont"]:
                    fout.write(",".join(["sample", "single_end", "fastq_1", "input_bam", "entrypoint"]) + "\n")
                    for sample in sorted(sample_mapping_dict.keys()):
                        for idx, val in enumerate(sample_mapping_dict[sample]):
                            fout.write(",".join(["{}_T{}".format(sample, idx + 1)] + val) + "\n")
                elif input_format == "FASTQ":
                    out_header = ["sample", "single_end", "fastq_1", "fastq_2"]
                    if has_lane:
                        out_header.append("lane")
                    if has_datatype:
                        out_header.append("datatype")
                    if has_platform:
                        out_header.append("platform")
                    if has_protocol:
                        out_header.append("protocol")
                    fout.write(",".join(out_header) + "\n")
                    for sample in sorted(sample_mapping_dict.keys()):
                        if not all(x[0] == sample_mapping_dict[sample][0][0] for x in sample_mapping_dict[sample]):
                            print_error(
                                "Multiple runs of a sample must be of the same datatype!",
                                "Sample: {}".format(sample),
                            )

                        for idx, val in enumerate(sample_mapping_dict[sample]):
                            ## val = [single_end, fastq_1, fastq_2, lane, datatype, platform, protocol]
                            row_vals = [sample, val[0], val[1], val[2]]
                            if has_lane:
                                row_vals.append(val[3])
                            if has_datatype:
                                row_vals.append(val[4])
                            if has_platform:
                                row_vals.append(val[5])
                            if has_protocol:
                                row_vals.append(val[6])
                            if not has_lane:
                                row_vals[0] = "{}_T{}".format(sample, idx + 1)
                            fout.write(",".join(row_vals) + "\n")
                elif input_format == "BAM":
                    fout.write(",".join(["sample", "idx", "bam"]) + "\n")
                    for sample in sorted(sample_mapping_dict.keys()):
                        for idx, val in enumerate(sample_mapping_dict[sample]):
                            fout.write(",".join(["{}".format(sample)] + val) + "\n")

        else:
            print_error("No entries to process!", "Samplesheet: {}".format(file_in))


def main(args=None):
    args = parse_args(args)
    check_samplesheet(args.FILE_IN, args.FILE_OUT, args.INPUT_FORMAT, args.PROTOCOL)


if __name__ == "__main__":
    sys.exit(main())
