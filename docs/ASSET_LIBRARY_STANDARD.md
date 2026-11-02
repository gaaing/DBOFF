# DBOFF Asset Library Standard and Cleanup Plan

> Status: proposal / not yet executed. This document defines the safe workflow for building a complete, deduplicated, traceable asset library. It does not authorize deletion, overwriting, bulk conversion, or R2 upload.

## 1. Goals

Build a clean, organized, reproducible asset library for DBOFF while preserving every original source and every meaningful variant.

The library must answer:
- Which original pak and internal entry did an asset come from?
- Is this file byte-identical to another file, merely similar, or a legitimate variant?
- Which converted/runtime files were generated from it, using which tool and settings?
- Which project systems or resources reference it?
- Can the project root move without invalidating asset identity or manifests?

## 2. Three-layer storage model

### A. Source Archive — immutable
- Preserve all original .pak files and their relative paths.
- Decode all pak files into a new, separate extraction destination; do not overwrite the existing raw directory.
- Keep decoded source files unchanged.
- Record source pak hash, size, relative path, decoder/version, arguments, per-pak status, logs, entry counts, output counts and validation warnings.
- Never rename, merge, normalize or delete source files in this layer.

### B. Canonical Library — indexed and deduplicated
- Organize logical assets by type and stable asset identity, not by the original drive letter or absolute path.
- Use stable asset_id values and manifests. Paths in manifests should be relative to a configurable library root.
- Keep source aliases and provenance records even when identical physical content is stored once.
- Separate exact duplicates, equivalent content, similarity candidates and legitimate variants.
- Do not collapse assets solely because filenames, dimensions, geometry or perceptual similarity match.

### C. Runtime Assets — reproducible outputs
- Generate Godot-ready GLB, textures, audio and other runtime formats from the canonical/source records.
- Record converter name/version, settings, source asset_id(s), output hash, output format and validation status.
- Runtime resources should resolve through stable IDs or generated catalogs rather than hardcoded machine-specific absolute paths.
- Rebuild outputs from source when converters or import settings change.

## 3. Duplicate detection policy

Classify duplicates in separate confidence tiers:

1. **Exact byte duplicate**: same SHA-256 and byte size. Safe to share one stored blob, but preserve every original path, pak entry and alias in provenance.
2. **Decoded-content duplicate**: different container/encoding but identical normalized decoded content. Candidate for shared storage only after the normalization method is documented and validated.
3. **High-similarity candidate**: similar model geometry, texture pixels, audio waveform/features or metadata. Report for review; do not automatically merge.
4. **Legitimate variant**: distinct gender/body/age rig, topology, skeleton, weights, attachment points, material, texture, animation, LOD or gameplay variant. Preserve as a separate logical asset and link it to a variant family.

A duplicate report must distinguish:
- duplicate physical bytes;
- same logical asset with multiple source locations;
- same-name but different-content files;
- similar but non-identical candidates;
- valid variants;
- unresolved cases.

Never delete source files during scanning or classification. Deduplication initially means catalog-level aliasing and storage planning, not destructive cleanup.

## 4. Type-specific comparison

- **Models**: compare topology, vertex/index counts, vertex order where meaningful, normals, UVs, material slots/faces, skeleton, bone names, weights, attachment points, mesh parts, LOD and animation compatibility.
- **Textures/images**: compare decoded pixel content, dimensions, channels, color space, mipmaps, alpha and compression; preserve materially different resolutions or variants.
- **Animations**: compare skeleton compatibility, track/bone names, duration, keyframes, root motion and event tracks. Same action label does not prove equivalence.
- **Audio**: compare decoded audio fingerprints and metadata such as duration, sample rate, channels and codec; preserve alternate language, quality, loop points and separately used cues.
- **UI/effects/fonts/data**: compare internal structure and references, not just filenames or file hashes.

## 5. Required manifests and reports

