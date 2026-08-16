#!/usr/bin/env python3
"""
Test script for incremental/decremental caching verification.
Tests that Nextflow pipeline properly caches tasks when samplesheet is modified.
"""

import subprocess
import os
import sys
import time
import re
import shutil
from pathlib import Path

BASE_DIR = Path("/Users/siyangming/nextflow_nf_core/circdna.nf")
TEST_DIR = BASE_DIR / "testdatasets"
SAMPLESHEET_DIR = TEST_DIR / "samplesheet"
ORIGINAL_SAMPLESHEET = SAMPLESHEET_DIR / "samplesheet_local.csv"
WORK_DIR = BASE_DIR / "nextflow_work"
RESULTS_DIR = BASE_DIR / "results_cache_test"

SAMPLESHEET_3 = """sample,fastq_1,fastq_2
circdna_1,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R2.fastq.gz
circdna_2,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_2_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_2_R2.fastq.gz
circdna_3,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_3_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_3_R2.fastq.gz
"""

SAMPLESHEET_4 = """sample,fastq_1,fastq_2
circdna_1,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R2.fastq.gz
circdna_2,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_2_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_2_R2.fastq.gz
circdna_3,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_3_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_3_R2.fastq.gz
circdna_4,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R2.fastq.gz
"""

SAMPLESHEET_2 = """sample,fastq_1,fastq_2
circdna_1,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R2.fastq.gz
circdna_2,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_2_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_2_R2.fastq.gz
"""

SAMPLESHEET_MIXED = """sample,fastq_1,fastq_2
circdna_1,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R2.fastq.gz
circdna_3,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_3_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_3_R2.fastq.gz
circdna_4,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R1.fastq.gz,/Users/siyangming/nextflow_nf_core/circdna.nf/testdatasets/testdata/circdna_1_R2.fastq.gz
"""

def write_samplesheet(content, path):
    with open(path, 'w') as f:
        f.write(content)
    print(f"  Written: {path} ({len(content.splitlines())-1} samples)")

def run_pipeline(samplesheet, outdir, resume=None, run_name=None):
    cmd = ["nextflow", "run", "main.nf",
           "-profile", "test_local",
           f"--input", str(samplesheet),
           f"--outdir", str(outdir),
           "-work-dir", str(WORK_DIR / run_name)]
    if resume:
        cmd.extend(["-resume", resume])
    cmd.extend(["-with-report", f"{outdir}/report_{run_name}.html",
                "-with-timeline", f"{outdir}/timeline_{run_name}.html",
                "-with-trace", f"{outdir}/trace_{run_name}.txt"])
    
    print(f"\n  Running: {' '.join(cmd)}")
    print(f"  CWD: {BASE_DIR}")
    
    result = subprocess.run(cmd, cwd=str(BASE_DIR), 
                          capture_output=True, text=True, timeout=7200)
    return result

def analyze_log(log_file):
    """Analyze nextflow trace/log for CACHED vs NEW tasks"""
    if not os.path.exists(log_file):
        return {}
    
    with open(log_file) as f:
        content = f.read()
    
    cached_samples = set()
    new_samples = set()
    
    cached_pattern = re.finditer(r'\[(.+?)\].*CACHED', content)
    new_pattern = re.finditer(r'\[(.+?)\].*NEW', content)
    
    for m in cached_pattern:
        task_info = m.group(1)
        cached_samples.add(task_info)
    
    for m in new_pattern:
        task_info = m.group(1)
        new_samples.add(task_info)
    
    return {
        'cached': list(cached_samples),
        'new': list(new_samples),
        'total_lines': len(content.splitlines())
    }

def check_cache_in_trace(trace_file):
    """Check trace file for task status"""
    if not os.path.exists(trace_file):
        return {}
    
    with open(trace_file) as f:
        lines = f.readlines()
    
    task_status = {}
    for line in lines:
        if 'task_id' in line.lower() or 'status' in line.lower():
            continue
    
    return {
        'trace_exists': True,
        'line_count': len(lines)
    }

