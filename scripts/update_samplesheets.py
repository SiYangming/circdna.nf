import pandas as pd
import os
import re

BASE_DIR = "/Users/siyangming/nextflow_nf_core/circdna.nf/samplesheets"

SPECIES_NAME_MAP = {
    "Oryza_sativa_Japonica_Group": "Oryza_sativa",
}

def extract_species(path):
    match = re.search(r'/eccDNA/([^/]+)/', path)
    if match:
        sp = match.group(1)
        return SPECIES_NAME_MAP.get(sp, sp)
    match = re.search(r'/circRNA/([^/]+)/', path)
    if match:
        sp = match.group(1)
        return SPECIES_NAME_MAP.get(sp, sp)
    return None

def split_by_species(df):
    species_map = {}
    for idx, row in df.iterrows():
        species = None
        for col in ['fastq_1', 'fastq_2']:
            if pd.notna(row.get(col)) and str(row[col]).strip():
                s = extract_species(str(row[col]))
                if s:
                    species = s
                    break
        if species is None:
            sample = str(row.get('sample', ''))
            if '_circRNA' in sample:
                for col in ['fastq_1', 'fastq_2']:
                    if pd.notna(row.get(col)) and str(row[col]).strip():
                        s = extract_species(str(row[col]))
                        if s:
                            species = s
                            break
            if species is None:
                continue
        if species not in species_map:
            species_map[species] = []
        species_map[species].append(row)
    return species_map

def read_csv_safe(filepath):
    if not os.path.exists(filepath):
        return None
    try:
        df = pd.read_csv(filepath)
        if len(df) == 0:
            return None
        return df
    except Exception:
        return None

def update_circdna_ngs():
    print("=" * 60)
    print("Processing circDNA NGS data (including other_clean merge)...")
    print("=" * 60)

    ngs_file = os.path.join(BASE_DIR, "circdna_ngs_clean.csv")
    other_file = os.path.join(BASE_DIR, "circdna_other_clean.csv")

    ngs_df = pd.read_csv(ngs_file)
    print(f"  Read {len(ngs_df)} entries from circdna_ngs_clean.csv")

    other_df = read_csv_safe(other_file)
    other_count = 0
    if other_df is not None:
        print(f"  Read {len(other_df)} entries from circdna_other_clean.csv")
        other_count = len(other_df)

    combined_df = ngs_df.copy()
    if other_df is not None:
        combined_df = pd.concat([combined_df, other_df], ignore_index=True)

    species_map = split_by_species(combined_df)

    print(f"\n  Species distribution:")
    total = 0
    for sp, rows in sorted(species_map.items()):
        print(f"    {sp}: {len(rows)} entries")
        total += len(rows)
    print(f"    Total: {total}")

    all_rows = []
    existing_files = [f for f in os.listdir(BASE_DIR) if f.startswith("circdna_") and f.endswith("_eccDNA.csv")]

    for f in existing_files:
        fp = os.path.join(BASE_DIR, f)
        os.remove(fp)
        print(f"  Deleted: {f} (will be regenerated)")

    for sp, rows in sorted(species_map.items()):
        species_df = pd.DataFrame(rows)

        file_name = f"circdna_{sp}_eccDNA.csv"
        file_path = os.path.join(BASE_DIR, file_name)

        species_df.to_csv(file_path, index=False)
        print(f"  Created: {file_name} ({len(rows)} entries)")

        all_rows.extend(rows)

    if all_rows:
        all_df = pd.DataFrame(all_rows)
        all_file = os.path.join(BASE_DIR, "circdna_all.csv")
        all_df.to_csv(all_file, index=False)
        print(f"  Updated: circdna_all.csv ({len(all_rows)} entries)")

