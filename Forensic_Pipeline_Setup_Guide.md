# WORKSTATION DEPLOYMENT SETUP GUIDE: PARALLEL FORENSIC PIPELINE

## 1. HARDWARE STORAGE ARCHITECTURE SETUP
To prevent system crashes, read-write contentions, and catastrophic disk queue performance drops, map your system drives precisely to this matrix:

*   **Drive C:\ (OS & Software Application Engine Layer):** System operating drive running Windows 10/11 Enterprise, Cellebrite Inseyets Desktop environment, and Magnet Axiom suite.
*   **Drive D:\ (Cold Ingestion Repository):** Standard high-capacity array holding pristine, read-only mobile extraction source folders.
*   **Drive E:\ (Cellebrite Processing Pool):** High-speed NVMe PCIe Gen4/5 SSD dedicated exclusively to Cellebrite extraction temp builds and database generation.
*   **Drive F:\ (Magnet Axiom Processing Pool):** High-speed NVMe PCIe Gen4/5 SSD dedicated exclusively to Magnet Axiom data builds and artifact caches.

## 2. AIR-GAPPED ENVIRONMENT SOFTWARE PREPARATION
Ensure the following settings are established on your target isolated machine before execution:
1. Confirm that **Cellebrite Inseyets Physical Analyzer v10.x** is deployed and that `pas.exe` is located under: `C:\Program Files\Cellebrite\Forensic\Inseyets Physical Analyzer\pas.exe`
2. Confirm that **Magnet Axiom (Process / Cyber)** is deployed and that `AxiomProcess.exe` is located under: `C:\Program Files\Magnet Forensics\Magnet AXIOM\Magnet AXIOM Process\AxiomProcess.exe`
3. Connect all required physical USB licensing keys/dongles directly to the workstation ports. The script relies on persistent hardware validation tokens to authenticate automated background processes.

## 3. DEPLOYING AND RUNNING THE PIPELINE SCRIPT
1. Transfer the exported `ForensicPipeline_Offline.ps1` file onto your isolated machine via an approved hardware validation process.
2. Open an elevated PowerShell terminal window (Run as Administrator) and run this system command to temporarily allow script initialization:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope Process
   ```
3. Execute the script by right-clicking the file and selecting **Run with PowerShell** or running `.\ForensicPipeline_Offline.ps1` from the terminal.
4. Use the interface fields to designate the source drive path (`D:\...`) and the separate high-speed NVMe scratch directories (`E:\...` and `F:\...`). Click **Initialize Dual Pipeline**.
5. Track processing sequences seamlessly via the live window window or inspect `ForensicPipeline_RunLog.txt` directly within the designated extraction source directory for precise step logs.