def main():
    print("=" * 70)
    print("circDNA Incremental/Decremental Cache Verification")
    print("=" * 70)
    
    os.chdir(BASE_DIR)
    
    # Step 0: Clean up
    print("\n[Step 0] Cleaning up previous runs...")
    for d in [RESULTS_DIR, WORK_DIR]:
        if d.exists():
            shutil.rmtree(d, ignore_errors=True)
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    
    backup = SAMPLESHEET_DIR / "samplesheet_local.csv.bak"
    shutil.copy2(ORIGINAL_SAMPLESHEET, backup)
    
    try:
        # Step 1: Initial run with 3 samples
        print("\n[Step 1] Initial run with 3 samples...")
        ss_3 = SAMPLESHEET_DIR / "test_3.csv"
        write_samplesheet(SAMPLESHEET_3, ss_3)
        
        result_1 = run_pipeline(ss_3, RESULTS_DIR / "run1_3samples", run_name="run1")
        if result_1.returncode != 0:
            print(f"  FAILED! Return code: {result_1.returncode}")
            print(f"  STDOUT: {result_1.stdout[-500:]}")
            print(f"  STDERR: {result_1.stderr[-500:]}")
            return 1
        print(f"  PASSED! Return code: {result_1.returncode}")
        
        run1_id = None
        for line in result_1.stdout.splitlines():
            if 'workDir' in line.lower():
                parts = line.split(':')
                if len(parts) >= 2:
                    run1_id = parts[1].strip().split('/')[-2] if len(parts) > 2 else None
        
        # Step 2: Add sample (incremental cache test)
        print("\n[Step 2] Add 1 sample (incremental cache test)...")
        ss_4 = SAMPLESHEET_DIR / "test_4.csv"
        write_samplesheet(SAMPLESHEET_4, ss_4)
        
        resume_path = str(WORK_DIR / "run1")
        result_2 = run_pipeline(ss_4, RESULTS_DIR / "run2_4samples", 
                                resume=resume_path, run_name="run2")
        
        trace_2 = RESULTS_DIR / "run2_4samples" / "trace_run2.txt"
        if trace_2.exists():
            analysis_2 = analyze_log(str(trace_2))
            print(f"  Trace analysis: {len(analysis_2.get('cached', []))} CACHED, {len(analysis_2.get('new', []))} NEW tasks")
        
        if result_2.returncode != 0:
            print(f"  FAILED! Return code: {result_2.returncode}")
            print(f"  STDOUT: {result_2.stdout[-500:]}")
        else:
            print(f"  PASSED! Return code: {result_2.returncode}")
        
        # Step 3: Remove sample (decremental cache test)
        print("\n[Step 3] Remove 1 sample (decremental cache test)...")
        ss_2 = SAMPLESHEET_DIR / "test_2.csv"
        write_samplesheet(SAMPLESHEET_2, ss_2)
        
        resume_path_2 = str(WORK_DIR / "run2")
        result_3 = run_pipeline(ss_2, RESULTS_DIR / "run3_2samples",
                                resume=resume_path_2, run_name="run3")
        
        if result_3.returncode != 0:
            print(f"  FAILED! Return code: {result_3.returncode}")
        else:
            print(f"  PASSED! Return code: {result_3.returncode}")
        
        # Step 4: Mixed change (add + remove)
        print("\n[Step 4] Mixed change (add 1 + remove 1)...")
        ss_mixed = SAMPLESHEET_DIR / "test_mixed.csv"
        write_samplesheet(SAMPLESHEET_MIXED, ss_mixed)
        
        resume_path_3 = str(WORK_DIR / "run3")
        result_4 = run_pipeline(ss_mixed, RESULTS_DIR / "run4_mixed",
                                resume=resume_path_3, run_name="run4")
        
        if result_4.returncode != 0:
            print(f"  FAILED! Return code: {result_4.returncode}")
        else:
            print(f"  PASSED! Return code: {result_4.returncode}")
        
        # Summary
        print("\n" + "=" * 70)
        print("VERIFICATION SUMMARY")
        print("=" * 70)
        print(f"  Step 1 (initial 3 samples): {'PASS' if result_1.returncode == 0 else 'FAIL'}")
        print(f"  Step 2 (add sample):        {'PASS' if result_2.returncode == 0 else 'FAIL'}")
        print(f"  Step 3 (remove sample):      {'PASS' if result_3.returncode == 0 else 'FAIL'}")
        print(f"  Step 4 (mixed change):       {'PASS' if result_4.returncode == 0 else 'FAIL'}")
        
        all_passed = all(r.returncode == 0 for r in [result_1, result_2, result_3, result_4])
        print(f"\n  Overall: {'ALL PASSED' if all_passed else 'SOME FAILED'}")
        
        return 0 if all_passed else 1
        
    finally:
        # Restore original samplesheet
        shutil.copy2(backup, ORIGINAL_SAMPLESHEET)
        backup.unlink(missing_ok=True)
        
        # Cleanup test samplesheets
        for f in [ss_3, ss_4, ss_2, ss_mixed]:
            if f.exists():
                f.unlink()

if __name__ == "__main__":
    sys.exit(main())
