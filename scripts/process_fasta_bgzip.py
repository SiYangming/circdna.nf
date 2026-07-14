#!/usr/bin/env python3

import os
import subprocess
import gzip
import sys
import argparse
from pathlib import Path

FASTA_DIR = "/data1/users/siyangming/FASTA"
GENES_DIR = "/data1/users/siyangming/GENE"

SPECIES_MAP = {
    "Arabidopsis_thaliana": {
        "fasta": "Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz",
        "gtf": "Arabidopsis_thaliana.TAIR10.63.gtf.gz",
        "new_name": "Arabidopsis_thaliana.TAIR10.dna.fa",
        "filter_by_gtf": True
    },
    "Daucus_carota": {
        "fasta": "Daucus_carota.ASM162521v1.dna.toplevel.fa.gz",
        "gtf": "Daucus_carota.ASM162521v1.63.gtf.gz",
        "new_name": "Daucus_carota.ASM162521v1.dna.fa",
        "filter_by_gtf": True
    },
    "Helianthus_annuus": {
        "fasta": "Helianthus_annuus.HanXRQr2.0-SUNRISE.dna.toplevel.fa.gz",
        "gtf": "Helianthus_annuus.HanXRQr2.0-SUNRISE.63.gtf.gz",
        "new_name": "Helianthus_annuus.HanXRQr2.0-SUNRISE.dna.fa",
        "filter_by_gtf": True
    },
    "Oryza_sativa": {
        "fasta": "Oryza_sativa.IRGSP-1.0.dna.toplevel.fa.gz",
        "gtf": "Oryza_sativa.IRGSP-1.0.63.gtf.gz",
        "new_name": "Oryza_sativa.IRGSP-1.0.dna.fa",
        "filter_by_gtf": True
    },
    "Solanum_lycopersicum": {
        "fasta": "Solanum_lycopersicum_gca000188115v5cm.SL4.0.dna.toplevel.fa.gz",
        "gtf": "Solanum_lycopersicum_gca000188115v5cm.SL4.0.63.gtf.gz",
        "new_name": "Solanum_lycopersicum_gca000188115v5cm.SL4.0.dna.fa",
        "filter_by_gtf": True
    },
    "Triticum_aestivum": {
        "fasta": "Triticum_aestivum.IWGSC.dna.toplevel.fa.gz",
        "gtf": "Triticum_aestivum.IWGSC.63.gtf.gz",
        "new_name": "Triticum_aestivum.IWGSC.dna.fa",
        "filter_by_gtf": True
    },
    "Alopecurus_myosuroides": {
        "fasta": "GCA_028641055.1_Alomy_genome_v1_genomic.fna.gz",
        "new_name": "Alopecurus_myosuroides_v1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Amaranthus_palmeri_hap1": {
        "fasta": "GCA_051800445.1_Amaranthus_palmeri.hap1.genome.v01_genomic.fna.gz",
        "new_name": "Amaranthus_palmeri_hap1_v01.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Amaranthus_palmeri_hap2": {
        "fasta": "GCA_051800465.1_Amaranthus_palmeri.hap2.genome.v01_genomic.fna.gz",
        "new_name": "Amaranthus_palmeri_hap2_v01.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Artemisia_annua": {
        "fasta": "GCA_014162995.1_Aran_genomic.fna.gz",
        "new_name": "Artemisia_annua_v1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Cryptomeria_japonica": {
        "fasta": "GCF_030272615.1_Sugi_1.0_genomic.fna.gz",
        "new_name": "Cryptomeria_japonica_1.0.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Nicotiana_benthamiana": {
        "fasta": "GCA_034376525.1_ASM3437652v1_genomic.fna.gz",
        "new_name": "Nicotiana_benthamiana_v1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Tragopogon_porrifolius_hap1": {
        "fasta": "GCA_977969915.1_daTraPorr1.hap1.1_genomic.fna.gz",
        "new_name": "Tragopogon_porrifolius_hap1.1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Tragopogon_porrifolius_hap2": {
        "fasta": "GCA_977969905.1_daTraPorr1.hap2.1_genomic.fna.gz",
        "new_name": "Tragopogon_porrifolius_hap2.1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Beta_vulgaris": {
        "fasta": "Beta_vulgaris.RefBeet-1.2.2.dna.toplevel.fa.gz",
        "gtf": "Beta_vulgaris.RefBeet-1.2.2.63.gtf.gz",
        "new_name": "Beta_vulgaris.RefBeet-1.2.2.dna.fa",
        "filter_by_gtf": True
    },
    "Lycium_ruthenicum": {
        "fasta": "GCA_041430385.1_ASM4143038v1_genomic.fna.gz",
        "new_name": "Lycium_ruthenicum_ASM4143038v1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    },
    "Cynodon_dactylon": {
        "fasta": "GCA_046862365.1_ASM4686236v1_genomic.fna.gz",
        "new_name": "Cynodon_dactylon_ASM4686236v1.fa",
        "filter_by_gtf": False,
        "remove_version": True
    }
}

def check_dependencies():
    try:
        subprocess.run(["bgzip", "--version"], capture_output=True, check=True)
    except FileNotFoundError:
        print("❌ bgzip not found. Please install htslib first.")
        sys.exit(1)
    
    try:
        subprocess.run(["samtools", "--version"], capture_output=True, check=True)
    except FileNotFoundError:
        print("❌ samtools not found. Please install samtools first.")
        sys.exit(1)
    
    print("✅ Dependencies check passed")

def get_fai_path(bgz_path):
    bgz_path = Path(bgz_path)
    fai_path = Path(str(bgz_path) + ".fai")
    if fai_path.exists():
        return fai_path
    fai_path = bgz_path.parent / f"{bgz_path.stem}.fai"
    return fai_path

def get_gzi_path(bgz_path):
    bgz_path = Path(bgz_path)
    gzi_path = Path(str(bgz_path) + ".gzi")
    if gzi_path.exists():
        return gzi_path
    gzi_path = bgz_path.with_suffix('.gzi')
    return gzi_path

def get_file_size(path):
    size = os.path.getsize(path)
    if size < 1024:
        return f"{size} B"
    elif size < 1024 * 1024:
        return f"{size / 1024:.1f} KB"
    elif size < 1024 * 1024 * 1024:
        return f"{size / (1024 * 1024):.1f} MB"
    else:
        return f"{size / (1024 * 1024 * 1024):.1f} GB"

def get_gtf_seq_ids(gtf_path):
    seq_ids = set()
    with gzip.open(gtf_path, 'rt') as f:
        for line in f:
            if not line.startswith('#'):
                parts = line.split('\t')
                if len(parts) >= 1:
                    seq_ids.add(parts[0])
    return seq_ids

def process_fasta_to_bgzip(fasta_path, output_path, seq_ids=None, remove_version=False, force=False):
    bgz_path = Path(output_path).with_suffix('.bgz')
    fai_path = get_fai_path(bgz_path)
    gzi_path = get_gzi_path(bgz_path)
    
    if bgz_path.exists():
        if force:
            print(f"⚠️ Output file exists, removing for rebuild: {bgz_path.name}")
            os.remove(bgz_path)
            if fai_path.exists():
                os.remove(fai_path)
            if gzi_path.exists():
                os.remove(gzi_path)
        else:
            print(f"⚠️ Output file already exists, skipping: {bgz_path.name}")
            return False, 0, 0
    
    include_seq = True
    kept_count = 0
    skipped_count = 0
    
    bgzip_proc = subprocess.Popen(["bgzip", "-c"], stdin=subprocess.PIPE, stdout=open(bgz_path, 'wb'))
    
    try:
        with gzip.open(fasta_path, 'rt') as f:
            for line in f:
                line = line.rstrip('\n')
                
                if line.startswith('>'):
                    seq_id = line.split()[0][1:]
                    
                    if remove_version and '.' in seq_id:
                        seq_id = seq_id.split('.')[0]
                    
                    if seq_ids is not None:
                        if seq_id in seq_ids:
                            include_seq = True
                            kept_count += 1
                            bgzip_proc.stdin.write(('>' + seq_id + '\n').encode('utf-8'))
                        else:
                            include_seq = False
                            skipped_count += 1
                    else:
                        include_seq = True
                        kept_count += 1
                        bgzip_proc.stdin.write(('>' + seq_id + '\n').encode('utf-8'))
                elif include_seq:
                    bgzip_proc.stdin.write((line + '\n').encode('utf-8'))
        
        bgzip_proc.stdin.close()
        bgzip_proc.wait()
        
        if bgzip_proc.returncode != 0:
            raise subprocess.CalledProcessError(bgzip_proc.returncode, "bgzip")
        
        print(f"    Output: {bgz_path.name}")
        print(f"    Compressed size: {get_file_size(bgz_path)}")
        
        print(f"\n[3] Creating FASTA index with samtools faidx")
        cmd = ["samtools", "faidx", str(bgz_path)]
        subprocess.run(cmd, check=True)
        
        fai_path = get_fai_path(bgz_path)
        if fai_path.exists():
            print(f"    Index created: {fai_path.name}")
        
        return True, kept_count, skipped_count
        
    except Exception as e:
        print(f"❌ Failed: {e}")
        if bgz_path.exists():
            os.remove(bgz_path)
        return False, kept_count, skipped_count

def validate_gzip_file(file_path):
    try:
        with gzip.open(file_path, 'rt') as f:
            for _ in f:
                pass
        return True
    except (EOFError, OSError, gzip.BadGzipFile) as e:
        print(f"❌ Gzip file corrupted: {file_path} ({e})")
        return False

def cleanup_leftovers():
    leftover_patterns = ["*.fa.tmp", "*_genomic.gbff"]
    
    for pattern in leftover_patterns:
        for f in Path(FASTA_DIR).glob(pattern):
            print(f"🗑️ Removing leftover temp file: {f.name}")
            os.remove(f)
    
    for f in Path(FASTA_DIR).glob("*.py"):
        if f.name.startswith("convert_to_bgzip") or f.name.startswith("process_fasta_server"):
            print(f"🗑️ Removing old script: {f.name}")
            os.remove(f)

def verify_bgz_file(bgz_path):
    bgz_path = Path(bgz_path)
    
    if not bgz_path.exists():
        return False, "File not found"
    
    fai_path = get_fai_path(bgz_path)
    gzi_path = get_gzi_path(bgz_path)
    
    if not fai_path.exists():
        return False, "Missing .fai index"
    
    bgz_size = os.path.getsize(bgz_path)
    fai_size = os.path.getsize(fai_path)
    
    if bgz_size < 1024 * 1024:
        return False, f"File too small ({bgz_size} bytes), likely corrupted"
    
    if fai_size < 10:
        return False, f"Index too small ({fai_size} bytes), likely corrupted"
    
    try:
        with open(fai_path, 'r') as f:
            lines = f.readlines()
        
        num_seqs = len(lines)
        total_bp = 0
        for line in lines:
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                try:
                    total_bp += int(parts[1])
                except ValueError:
                    pass
        
        if num_seqs == 0:
            return False, "Index contains 0 sequences"
        
        return True, f"Valid: {num_seqs} sequences, {total_bp:,} bp"
    except Exception as e:
        return False, f"Validation error: {str(e)[:100]}"

def check_all_outputs():
    print(f"{'='*60}")
    print("Checking all output files")
    print(f"{'='*60}\n")
    
    all_ok = True
    need_rebuild = []
    
    for species, info in SPECIES_MAP.items():
        output_path = os.path.join(FASTA_DIR, info['new_name'])
        bgz_path = Path(output_path).with_suffix('.bgz')
        
        print(f"[{species}]")
        print(f"  File: {bgz_path.name}")
        
        if not os.path.exists(info['fasta']):
            fasta_path = os.path.join(FASTA_DIR, info['fasta'])
            print(f"  ❌ Input file not found: {info['fasta']}")
            all_ok = False
            continue
        
        if not bgz_path.exists():
            print(f"  ❌ Output missing")
            need_rebuild.append(species)
            all_ok = False
            continue
        
        is_valid, msg = verify_bgz_file(bgz_path)
        if is_valid:
            print(f"  ✅ {msg}")
        else:
            print(f"  ❌ {msg}")
            need_rebuild.append(species)
            all_ok = False
        
        print()
    
    print(f"{'='*60}")
    if all_ok:
        print("✅ All files are valid!")
    else:
        print(f"⚠️ {len(need_rebuild)} file(s) need rebuilding:")
        for s in need_rebuild:
            print(f"   - {s}")
    print(f"{'='*60}")
    
    return need_rebuild

def main():
    parser = argparse.ArgumentParser(description="FASTA Processor + bgzip Converter")
    parser.add_argument('--force', action='store_true', help='Force rebuild by removing existing .bgz files')
    parser.add_argument('--clean', action='store_true', help='Clean corrupted intermediate .fa.gz files and rebuild')
    parser.add_argument('--cleanup', action='store_true', help='Clean up leftover temp files and old scripts')
    parser.add_argument('--check', action='store_true', help='Check and verify all output files')
    parser.add_argument('--fix', action='store_true', help='Check and rebuild only problematic files')
    parser.add_argument('--species', type=str, help='Process only specified species (comma-separated)')
    args = parser.parse_args()
    
    if args.cleanup:
        cleanup_leftovers()
        return
    
    if args.check:
        check_all_outputs()
        return
    
    print(f"{'='*60}")
    print("FASTA Processor + bgzip Converter")
    print(f"{'='*60}")
    
    check_dependencies()
    
    target_species = None
    if args.species:
        target_species = set(s.strip() for s in args.species.split(','))
        print(f"\nTarget species: {', '.join(target_species)}")
    
    species_to_fix = None
    if args.fix:
        print("\n[Step 1/2] Checking all outputs first...")
        species_to_fix = set(check_all_outputs())
        if not species_to_fix:
            print("\n✅ All files are valid, nothing to fix!")
            return
        print(f"\n[Step 2/2] Rebuilding {len(species_to_fix)} problematic file(s)...")
    
    for species, info in SPECIES_MAP.items():
        if target_species and species not in target_species:
            continue
        
        if species_to_fix is not None and species not in species_to_fix:
            continue
        
        print(f"\n{'='*60}")
        print(f"Processing {species}")
        print(f"{'='*60}")
        
        fasta_path = os.path.join(FASTA_DIR, info['fasta'])
        output_path = os.path.join(FASTA_DIR, info['new_name'])
        
        if not os.path.exists(fasta_path):
            print(f"❌ FASTA file not found: {info['fasta']}")
            print(f"   Full path: {fasta_path}")
            
            alternatives = []
            for ext in ['.fna.gz', '.fasta.gz', '.fa.gz']:
                alt_path = fasta_path.replace('.fna.gz', ext) if '.fna.gz' in fasta_path else fasta_path + ext
                if os.path.exists(alt_path):
                    alternatives.append(os.path.basename(alt_path))
            
            if alternatives:
                print(f"   Found similar files: {', '.join(alternatives)}")
            continue
        
        bgz_path = Path(output_path).with_suffix('.bgz')
        old_gz_path = Path(output_path).with_suffix('.fa.gz')
        
        if args.clean and old_gz_path.exists():
            if not validate_gzip_file(old_gz_path):
                print(f"🗑️ Removing corrupted file: {old_gz_path.name}")
                os.remove(old_gz_path)
        
        if bgz_path.exists():
            if args.force or args.fix:
                print(f"⚠️ Output file exists, removing for rebuild: {bgz_path.name}")
                os.remove(bgz_path)
                fai_path = get_fai_path(bgz_path)
                if fai_path.exists():
                    os.remove(fai_path)
                gzi_path = get_gzi_path(bgz_path)
                if gzi_path.exists():
                    os.remove(gzi_path)
            else:
                print(f"⚠️ Output file already exists, skipping: {bgz_path.name}")
                continue
        
        seq_ids = None
        
        if info.get('filter_by_gtf', False):
            gtf_path = os.path.join(GENES_DIR, info['gtf'])
            if not os.path.exists(gtf_path):
                print(f"❌ GTF file not found, skipping filter: {info['gtf']}")
            else:
                print(f"[1] Reading GTF: {os.path.basename(gtf_path)}")
                seq_ids = get_gtf_seq_ids(gtf_path)
                print(f"Found {len(seq_ids)} sequence IDs")
        
        print(f"\n[2] Processing FASTA and converting to bgzip: {info['fasta']}")
        print(f"  - Filter by GTF: {'Yes' if seq_ids else 'No'}")
        print(f"  - Remove version: {'Yes' if info.get('remove_version', False) else 'No'}")
        
        success, kept, skipped = process_fasta_to_bgzip(
            fasta_path, 
            output_path, 
            seq_ids=seq_ids,
            remove_version=info.get('remove_version', False),
            force=args.force
        )
        
        if success:
            print(f"✅ Kept: {kept} sequences")
            if skipped > 0:
                print(f"❌ Skipped: {skipped} sequences")
            print(f"✅ Saved to: {bgz_path.name}")
            print(f"✅ Original file preserved: {info['fasta']}")
        else:
            print(f"⚠️ Failed: {info['new_name']}")
    
    print(f"\n{'='*60}")
    print("Processing complete!")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
