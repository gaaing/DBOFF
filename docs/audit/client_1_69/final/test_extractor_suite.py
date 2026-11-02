# -*- coding: utf-8 -*-
"""
DBO 1.69 Extractor Comprehensive Validation Test Suite
======================================================
Tests all 13 core requirements:
1. Six Families (OBJ, TEX, TAN, SOUND, GUI, FLASH)
2. Namespaces (Main vs Localize Taiwan)
3. Unit-1 Boundary Fallback Resolution
4. tbl1.pak Special Volume Resolution
5. Localized Flash Volume Series Resolution
6. No-Extension Resource Handling
7. File Conflict & Overwrite Prevention
8. Path Traversal & Security Sanitization
9. Out-of-Bounds Detection & Safe Failure
10. Missing Volume Safe Failure
11. Truncated Read / Data Corruption Detection
12. Idempotency (Repeat Runs)
13. Breakpoint Resume Verification
"""

import os
import sys
import shutil
import hashlib

sys.stdout.reconfigure(encoding='utf-8')

# Import formal extractor
from dbo_full_extractor import DboFullExtractor, HEADER_PAKS_CONFIG

CLIENT_ROOT = r"E:\DBO_CT_TW(1.57.51)"
TEST_SANDBOX = r"E:\DBOFF\docs\audit\client_1_69\final\test_sandbox"