At minimum generate:
- pak_manifest.csv/json — every original pak, relative path, size, SHA-256 and version/type metadata.
- pak_extraction_log.csv/json — one record per pak, status, tool/version, arguments, counts, output bytes, warnings and errors.
- source_inventory.csv — every decoded source entry with stable source_id, pak provenance, internal path, size, hash, detected type and signature.
- project_inventory.csv — every project-side file, including audio, UI, effects, fonts, data, scripts and scenes; classify generated/import/cache metadata separately.
- duplicate_groups.csv — exact duplicate groups and their provenance.
- similarity_candidates.csv — non-exact candidates with comparison method and confidence; never auto-delete.
- variant_families.csv — related but distinct assets and the evidence supporting variant relationships.
- source_project_mapping.csv — bidirectional source-to-project mappings, including one-to-many and many-to-one conversions.
- runtime_outputs.csv — generated outputs and converter provenance.
- unresolved_assets.csv — unknown type, unmatched source, unmatched project asset and unresolved mapping.
- asset_catalog.json — stable IDs, relative paths, aliases, provenance, variants, references and validation state.

Every scan must record timestamp, tool version, scan roots, exclusions and ruleset version so results are reproducible.

## 6. Safe execution order

### Phase 0 — read-only tool review
Inspect the pak decoder and export/conversion scripts. Confirm supported pak formats, sound pak handling, error handling, path behavior, overwrite behavior, filtering rules and validation. Do not run a bulk extraction yet.

### Phase 1 — pak inventory
Enumerate all original pak files, including the 66 sound pak reported by the previous scan. Produce a manifest and identify unsupported or ambiguous packages.

### Phase 2 — complete extraction to a new destination
Only after the decoder review and user approval, decode all packages into a new empty destination separate from the existing raw and project folders. Do not overwrite. Record a per-pak result and validate package/entry integrity where the format allows it.

### Phase 3 — full bidirectional inventory
Scan the complete decoded source and every project asset root. Do not infer that a resource is absent because it is not in a known folder. Include existing project audio independently of the current raw sound folder.

### Phase 4 — duplicate and variant analysis
Run exact hashing first, then format-aware content comparisons, then similarity analysis. Produce reports only. No destructive deletion or relocation.

### Phase 5 — canonical catalog proposal
Propose a stable-ID catalog and folder layout. Verify that references, aliases, variants and provenance remain resolvable if the library root changes. Test on a small sample before bulk adoption.

### Phase 6 — runtime conversion and validation
Convert from canonical/source records using versioned tools. Validate model materials and rigging, texture correctness, animation compatibility, audio decoding/playback references, UI loading and data parsing.

### Phase 7 — controlled cleanup
Only after user review, move or deduplicate project-side copies according to the approved catalog. Preserve the source archive and keep a reversible change log. No automatic source deletion.

## 7. Metrics — keep separate

Do not combine these into one coverage percentage:
- source package extraction completeness;
- source-to-project asset coverage;
- project asset provenance/traceability;
- conversion success rate;
- runtime usability rate;
- exact duplicate storage reduction;
- unresolved/variant-review counts.

## 8. Path portability

- A configurable root path is allowed to change.
- Stable asset identity must not depend on drive letters or absolute paths.
- Store relative paths from the configured root, stable IDs and SHA-256.
- Keep root configuration outside the generated catalog, so moving the library requires changing one root setting rather than rewriting every record.
- Validate path relocation by moving a small test library and resolving its catalog before adopting the scheme.

## 9. Current known blockers

From the first Antigravity report, not independently re-scanned:
- 469 pak files were reported; 66 sound pak were reported as not decoded.
- Existing raw is therefore not yet a complete source baseline.
- The report's raw-to-export missing counts are provisional and must not be treated as final missing-asset counts.
- The report's duplicate count is not yet a trusted deletion list; grouping rules and variant false positives need review.
- Decoder/exporter source code and versioned logs were not present in the checked GitHub repository at the time of review.
- Project audio exists according to the user, but a complete independent audio inventory has not yet been provided.
- The complete binary asset library is not in the GitHub repository; the repository's ignore rules exclude most binary asset directories.
- R2 storage of the full asset library is paused. Keep the library local for now; revisit R2 only for release distribution after package size and delivery needs are known.

