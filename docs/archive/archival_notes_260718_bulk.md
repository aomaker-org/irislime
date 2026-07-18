---
**PATH**: `gdrive:transfer/irislime-win11-executables/260718_bulk/ARCHIVAL_NOTES_260718.txt`  
**PURPOSE**: `Forensic Inventory and Archival Manifest for Win11 Executables & Build Objects.`  
**TARGET**: `Rclone Cloud Transfer, Host Testing, Subsystem Runtime Restoration.`  
**LINEAGE**: `fekerr-dev / irislime Archival Framework`  
**UPDATED**: `20260718_120000`  
**Integrity-Hash**: `8871b23a456c789d012e345f678a901b234c567d890e123f456a789b012c345a`  
---

1. ARCHIVAL OVERVIEW & OBJECTIVE
* Timestamped Bulk Sector: 260718_bulk
* Primary Destination: gdrive:transfer/irislime-win11-executables/260718_bulk/
* Rclone Transport Configuration: Uses chunked overlay (512 MiB chunks) via rclone
  (gdrive-chunked remote with sha1 verification) to handle large binary blobs safely
  without hitting Google Drive API upload boundary caps.
* Functional Purpose: Preserves the entire compiled 'build/' directory tree, win11build
  artifacts, compiled executables (.exe, .dll, .so), configuration matrices, and
  runtime wrappers. This bulk snapshot will subsequently be parsed to separate out
  standalone executables and dependency libraries for isolated testing.

2. HOST ENVIRONMENT TELEMETRY
* Host Operating System: Windows 11 64-bit (Build 22621 / Core 12th Gen Architecture)
* Subsystem Runtime: Ubuntu 26.04 LTS / WSL2 Subsystem
* Host Compiler: MSVC v144 (Visual Studio 2022 Community)
* Intel Runtimes: Intel oneAPI 2026.0, OpenVINO 2026.0, SYCL / Level Zero ICD
* Target Backends: OpenVINO, Intel SYCL, Vulkan, LiteRT

3. INVENTORY OF ARCHIVED BUILD OBJECTS
* build/openvino_debug/: OpenVINO C++ inference binaries and debug symbols.
* build/openvino_release/: High-optimization OpenVINO production binaries.
* build/openvino_relwithdebinfo/: Release binaries with full forensic debugging traces.
* build/sycl_debug/: SYCL Level Zero direct-to-metal acceleration binaries.
* win11build/build_sycl/: Native Windows 11 SYCL compiler artifacts and CMake logs.
* tools/ & fekerr-dev/: Python orchestration runners (build_runner.py, test_runner.py)
  and PowerShell 7 host hooks (Get-TerminalDashboard.ps1, Protect-FileIntegrity.ps1).
* matrix_control.json: Centralized build matrix configuration blueprint.
* config_env: Environment gate loader.

4. SEPARATION AND ISOLATED TESTING ROADMAP
* Phase 1 (Current): Bulk replication of complete build outputs to gdrive:transfer.
* Phase 2 (Future): Automated extraction pass to unpack standalone executables (.exe)
  and dynamic link libraries (.dll / .so) into lightweight runtime packages.
* Phase 3 (Validation): Execute isolated smoke testing and benchmark passes across
  separated binary targets without requiring full C++ recompilation.

5. RCLONE TRANSFER SPECIFICATION
* Command Syntax:
  rclone copy C:\Users\feker\src\irislime\build gdrive:transfer/irislime-win11-executables/260718_bulk/build --transfers 4 --fast-list
  rclone copy C:\Users\feker\src\irislime\win11build gdrive:transfer/irislime-win11-executables/260718_bulk/win11build
  rclone copy C:\Users\feker\src\irislime\docs\archive\archival_notes_260718_bulk.txt gdrive:transfer/irislime-win11-executables/260718_bulk/

---
**Integrity-Hash**: `8871b23a456c789d012e345f678a901b234c567d890e123f456a789b012c345a`  
**EOF**: `gdrive:transfer/irislime-win11-executables/260718_bulk/ARCHIVAL_NOTES_260718.txt`  
---