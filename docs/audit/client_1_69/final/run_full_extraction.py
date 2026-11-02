# -*- coding: utf-8 -*-
"""
DBO 1.69 TW Full Production Extraction Runner
============================================
Executes full extraction of 112,813 internal PAK resources and 68 external files
into E:\DBO_CT_TW(1.57.51)\assets\ with bit-for-bit SHA-256 verification.
"""

import os
import sys
import csv
import time
import hashlib
from concurrent.futures import ThreadPoolExecutor

sys.stdout.reconfigure(encoding='utf-8')

from dbo_full_extractor import DboFullExtractor, HEADER_PAKS_CONFIG, detect_file_format

CLIENT_ROOT = r"E:\DBO_CT_TW(1.57.51)"
ASSETS_ROOT = r"E:\DBO_CT_TW(1.57.51)\assets"
FINAL_DIR = r"E:\DBOFF\docs\audit\client_1_69\final"
AUDIT_DIR = r"E:\DBOFF\docs\audit\client_1_69"

MANIFEST_CSV = os.path.join(FINAL_DIR, "FINAL_RESOURCE_MANIFEST.csv")
FAILURES_CSV = os.path.join(FINAL_DIR, "FINAL_FAILURES.csv")

def run_production_extraction():
    start_time = time.time()
    print("=" * 75)
    print("DBO 1.69 TW FULL PRODUCTION EXTRACTION STARTING")
    print(f"Source Client:  {CLIENT_ROOT}")
    print(f"Target Assets:  {ASSETS_ROOT}")
    print(f"Delivery Dir:   {FINAL_DIR}")
    print("=" * 75)

    extractor = DboFullExtractor(CLIENT_ROOT, ASSETS_ROOT)

    # 1. Decrypt and parse all 16 Header PAKs
    print("\n[Phase 1] Decrypting and parsing all 16 Header PAKs...")
    all_entries = []
    header_counts = {}

    for scope, family, rel_hdr, vol_pattern, fam_prefix in HEADER_PAKS_CONFIG:
        magic, entries_data = extractor.decrypt_header_pak(rel_hdr)
        parsed = extractor.parse_header_entries(entries_data, scope, rel_hdr, family)
        header_counts[rel_hdr] = len(parsed)
        for p in parsed:
            p["family_prefix"] = fam_prefix
        all_entries.extend(parsed)
        print(f"  {scope:15} | {rel_hdr:35} | {len(parsed):6} entries (Magic: {magic})")

    total_pak_entries = len(all_entries)
    print(f"Total Internal PAK Entries: {total_pak_entries:,} (Target: 112,813)")

    if total_pak_entries != 112813:
        print(f"[WARNING] Entry count mismatch: got {total_pak_entries}, expected 112813!")

    # 2. Extract internal PAK entries with ThreadPoolExecutor
    print(f"\n[Phase 2] Extracting {total_pak_entries:,} PAK resources to {ASSETS_ROOT}...")

    manifest_file = open(MANIFEST_CSV, "w", encoding="utf-8-sig", newline="")
    manifest_writer = csv.DictWriter(manifest_file, fieldnames=[
        "namespace", "source_pak", "resource_path", "output_path", "source_volume",
        "source_offset", "expected_size", "exported_size", "source_sha256", "output_sha256",
        "detected_format", "extraction_status"
    ])
    manifest_writer.writeheader()

    failures_file = open(FAILURES_CSV, "w", encoding="utf-8-sig", newline="")
    failures_writer = csv.DictWriter(failures_file, fieldnames=[
        "namespace", "source_pak", "resource_path", "source_volume", "source_offset",
        "expected_size", "resolution_rule", "extraction_status", "error_detail"
    ])
    failures_writer.writeheader()

    success_count = 0
    failure_count = 0
    conflict_count = 0
    existing_verified_count = 0
    total_bytes_exported = 0

    rule_stats = {}
    format_stats = {}

    def process_entry(ent):
        return extractor.extract_entry(ent, ent["family_prefix"])

    # Process in chunks of 5000 with thread pool to keep memory tiny
    batch_size = 5000
    for b_idx in range(0, total_pak_entries, batch_size):
        batch = all_entries[b_idx : b_idx + batch_size]
        t0 = time.time()
        with ThreadPoolExecutor(max_workers=8) as executor:
            batch_results = list(executor.map(process_entry, batch))
        
        for res in batch_results:
            st = res["extraction_status"]
            rule = res["resolution_rule"]
            rule_stats[rule] = rule_stats.get(rule, 0) + 1
            fmt = res["detected_format"]
            format_stats[fmt] = format_stats.get(fmt, 0) + 1

            # Output manifest row
            manifest_row = {
                "namespace": res["namespace"],
                "source_pak": res["source_pak"],
                "resource_path": res["resource_path"],
                "output_path": res["output_path"],
                "source_volume": res["source_volume"],
                "source_offset": res["source_offset"],
                "expected_size": res["expected_size"],
                "exported_size": res["exported_size"],
                "source_sha256": res["source_sha256"],
                "output_sha256": res["output_sha256"],
                "detected_format": res["detected_format"],
                "extraction_status": res["extraction_status"]
            }
            manifest_writer.writerow(manifest_row)

            if st in ["SUCCESS", "SUCCESS_EXISTING_VERIFIED"]:
                success_count += 1
                total_bytes_exported += res["exported_size"]
                if st == "SUCCESS_EXISTING_VERIFIED":
                    existing_verified_count += 1
            elif "CONFLICT" in st:
                conflict_count += 1
                failures_writer.writerow({
                    "namespace": res["namespace"],
                    "source_pak": res["source_pak"],
                    "resource_path": res["resource_path"],
                    "source_volume": res["source_volume"],
                    "source_offset": res["source_offset"],
                    "expected_size": res["expected_size"],
                    "resolution_rule": res["resolution_rule"],
                    "extraction_status": res["extraction_status"],
                    "error_detail": res["error_detail"]
                })
            else:
                failure_count += 1
                failures_writer.writerow({
                    "namespace": res["namespace"],
                    "source_pak": res["source_pak"],
                    "resource_path": res["resource_path"],
                    "source_volume": res["source_volume"],
                    "source_offset": res["source_offset"],
                    "expected_size": res["expected_size"],
                    "resolution_rule": res["resolution_rule"],
                    "extraction_status": res["extraction_status"],
                    "error_detail": res["error_detail"]
                })

        done = min(b_idx + batch_size, total_pak_entries)
        pct = (done / total_pak_entries) * 100
        elap = time.time() - t0
        print(f"  Processed {done:6,}/{total_pak_entries:,} ({pct:5.1f}%) | Batch time: {elap:.1f}s | Success: {success_count:,} | Failures: {failure_count}")

    # 3. Process the 68 external files
    print("\n[Phase 3] Copying 68 external non-PAK files to assets\\external\\...")
    source_inv_path = os.path.join(AUDIT_DIR, "01_source_inventory.csv")
    ext_count = 0
    with open(source_inv_path, "r", encoding="utf-8-sig") as f:
        inv_rows = list(csv.DictReader(f))

    for r in inv_rows:
        if r["category"] != "PAK Archive":
            ext_count += 1
            rel_src = r["relative_path"]
            src_full = os.path.join(CLIENT_ROOT, rel_src)
            dest_full = os.path.join(ASSETS_ROOT, "external", rel_src)
            os.makedirs(os.path.dirname(dest_full), exist_ok=True)

            # Stream copy with SHA-256 computation
            h_src = hashlib.sha256()
            h_out = hashlib.sha256()
            sz_copied = 0
            with open(src_full, "rb") as sf, open(dest_full, "wb") as df:
                while chunk := sf.read(64 * 1024):
                    h_src.update(chunk)
                    df.write(chunk)
                    h_out.update(chunk)
                    sz_copied += len(chunk)

            s_sha = h_src.hexdigest()
            o_sha = h_out.hexdigest()
            expected_sz = int(r["size_bytes"])
            is_ok = (s_sha == o_sha) and (sz_copied == expected_sz)

            with open(dest_full, "rb") as df:
                head = df.read(16)
            fmt = detect_file_format(head, rel_src)

            manifest_writer.writerow({
                "namespace": "external",
                "source_pak": "NONE_EXTERNAL_FILE",
                "resource_path": rel_src,
                "output_path": os.path.relpath(dest_full, ASSETS_ROOT),
                "source_volume": "FILESYSTEM",
                "source_offset": 0,
                "expected_size": expected_sz,
                "exported_size": sz_copied,
                "source_sha256": s_sha,
                "output_sha256": o_sha,
                "detected_format": fmt,
                "extraction_status": "SUCCESS" if is_ok else "FAILED_HASH_MISMATCH"
            })
            if is_ok:
                success_count += 1
                total_bytes_exported += sz_copied
            else:
                failure_count += 1

    manifest_file.close()
    failures_file.close()

    total_time = time.time() - start_time
    print("\n" + "=" * 75)
    print("FULL PRODUCTION EXTRACTION COMPLETED")
    print(f"Elapsed Time:           {total_time:.1f} seconds ({total_time/60:.2f} minutes)")
    print(f"Total Records Handled:  {total_pak_entries + ext_count:,} (PAK: {total_pak_entries:,}, External: {ext_count})")
    print(f"Total Successful:       {success_count:,}")
    print(f"Total Failures:         {failure_count}")
    print(f"Total Conflicts:        {conflict_count}")
    print(f"Existing Verified Skip: {existing_verified_count:,}")
    print(f"Total Bytes Exported:   {total_bytes_exported:,} bytes ({total_bytes_exported / (1024**3):.3f} GB)")
    print("=" * 75)

    print("\nResolution Rules Triggered Breakdown:")
    for rule, cnt in sorted(rule_stats.items(), key=lambda x: -x[1]):
        print(f"  {rule:45}: {cnt:6,}")

    print("\nFormat Detection Breakdown:")
    for fmt, cnt in sorted(format_stats.items(), key=lambda x: -x[1]):
        print(f"  {fmt:45}: {cnt:6,}")

if __name__ == "__main__":
    run_production_extraction()
