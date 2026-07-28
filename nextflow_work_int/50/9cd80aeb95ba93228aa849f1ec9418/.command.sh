#!/usr/bin/env bash -C -e -u -o pipefail
cat <<-END_FLAGSTAT > gdna_1.flagstat
1000000 + 0 in total (QC-passed reads + QC-failed reads)
0 + 0 secondary
0 + 0 supplementary
0 + 0 duplicates
900000 + 0 mapped (90.00% : N/A)
1000000 + 0 paired in sequencing
500000 + 0 read1
500000 + 0 read2
800000 + 0 properly paired (80.00% : N/A)
850000 + 0 with mate mapped to a different chr
50000 + 0 with mate mapped to a different chr (mapQ>=5)
END_FLAGSTAT

# capture process environment
set +u
set +e
cd "$NXF_TASK_WORKDIR"

nxf_eval_cmd() {
    {
        IFS=$'\n' read -r -d '' "${1}";
        IFS=$'\n' read -r -d '' "${2}";
        (IFS=$'\n' read -r -d '' _ERRNO_; return ${_ERRNO_});
    } < <((printf '\0%s\0%d\0' "$(((({ shift 2; "${@}"; echo "${?}" 1>&3-; } | tr -d '\0' 1>&4-) 4>&2- 2>&1- | tr -d '\0' 1>&4-) 3>&1- | exit "$(cat)") 4>&1-)" "${?}" 1>&2) 2>&1)
}

echo '' > .command.env
#
nxf_eval_cmd STDOUT STDERR bash -c "samtools version | sed '1!d;s/.* //'"
status=$?
if [ $status -eq 0 ]; then
  echo nxf_out_eval_16="$STDOUT" >> .command.env
  echo /nxf_out_eval_16/=exit:0 >> .command.env
else
  echo nxf_out_eval_16="$STDERR" >> .command.env
  echo /nxf_out_eval_16/=exit:$status >> .command.env
fi
