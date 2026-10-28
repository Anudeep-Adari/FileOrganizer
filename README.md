<div align="center">

# 🗂️ FileOrganizer

### Multi-Extension File Classification, Safe Relocation & Storage Organizer
**PowerShell 7+ • Python 3.10+ • Atomic Transaction Journal • Reversible Operations**

<p align="center">
  <em>Rule-based storage classifier featuring conflict resolution, atomic file moving, and comprehensive audit logs.</em>
</p>

<!-- Badges -->
<p align="center">
  <a href="https://learn.microsoft.com/en-us/powershell/"><img src="https://img.shields.io/badge/PowerShell-7%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell" /></a>
  <a href="https://www.python.org/downloads/"><img src="https://img.shields.io/badge/Python-3.10%2B-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python 3.10+" /></a>
  <a href="https://coderabbit.ai"><img src="https://img.shields.io/badge/CodeRabbit-AI_Reviewed-FF5C00?style=for-the-badge&logo=coderabbit&logoColor=white" alt="CodeRabbit" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Operations-Journaled_%26_Atomic-10B981?style=flat-square" />
  <img src="https://img.shields.io/badge/Config-JSON_Rule_Driven-blueviolet?style=flat-square" />
  <img src="https://img.shields.io/badge/Platform-Windows-0078D4?style=flat-square" />
</p>

---

</div>

## 📌 Architecture & Execution Flow

```mermaid
flowchart TB
    %% Styling & Spacing
    classDef client fill:#161b22,stroke:#58a6ff,stroke-width:2px,color:#ffffff;
    classDef zone fill:#0d1117,stroke:#30363d,stroke-width:1.5px,color:#c9d1d9;
    classDef security fill:#161b22,stroke:#f85149,stroke-width:2px,color:#ffffff;
    classDef data fill:#161b22,stroke:#3fb950,stroke-width:2px,color:#ffffff;

    subgraph InputTier [" 📥 SOURCE DIRECTORY & STAGING INGESTION "]
        direction LR
        RawDownloads["Unsorted Downloads<br/><sub>Transient Web Files & Installers</sub>"]:::client
        DesktopDump["Desktop Clutter<br/><sub>Ad-hoc Working Documents & Scripts</sub>"]:::client
    end

    subgraph Region1 [" ⚙️ REGION 1: TAXONOMY & RULE MATRIX "]
        direction TB
        ConfigMap["Rule Engine (config.json)<br/>• Extension Taxonomy Mapping (.pdf, .zip, .exe)<br/>• Pattern Matching & Prefix Filter"]:::client
        MetaParser["Metadata & Date Sorter<br/>• Creation / Modification Timestamping<br/>• Monthly Sub-Vault Routing"]:::client
    end

    subgraph Region2 [" 🛡️ REGION 2: COLLISION & INTEGRITY ENGINE "]
        direction TB
        CollisionGuard["Collision Resolver<br/>• Incremental Suffixing (_v1, _v2)<br/>• Zero Overwrite Protection"]:::security
        DryRunInspector["Dry-Run Inspector<br/>• Preview Matrix Generation<br/>• Pre-Execution Path Validation"]:::security
    end

    subgraph CentralTransit [" 🔄 CENTRAL TRANSIT: ATOMIC TRANSACTION GATEWAY "]
        direction TB
        MoveExecutor["Atomic Move Executor<br/><sub>Transactional Filesystem Operation</sub>"]:::security
        JournalStore[("Reversible Transaction Store<br/>journal.json Audit Trail")]:::data
    end

    subgraph StorageVaults [" 📁 ORGANIZED STORAGE VAULTS PLANE "]
        direction LR
        Docs["📁 Documents & Manuals"]:::data
        Media["📁 Images & Media Assets"]:::data
        Archives["📁 Compressed Archives"]:::data
        Code["📁 Source Code Projects"]:::data
    end

    %% Spacious Architectural Connections
    RawDownloads ---------> ConfigMap
    DesktopDump ----------> ConfigMap

    ConfigMap ------------> MetaParser
    MetaParser -----------> CollisionGuard
    CollisionGuard -------> DryRunInspector

    DryRunInspector ------> MoveExecutor
    MoveExecutor -.-.-.-.->|Record Previous & New Paths| JournalStore

    MoveExecutor ---------> Docs
    MoveExecutor ---------> Media
    MoveExecutor ---------> Archives
    MoveExecutor ---------> Code
```

---

## ⚡ Key Capabilities

* **Dual Engine Flexibility:** Run via Python (`organizer_engine.py`) or natively in PowerShell (`Invoke-FileOrganizer.ps1`).
* **Conflict Resolution:** Safely renames duplicate file names with clean revision increments rather than overwriting existing data.
* **Transaction Journaling:** Records each operation to `journal.json` for full rollback capability.

---

## 🚀 Quickstart

```powershell
# Clone the repository
git clone https://github.com/Anudeep-Adari/FileOrganizer.git
cd FileOrganizer

# Run natively in PowerShell
.\Invoke-FileOrganizer.ps1 -DryRun   # Preview changes without moving
.\Invoke-FileOrganizer.ps1          # Execute file organization
```

---

<div align="center">

Crafted with high engineering precision by **[Anudeep Adari](https://github.com/Anudeep-Adari)**  
Continuous AI Code Reviews powered by **CodeRabbit**

</div>