## 10. Immediate next task for Antigravity

Start with a **read-only inspection**, not a bulk extraction:
1. Locate and report the exact pak decoder, batch extraction scripts, export scripts and configuration files.
2. List all pak files, including sound pak, with relative paths, sizes and SHA-256.
3. Explain which package types the decoder supports and whether it can decode every listed pak.
4. Trace filters, skipped extensions, swallowed exceptions, output naming and overwrite behavior.
5. Identify how extraction completeness can be validated.
6. Independently inventory all existing project audio files and all project asset roots.
7. Produce a proposed execution plan and list risks. Do not extract, overwrite, move, rename, delete, convert or upload anything until the user approves the plan.

## 11. Acceptance rule

The library is not considered clean merely because duplicate files were removed or folders look tidy. It is ready for systematic game reconstruction only when source provenance, variants, references, conversion lineage and runtime validation are queryable and reproducible.


## 12. Version authority and untrusted reference assets

### 12.1 Preferred source baseline

The user has selected the DBO_CT_TW 1.69 TW package set as DBOFF's preferred original-resource baseline. The user identifies the associated client/table label as DBO_CT_TW (1.57.51), corresponding to 1.69 TW. This version mapping is currently user-reported; verify it against package/client metadata and a complete pak manifest before declaring every package confirmed.

The authoritative source archive should therefore be built from the selected 1.69 TW original PAK files plus their complete, validated extraction outputs. Keep the original PAK files immutable.

### 12.2 OpenDBO source separation

- OpenDBO-Core remains an independent code and behavior reference for mechanisms, structures, resource references and implementation research.
- OpenDBO repository assets/ and previously extracted raw/ are **not** presumed to be official or version-pure DBO assets. They may contain private-server customizations, replacements or resources from other client versions.
- Treat those files as untrusted reference candidates until provenance and content are checked against the selected 1.69 TW source.
- Do not copy, merge, overwrite or promote OpenDBO assets into the canonical source archive solely because they exist in OpenDBO or are referenced by its code.

### 12.3 Revised source comparison workflow

1. Inventory every selected 1.69 TW PAK with relative path, size, SHA-256, detectable version/region metadata and package type.
2. Verify decoder compatibility for all package categories, including sound and non-model packages.
3. Extract into a new isolated destination with per-package logs and integrity checks; never overwrite existing raw or project assets.
4. Build the source inventory from the validated 1.69 TW extraction, then perform bidirectional mapping against all project assets.
5. Inventory OpenDBO assets/raw separately and compare candidates by provenance, internal identifiers, content and format-aware structure. Filename similarity alone is not proof of identity or official origin.
6. Preserve disagreements as separate records. Classify them as matching, modified/custom candidate, other-version candidate or unresolved; do not automatically merge or delete.
7. Preserve existing project assets. Reclassify them by provenance and conversion quality; only regenerate individual assets when evidence shows they are missing, incorrect or lossy.

### 12.4 Required evidence before the baseline is accepted as complete

- Complete 1.69 TW PAK manifest and hashes;
- package/client metadata supporting version and region identity;
- decoder source/version/configuration and per-package extraction logs;
- complete project inventory, including audio, UI, effects and fonts;
- All Text Table file manifest and version evidence;
- separate OpenDBO asset/raw inventory and provenance where available.

The selected version is the project policy decision; completeness and package integrity remain validation tasks.


## 13. Local 1.69 TW client-root inventory handoff (revised 2026-11-02)

The user identifies `E:\\DBO_CT_TW(1.57.51)\\` as the root of the downloaded client believed to be the final pre-shutdown 1.69 TW release. The `pack\\` directory is only one subdirectory containing PAK containers. The user has clarified that additional resources exist elsewhere in the client root; therefore the audit and eventual source archive must not be limited to PAK files. This is a user-reported local path; remote reviewers cannot inspect it directly.