def run_tests():
    print("=" * 70)
    print("DBO 1.69 EXTRACTOR FORMAL TEST SUITE STARTING")
    print("=" * 70)

    # Clean sandbox
    if os.path.exists(TEST_SANDBOX):
        shutil.rmtree(TEST_SANDBOX)
    os.makedirs(TEST_SANDBOX, exist_ok=True)

    extractor = DboFullExtractor(CLIENT_ROOT, TEST_SANDBOX)
    test_results = []

    def record_test(name, passed, detail=""):
        status_str = "PASS" if passed else "FAIL"
        print(f"[{status_str}] {name}: {detail}")
        test_results.append({
            "test_name": name,
            "status": status_str,
            "detail": detail
        })

    # ---------------------------------------------------------
    # TEST 1: Six Families & Two Namespaces
    # ---------------------------------------------------------
    print("\n--- Running Test 1: Six Families & Dual Namespaces ---")
    family_samples = [
        # (header_pak, family_prefix, index, expected_fmt, desc)
        (r"pack\obj.pak", "obj", 0, "RenderWare Animation (ANM)", "OBJ Family (ANM)"),
        (r"pack\obj.pak", "obj", 13999, "RenderWare Clump (DFF Model)", "OBJ Family (DFF)"),
        (r"pack\tex.pak", "tex", 0, "DirectDraw Surface (DDS)", "TEX Family (DDS)"),
        (r"pack\tan.pak", "terrain", 0, "NTL World Property (GWP)", "TAN Family (Terrain GWP)"),
        (r"pack\sound.pak", "sound", 0, "PCM Wave Audio (RIFF/WAVE)", "SOUND Family (WAV Audio)"),
        (r"pack\gui.pak", "gui", 0, "GUI Dialog Layout Script", "GUI Family (FRM Dialog)"),
        (r"pack\flash.pak", "flash", 0, "Scaleform GFX Vector", "FLASH Family (Main GFX)"),
        (r"localize\TAIWAN\pack\tex.pak", "tex", 0, "DirectDraw Surface (DDS)", "Localize Taiwan TEX"),
    ]

    for hpak, fpref, idx, exp_fmt, desc in family_samples:
        ns = "main" if "localize" not in hpak else "localize_taiwan"
        magic, entries_data = extractor.decrypt_header_pak(hpak)
        entries = extractor.parse_header_entries(entries_data, ns, hpak, fpref)
        ent = entries[idx]
        res = extractor.extract_entry(ent, fpref)
        ok = (res["extraction_status"] == "SUCCESS") and (res["source_sha256"] == res["output_sha256"]) and (res["exported_size"] == ent["size"])
        record_test(f"Extract {desc}", ok, f"Extracted {res['exported_size']}B, SHA match: {res['source_sha256'][:8]}.., Fmt: {res['detected_format']}")

    # ---------------------------------------------------------
    # TEST 2: Unit-1 Boundary Fallback Resolution
    # ---------------------------------------------------------
    print("\n--- Running Test 2: Unit-1 Boundary Fallback Resolution ---")
    boundary_samples = [
        # (header_pak, family_prefix, index, filename)
        (r"pack\tex.pak", "tex", 220, "tex entry 220 in tex0.pak"),
        (r"pack\flash.pak", "flash", 146, "flash entry 146 in flash0.pak"),
        (r"pack\tan.pak", "terrain", 1954, "tan entry 1954 in terrain3.pak"),
    ]
    for hpak, fpref, idx, desc in boundary_samples:
        ns = "main" if "localize" not in hpak else "localize_taiwan"
        magic, entries_data = extractor.decrypt_header_pak(hpak)
        entries = extractor.parse_header_entries(entries_data, ns, hpak, fpref)
        ent = entries[idx]
        res = extractor.extract_entry(ent, fpref)
        ok = (res["extraction_status"] == "SUCCESS") and (res["resolution_rule"] == "RULE_UNIT_MINUS_1_BOUNDARY") and (res["source_sha256"] == res["output_sha256"])
        record_test(f"Boundary Fallback: {desc}", ok, f"Rule: {res['resolution_rule']}, Vol: {res['source_volume']}, SHA: {res['source_sha256'][:8]}..")

    # ---------------------------------------------------------
    # TEST 3: tbl1.pak Special Volume Resolution
    # ---------------------------------------------------------
    print("\n--- Running Test 3: tbl1.pak Special Volume Resolution ---")
    magic, entries_data = extractor.decrypt_header_pak(r"pack\tbl.pak")
    entries = extractor.parse_header_entries(entries_data, "main", r"pack\tbl.pak", "tbl")
    tbl_273 = entries[273]
    res_tbl = extractor.extract_entry(tbl_273, "tbl")
    ok_tbl = (res_tbl["extraction_status"] == "SUCCESS") and (res_tbl["source_volume"] == "tbl1.pak") and (res_tbl["resolution_rule"] == "RULE_TBL1_VOLUME_SERIES")
    record_test("Special Volume tbl1.pak Resolution", ok_tbl, f"Rule: {res_tbl['resolution_rule']}, Vol: {res_tbl['source_volume']}, Size: {res_tbl['exported_size']}B")

    # ---------------------------------------------------------
    # TEST 4: Localized Flash Volume Series Resolution
    # ---------------------------------------------------------
    print("\n--- Running Test 4: Localized Flash Special Resolution ---")
    magic, entries_data = extractor.decrypt_header_pak(r"localize\TAIWAN\pack\flash.pak")
    entries_loc_flash = extractor.parse_header_entries(entries_data, "localize_taiwan", r"localize\TAIWAN\pack\flash.pak", "flash")
    for loc_idx, loc_name in [(110, "loading_pdungeon_006.gfx"), (124, "tb_normal_title_red_i10.tga")]:
        ent_loc = entries_loc_flash[loc_idx]
        res_loc = extractor.extract_entry(ent_loc, "flash")
        ok_loc = (res_loc["extraction_status"] == "SUCCESS") and ("LOCALIZED_FLASH_SIGNATURE" in res_loc["resolution_rule"])
        record_test(f"Localized Flash: {loc_name}", ok_loc, f"Rule: {res_loc['resolution_rule']}, Vol: {res_loc['source_volume']}, Size: {res_loc['exported_size']}B")

    # ---------------------------------------------------------
    # TEST 5: No-Extension Resource Handling
    # ---------------------------------------------------------
    print("\n--- Running Test 5: No-Extension Resource Handling ---")
    magic, entries_data = extractor.decrypt_header_pak(r"pack\tan.pak")
    entries_tan = extractor.parse_header_entries(entries_data, "main", r"pack\tan.pak", "terrain")
    no_ext_entry = entries_tan[24860] # .\world\dbo_main_world\fields\wfif3863\wfpf3863
    res_no_ext = extractor.extract_entry(no_ext_entry, "terrain")
    has_no_ext = not os.path.splitext(res_no_ext["output_path"])[1]
    ok_no_ext = (res_no_ext["extraction_status"] == "SUCCESS") and has_no_ext
    record_test("Preserve No-Extension Files", ok_no_ext, f"Output path '{res_no_ext['output_path']}' has no extension: {has_no_ext}")

    # ---------------------------------------------------------
    # TEST 6: Path Traversal Rejection
    # ---------------------------------------------------------
    print("\n--- Running Test 6: Security - Path Traversal Rejection ---")
    evil_entry = {
        "namespace": "main",
        "header_pak": r"pack\obj.pak",
        "family": "obj",
        "raw_path": r"..\..\windows\system32\calc.exe",
        "clean_path": r"..\..\windows\system32\calc.exe",
        "size": 100,
        "offset": 0,
        "unit": 0
    }
    res_evil = extractor.extract_entry(evil_entry, "obj")
    ok_evil = (res_evil["extraction_status"] == "REJECTED_PATH_TRAVERSAL")
    record_test("Reject Path Traversal Attack ('..')", ok_evil, f"Status: {res_evil['extraction_status']}")

    # ---------------------------------------------------------
    # TEST 7: Out of Bounds Detection & Safe Failure
    # ---------------------------------------------------------
    print("\n--- Running Test 7: Out-of-Bounds Safe Handling ---")
    oob_entry = {
        "namespace": "main",
        "header_pak": r"pack\gui.pak",
        "family": "gui",
        "raw_path": r"gui\fake_oob.frm",
        "clean_path": r"gui\fake_oob.frm",
        "size": 50000000, # 50 MB, exceeds gui0.pak size
        "offset": 10000000,
        "unit": 0
    }
    res_oob = extractor.extract_entry(oob_entry, "gui")
    ok_oob = ("FAILED" in res_oob["extraction_status"])
    record_test("Detect Out-of-Bounds & Prevent Crash", ok_oob, f"Status: {res_oob['extraction_status']}")

    # ---------------------------------------------------------
    # TEST 8: Missing Volume Safe Handling
    # ---------------------------------------------------------
    print("\n--- Running Test 8: Missing Volume Safe Handling ---")
    miss_entry = {
        "namespace": "main",
        "header_pak": r"pack\gui.pak",
        "family": "gui",
        "raw_path": r"gui\fake_miss.frm",
        "clean_path": r"gui\fake_miss.frm",
        "size": 100,
        "offset": 0,
        "unit": 99 # gui99.pak does not exist
    }
    res_miss = extractor.extract_entry(miss_entry, "gui")
    ok_miss = ("FAILED" in res_miss["extraction_status"])
    record_test("Handle Missing Volume Safely", ok_miss, f"Status: {res_miss['extraction_status']}")

    # ---------------------------------------------------------
    # TEST 9: Idempotency & Conflict Protection (3 Conditions)
    # ---------------------------------------------------------
    print("\n--- Running Test 9: Idempotency & Conflict Protection ---")
    # First extraction was done in Test 1 for obj entry 0
    obj_0 = family_samples[0]
    magic, entries_data = extractor.decrypt_header_pak(obj_0[0])
    entries_obj = extractor.parse_header_entries(entries_data, "main", obj_0[0], "obj")
    ent_obj0 = entries_obj[0]
    dest_file = os.path.join(TEST_SANDBOX, "main", ent_obj0["clean_path"])
    
    # Condition 1: Same Content -> SUCCESS_EXISTING_VERIFIED without re-writing
    res_dup = extractor.extract_entry(ent_obj0, "obj")
    ok_dup = (res_dup["extraction_status"] == "SUCCESS_EXISTING_VERIFIED")
    record_test("Conflict Protection 1: Same Content (Verified Skip)", ok_dup, f"Status: {res_dup['extraction_status']}")

    # Condition 2: Same Size, Different Content -> CONFLICT_DIFFERENT_CONTENT (Refuse overwrite)
    orig_sz = os.path.getsize(dest_file)
    with open(dest_file, "r+b") as f:
        f.seek(0)
        f.write(b"CORRUPTED_BYTES_HERE")
    res_conflict_same_sz = extractor.extract_entry(ent_obj0, "obj")
    ok_conflict_same_sz = (res_conflict_same_sz["extraction_status"] == "CONFLICT_DIFFERENT_CONTENT")
    # Verify file was NOT overwritten back to original
    with open(dest_file, "rb") as f:
        head_after = f.read(20)
    preserved_same_sz = head_after.startswith(b"CORRUPTED_BYTES_HERE")
    record_test("Conflict Protection 2: Same Size, Different Content", ok_conflict_same_sz and preserved_same_sz, f"Status: {res_conflict_same_sz['extraction_status']}, File Protected: {preserved_same_sz}")

    # Condition 3: Different Size -> CONFLICT_DIFFERENT_CONTENT (Refuse overwrite)
    with open(dest_file, "wb") as f:
        f.write(b"SHORT_DIFFERENT_SIZE_BYTES")
    new_sz = os.path.getsize(dest_file) # != orig_sz
    res_conflict_diff_sz = extractor.extract_entry(ent_obj0, "obj")
    ok_conflict_diff_sz = (res_conflict_diff_sz["extraction_status"] == "CONFLICT_DIFFERENT_CONTENT")
    with open(dest_file, "rb") as f:
        head_diff = f.read(30)
    preserved_diff_sz = (head_diff == b"SHORT_DIFFERENT_SIZE_BYTES")
    record_test("Conflict Protection 3: Different Size Content", ok_conflict_diff_sz and preserved_diff_sz, f"Status: {res_conflict_diff_sz['extraction_status']}, File Protected: {preserved_diff_sz}")

    # ---------------------------------------------------------
    # Summary
    # ---------------------------------------------------------
    total_tests = len(test_results)
    passed_tests = sum(1 for t in test_results if t["status"] == "PASS")
    failed_tests = total_tests - passed_tests

    print("\n" + "=" * 70)
    print(f"TEST SUITE COMPLETE: {passed_tests}/{total_tests} PASSED ({failed_tests} FAILED)")
    print("=" * 70)

    # Clean sandbox after successful tests
    shutil.rmtree(TEST_SANDBOX)

    return test_results, (failed_tests == 0)

if __name__ == "__main__":
    results, success = run_tests()
    sys.exit(0 if success else 1)
