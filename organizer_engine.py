"""
Smart Desktop & Downloads Auto-Organizer & File Triage Engine
Scans Downloads and Desktop, classifies loose files by type/age, moves them to D:/Organized,
and maintains a complete reversible undo ledger.
"""

import os
import shutil
import json
import time
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional

JOURNAL_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "journal.json")
CONFIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")

class FileOrganizerEngine:
    def __init__(self, config_path: str = CONFIG_FILE, journal_path: str = JOURNAL_FILE):
        self.config_path = config_path
        self.journal_path = journal_path
        self.config = self._load_config()
        self.journal = self._load_journal()

    def _load_config(self) -> Dict[str, Any]:
        if os.path.exists(self.config_path):
            with open(self.config_path, "r", encoding="utf-8") as f:
                return json.load(f)
        return {}

    def _load_journal(self) -> List[Dict[str, Any]]:
        if os.path.exists(self.journal_path):
            try:
                with open(self.journal_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return []
        return []

    def _save_journal(self):
        try:
            with open(self.journal_path, "w", encoding="utf-8") as f:
                json.dump(self.journal, f, indent=2)
        except Exception as e:
            print(f"[ERROR] Failed to save journal: {e}")

    def _get_category(self, filename: str) -> Optional[str]:
        _, ext = os.path.splitext(filename.lower())
        rules = self.config.get("rules", {})
        for category, extensions in rules.items():
            if ext in extensions:
                return category
        return "Uncategorized_Files"

    def _get_unique_target(self, target_dir: str, filename: str) -> str:
        base_name, ext = os.path.splitext(filename)
        candidate = os.path.join(target_dir, filename)
        counter = 1
        while os.path.exists(candidate):
            candidate = os.path.join(target_dir, f"{base_name} ({counter}){ext}")
            counter += 1
        return candidate

    def scan_candidates(self) -> List[Dict[str, Any]]:
        """
        Scans source folders and identifies candidate files for organization.
        Respects exclusions, directory protections, and grace periods.
        """
        candidates = []
        now = time.time()
        grace_seconds = self.config.get("grace_period_minutes", 15) * 60
        target_root = self.config.get("target_root", "D:/Organized")
        ignore_exts = set(self.config.get("ignore_extensions", []))
        ignore_names = set(k.lower() for k in self.config.get("ignore_filenames", []))
        ignore_folders = set(k.lower() for k in self.config.get("ignore_folders", []))

        for source in self.config.get("source_directories", []):
            if not os.path.exists(source):
                continue

            try:
                items = os.listdir(source)
            except Exception:
                continue

            for item in items:
                item_lower = item.lower()
                if item_lower in ignore_names or item_lower in ignore_folders:
                    continue

                full_path = os.path.join(source, item)

                # Never move subdirectories from Desktop/Downloads root automatically
                if os.path.isdir(full_path):
                    continue

                _, ext = os.path.splitext(item_lower)
                if ext in ignore_exts:
                    continue

                try:
                    stat = os.stat(full_path)
                except Exception:
                    continue

                # Grace period: skip files modified or created in last N minutes
                file_age = now - stat.st_mtime
                if file_age < grace_seconds:
                    continue

                category = self._get_category(item)
                dest_dir = os.path.join(target_root, category.replace("/", os.sep))

                candidates.append({
                    "filename": item,
                    "source_path": full_path,
                    "source_dir": source,
                    "category": category,
                    "dest_dir": dest_dir,
                    "size_bytes": stat.st_size,
                    "mtime": stat.st_mtime,
                    "age_hours": round(file_age / 3600, 1)
                })

        return candidates

    def preview(self) -> Dict[str, Any]:
        """Dry-run preview of files that would be organized."""
        candidates = self.scan_candidates()
        total_size = sum(c["size_bytes"] for c in candidates)
        category_breakdown = {}

        for c in candidates:
            cat = c["category"]
            category_breakdown[cat] = category_breakdown.get(cat, 0) + 1

        return {
            "candidate_count": len(candidates),
            "total_bytes": total_size,
            "total_mb": round(total_size / (1024 * 1024), 2),
            "categories": category_breakdown,
            "items": candidates
        }

    def organize(self) -> Dict[str, Any]:
        """
        Executes organization: moves candidate files and appends to journal.
        """
        candidates = self.scan_candidates()
        if not candidates:
            return {"status": "NO_FILES", "moved_count": 0, "total_mb": 0.0, "run_id": None}

        run_id = str(uuid.uuid4())[:8]
        run_record = {
            "run_id": run_id,
            "timestamp": datetime.now().isoformat(),
            "status": "COMPLETED",
            "files": []
        }

        moved_count = 0
        moved_bytes = 0

        for c in candidates:
            src = c["source_path"]
            dest_dir = c["dest_dir"]
            os.makedirs(dest_dir, exist_ok=True)

            dest = self._get_unique_target(dest_dir, c["filename"])

            try:
                shutil.move(src, dest)
                moved_count += 1
                moved_bytes += c["size_bytes"]
                run_record["files"].append({
                    "original_path": src,
                    "destination_path": dest,
                    "filename": c["filename"],
                    "size_bytes": c["size_bytes"],
                    "category": c["category"]
                })
            except Exception as e:
                print(f"[ERROR] Failed to move {src} -> {dest}: {e}")

        if run_record["files"]:
            self.journal.append(run_record)
            self._save_journal()

        return {
            "status": "SUCCESS",
            "run_id": run_id,
            "moved_count": moved_count,
            "total_mb": round(moved_bytes / (1024 * 1024), 2),
            "files": run_record["files"]
        }

    def undo_last_run(self) -> Dict[str, Any]:
        """
        Rolls back the most recent organization run, moving files back to source.
        """
        if not self.journal:
            return {"status": "EMPTY_JOURNAL", "restored_count": 0}

        # Find the last completed run that hasn't been undone
        target_run = None
        for run in reversed(self.journal):
            if run.get("status") == "COMPLETED" and run.get("files"):
                target_run = run
                break

        if not target_run:
            return {"status": "NO_RUNS_TO_UNDO", "restored_count": 0}

        restored_count = 0
        restored_bytes = 0
        failed_count = 0

        for item in target_run["files"]:
            dest = item["destination_path"]
            orig = item["original_path"]

            if os.path.exists(dest):
                try:
                    orig_dir = os.path.dirname(orig)
                    os.makedirs(orig_dir, exist_ok=True)
                    shutil.move(dest, orig)
                    restored_count += 1
                    restored_bytes += item.get("size_bytes", 0)
                except Exception as e:
                    print(f"[ERROR] Failed rollback {dest} -> {orig}: {e}")
                    failed_count += 1
            else:
                failed_count += 1

        target_run["status"] = "UNDONE"
        target_run["undone_timestamp"] = datetime.now().isoformat()
        self._save_journal()

        return {
            "status": "SUCCESS",
            "run_id": target_run["run_id"],
            "restored_count": restored_count,
            "restored_mb": round(restored_bytes / (1024 * 1024), 2),
            "failed_count": failed_count
        }

if __name__ == "__main__":
    import sys
    engine = FileOrganizerEngine()
    
    cmd = sys.argv[1] if len(sys.argv) > 1 else "preview"
    if cmd == "preview":
        res = engine.preview()
        print(json.dumps(res, indent=2))
    elif cmd == "organize":
        res = engine.organize()
        print(json.dumps(res, indent=2))
    elif cmd == "undo":
        res = engine.undo_last_run()
        print(json.dumps(res, indent=2))