### Read-only inventory scope

1. Recursively inventory **every file under the complete client root**, including all files inside and outside `pack\\`. Record relative path, extension, size and SHA-256; produce machine-readable CSV/JSON manifests and concise aggregate summaries.
2. Separately report:
   - PAK/container files under `pack\\`;
   - any PAK/container files found outside `pack\\`;
   - all non-PAK files and directories outside `pack\\`.
3. Classify non-PAK files lightly using path, extension, file signature and metadata. Candidate classes include executable/client components, configuration, language/localization, tables/data, scripts, audio, images, models, UI, plugins, patch/update metadata, cache/temp and unknown. These are hypotheses until supported by evidence; do not silently discard unknown files.
4. Inspect root-level version/update metadata and executable version resources to support client version/region identification. Record exact evidence paths and fields.
5. Inspect the PAK decoder and batch tools separately. Establish per-package compatibility, including sound and non-model packages, and document filtering, swallowed exceptions, collision/overwrite behavior and validation coverage.
6. Propose how PAK outputs and original non-PAK resources will be preserved in a single traceable source archive without altering the client installation.

### Token and output limits

- Use deterministic scripts for recursive enumeration, hashing, file signatures and aggregate statistics; these tasks do not require AI interpretation.
- Save full inventories as CSV/JSON files. In chat, report totals, category summaries, anomalies and only the small number of metadata/code excerpts needed for decisions. Do not paste thousands of manifest rows.
- Do not re-parse the previous raw tree or repeat last week's broad asset analysis.
- Do not deeply inspect every file. Escalate only ambiguous formats, version evidence, decoder compatibility and exceptions that affect completeness.

### Safety

This is a read-only audit. Do not write to or modify any file under `E:\\DBO_CT_TW(1.57.51)\\`. Do not extract, convert, move, rename, overwrite, delete or upload anything during this inspection. Do not begin bulk extraction until the user approves the plan.

### Acceptance boundary

The source archive can be called a complete client-resource baseline only after:
- the entire client root has been inventoried;
- all PAK/container files have been identified and their extraction status validated;
- every non-PAK file has been classified as an original resource, client/runtime component, metadata/tooling, cache/temp, or unresolved;
- all original resource-bearing files outside PAK have been preserved alongside the validated PAK extraction outputs.

A complete PAK extraction alone is not proof that the complete client resource set has been captured.


## 14. Additional local project asset roots identified (2026-11-01)

The user confirms these directories exist in the local DBOFF project:
- `assets/effect/`
- `assets/gui/`
- `assets/prop/property/`

Their absence from the GitHub tree is not evidence that they are absent locally. The current repository `.gitignore` uses an assets whitelist that explicitly allows `assets/tbl/` but does not yet allow these three roots. Before tracking them, inventory file counts, total size, largest files, extensions, and cache/temp content. Then adjust ignore rules narrowly and stage only these three paths. Do not stage the entire `assets/` tree. The contents and completeness of `assets/gui/`, including the suspected two SWF-derived JSON files, remain unverified until their names/content are inspected.


## 15. Narrow asset whitelist staged locally (2026-11-02)

The user corrected the assets ignore rules and locally staged only .gitignore, assets/effect/, assets/gui/, and assets/prop/property/ (also re-added assets/tbl/ in case it had staged changes). The reported staged additions are 2 effect JSON files, 2 GUI dictionary JSON files, and 7 property JSON files. A staged-path filter for assets outside tbl/, effect/, gui/, and prop/property/ returned no matches, so the accidentally exposed GLB files do not appear in the supplied staged listing.

Git emitted CRLF-to-LF normalization warnings for these JSON files; these are line-ending notices, not evidence of content corruption. The local status also showed docs/pak_audit_1_69/ as untracked and not staged. Inspect that directory separately before deciding whether it belongs in the repository.

This is based on the user's pasted local command output. The complete staged diff, final ignore file, file-size audit, and commit/push status have not yet been inspected. Do not commit or push until those checks are reviewed.
