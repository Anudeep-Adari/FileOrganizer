<div align="center">

# 🗂️ FileOrganizer

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=26&duration=3000&pause=1000&color=2EA043&center=true&vCenter=true&width=620&lines=Rule-Based+File+Routing+%26+Classification;Dual-Engine+Architecture+(PowerShell+%2B+Python);Journaled+Reversible+File+Operations;Automated+Workspace+Hygiene+Utility" alt="Typing SVG" />
</p>

<p align="center">
  <strong>Automated Multi-Extension File Classification, Safe Relocation & Journaled Storage Organizer</strong>
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
flowchart LR
    subgraph Input ["📥 Source Directory"]
        Unsorted["Unsorted Downloads / Workspace Files"]
    end

    subgraph Engine ["⚙️ Execution Engine"]
        Matcher["Rule Matcher (config.json)"]
        Collision["Collision Handler & Collision Renamer"]
        Journal["Atomic Journal Ledger (journal.json)"]
    end

    subgraph Output ["📁 Target Vaults"]
        Docs["Documents / Archive"]
        Media["Images & Video Assets"]
        Archives["Compressed Archives"]
        Code["Source Code Projects"]
    end

    Input --> Matcher
    Matcher --> Collision
    Collision --> Journal
    Journal --> Output
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
