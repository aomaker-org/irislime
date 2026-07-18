======================================================================
WSL CLOUD BACKUP SYSTEM: DIRECT STREAM SEGMENTATION SPECIFICATION
======================================================================

1. STRUCTURAL OVERVIEW
----------------------------------------------------------------------
This subsystem provides a zero-disk-overhead backup pipeline for heavy 
WSL ext4.vhdx virtual machine files on space-constrained host machines. 
By coupling the standard output (stdout) stream of "wsl --export" 
directly into an "rclone rcat" boundary overlayed by a virtual "chunker" 
abstraction, the host operating system transfers snapshots straight out 
of volatile memory to the cloud network adapter. The local hard drive 
experiences zero write amplification during execution.

                           [ HOST RAM BUFFER ]
+--------------------+     +-----------------+     +-----------------+
|  wsl --export -    | ==> | Inline Segment  | ==> | Google Drive    |
| (Continuous Stream)|     | (2 GiB Chunks)  |     | Remote Target   |
+--------------------+     +-----------------+     +-----------------+


2. REMOTE REGISTRY CONFIGURATION (rclone.conf)
----------------------------------------------------------------------
To deploy this architecture, the host machine's rclone configuration 
file must contain both the foundational storage target and the virtual 
chunking encapsulation layer. 

Append the following structural blocks to your host rclone.conf:

[gdrive]
type = drive
scope = drive
token = {"access_token":"...","token_type":"Bearer","refresh_token":"...","expiry":"..."}

[gdrive-chunked]
type = chunker
remote = gdrive:transfer/2026LaptopsArchive/irislime_reviews/20260717_719p/
chunk_size = 2GiB
hash_type = sha1


3. REVIEW WORKSPACE TARGET STAGING MATRIX
----------------------------------------------------------------------
For the active review pass (20260717_719p), the three target instances 
are mapped to explicit identity subdirectories using your visual prompt 
tags to isolate data spaces cleanly.

| Linux Subsystem Name | Prompt Tag | Chunker Cloud Target Path                      |
| :------------------- | :--------- | :--------------------------------------------- |
| ubu26_0715           | id1000     | gdrive-chunked:id1000/ubu26_0715_review.tar    |
| Ubuntu-26.04         | id1001     | gdrive-chunked:id1001/ubuntu_2604_review.tar   |
| Ubuntu-24.04         | id1003     | gdrive-chunked:id1003/ubuntu_2404_review.tar   |


4. EXECUTION PROTOCOL (WINDOWS POWERSHELL)
----------------------------------------------------------------------
Prior to executing the streaming loop, all target virtual machines must 
be gracefully brought down to ensure filesystem transactions are locked 
and the underlying storage layers are fully consistent.

Step 1: Quiesce the WSL Execution Layer
Run this command from a host Windows PowerShell prompt:
    wsl --shutdown

Step 2: Stream Sequential Backups Directly to Cloud Vault
Execute these three streaming lines in sequence. The local storage 
drive will experience zero write operations during this process:

    wsl --export ubu26_0715 - | rclone rcat gdrive-chunked:id1000/ubu26_0715_review.tar --progress

    wsl --export Ubuntu-26.04 - | rclone rcat gdrive-chunked:id1001/ubuntu_2604_review.tar --progress

    wsl --export Ubuntu-24.04 - | rclone rcat gdrive-chunked:id1003/ubuntu_2404_review.tar --progress

Operational Note: On Google Drive, rclone will transparently handle 
the file segments, naming them sequentially (e.g., .001, .002) along 
with a lightweight .rcat metadata configuration map.


5. RESTORATION AND REASSEMBLY SEQUENCE
----------------------------------------------------------------------
If you ever need to rebuild a workspace from these segmented cloud 
assets onto a machine with open disk space, the chunker remote 
completely automates the reassembly process. You do not need to 
manually stitch the chunks together using split utilities.

To import an archive back into a fresh local WSL instance, run this 
direct inverse pipeline from PowerShell:

    rclone cat gdrive-chunked:id1000/ubu26_0715_review.tar | wsl --import ubu26_0715_restored C:\WSL\restored_instances\ -

======================================================================