def update_circdna_tgs():
    print("\n" + "=" * 60)
    print("Processing circDNA TGS (long-read) data...")
    print("=" * 60)

    clean_file = os.path.join(BASE_DIR, "circdna_tgs_clean.csv")
    df = pd.read_csv(clean_file)
    print(f"  Read {len(df)} entries from circdna_tgs_clean.csv")

    species_map = split_by_species(df)

    print(f"\n  Species distribution:")
    total = 0
    for sp, rows in sorted(species_map.items()):
        print(f"    {sp}: {len(rows)} entries")
        total += len(rows)
    print(f"    Total: {total}")

    all_rows = []
    existing_files = [f for f in os.listdir(BASE_DIR) if f.startswith("circdnalr_") and f.endswith("_long_read.csv")]

    for f in existing_files:
        fp = os.path.join(BASE_DIR, f)
        os.remove(fp)
        print(f"  Deleted: {f} (will be regenerated)")

    for sp, rows in sorted(species_map.items()):
        species_df = pd.DataFrame(rows)

        file_name = f"circdnalr_{sp}_long_read.csv"
        file_path = os.path.join(BASE_DIR, file_name)

        species_df.to_csv(file_path, index=False)
        print(f"  Created: {file_name} ({len(rows)} entries)")

        all_rows.extend(rows)

    if all_rows:
        all_df = pd.DataFrame(all_rows)
        all_file = os.path.join(BASE_DIR, "circdnalr_all.csv")
        all_df.to_csv(all_file, index=False)
        print(f"  Updated: circdnalr_all.csv ({len(all_rows)} entries)")

def update_circrna():
    print("\n" + "=" * 60)
    print("Processing circRNA data...")
    print("=" * 60)

    clean_file = os.path.join(BASE_DIR, "circrna_clean.csv")
    df = pd.read_csv(clean_file)
    print(f"  Read {len(df)} entries from circrna_clean.csv")

    species_map = split_by_species(df)

    print(f"\n  Species distribution:")
    total = 0
    for sp, rows in sorted(species_map.items()):
        print(f"    {sp}: {len(rows)} entries")
        total += len(rows)
    print(f"    Total: {total}")

    all_rows = []
    existing_files = [f for f in os.listdir(BASE_DIR) if f.startswith("circrna_") and f.endswith("_circRNA.csv") and f != "circrna_all.csv"]

    for f in existing_files:
        fp = os.path.join(BASE_DIR, f)
        os.remove(fp)
        print(f"  Deleted: {f} (will be regenerated)")

    for sp, rows in sorted(species_map.items()):
        species_df = pd.DataFrame(rows)

        file_name = f"circrna_{sp}_circRNA.csv"
        file_path = os.path.join(BASE_DIR, file_name)

        species_df.to_csv(file_path, index=False)
        print(f"  Created: {file_name} ({len(rows)} entries)")

        all_rows.extend(rows)

    if all_rows:
        all_df = pd.DataFrame(all_rows)
        all_file = os.path.join(BASE_DIR, "circrna_all.csv")
        all_df.to_csv(all_file, index=False)
        print(f"  Updated: circrna_all.csv ({len(all_rows)} entries)")

def update_ont_isoseq():
    print("\n" + "=" * 60)
    print("Updating ont_samples.csv and isoseq_samples.csv...")
    print("=" * 60)

    tgs_file = os.path.join(BASE_DIR, "circdna_tgs_clean.csv")
    df = pd.read_csv(tgs_file)

    ont_rows = []
    isoseq_rows = []

    for idx, row in df.iterrows():
        sample = str(row.get('sample', ''))
        platform = str(row.get('fastq_1', ''))

        if 'ont' in sample.lower() or 'nanopore' in platform.lower():
            ont_rows.append(row)
        elif 'isoseq' in sample.lower() or 'pacbio' in platform.lower():
            isoseq_rows.append(row)
        else:
            ont_rows.append(row)

    if ont_rows:
        ont_df = pd.DataFrame(ont_rows)
        ont_file = os.path.join(BASE_DIR, "ont_samples.csv")
        ont_df.to_csv(ont_file, index=False)
        print(f"  Updated: ont_samples.csv ({len(ont_rows)} entries)")

    if isoseq_rows:
        isoseq_df = pd.DataFrame(isoseq_rows)
        isoseq_file = os.path.join(BASE_DIR, "isoseq_samples.csv")
        isoseq_df.to_csv(isoseq_file, index=False)
        print(f"  Updated: isoseq_samples.csv ({len(isoseq_rows)} entries)")

def main():
    print("Samplesheets Update Script v2")
    print("=" * 60)
    print(f"Base directory: {BASE_DIR}")
    print()

    update_circdna_ngs()
    update_circdna_tgs()
    update_circrna()
    update_ont_isoseq()

    print("\n" + "=" * 60)
    print("Update completed!")
    print("=" * 60)

if __name__ == "__main__":
    main()
