# NSX DFW Scripts

CLI toolkit for managing and backing up VMware NSX Distributed Firewall (DFW) configuration using the Policy and Manager APIs.

---

# 🚀 Overview

This repo provides scripts to:

- Export / import firewall policies
- Reorder policies (top / bottom)
- Delete policies
- Move rules between sections
- Perform **full DFW backups**
- Backup and restore **VM tags safely across environments**

---

# ⚡ Quick Start

## 1. Authenticate

```bash
source set-nsx-env.sh
```

Prompts for:
- NSX Manager
- Username
- Password

---

# 📦 Scripts

## 🔹 export-dfw-policy.sh
Export a policy (section) to JSON.

```bash
./export-dfw-policy.sh
```

---

## 🔹 import.sh
Import policy only (no ordering).

```bash
./import.sh policy.json
```

---

## 🔹 import-top.sh
Import and place at top of category.

```bash
./import-top.sh policy.json
```

---

## 🔹 import-bottom.sh
Import and place at bottom of category.

```bash
./import-bottom.sh policy.json
```

Recommended for most use cases.

---

## 🔹 delete-policy.sh
Delete a policy safely.

```bash
./delete-policy.sh policy-id
```

---

## 🔹 move-rule.sh
Move rule between sections (recreate + delete).

```bash
./move-rule.sh
```

---

# 📦 Full Backup

## 🔹 backup-all.sh

Creates a complete, restorable snapshot of:

- Policies
- Groups
- Services
- Context Profiles
- VM Tags (only real tags)

```bash
./backup-all.sh
```

---

## 📁 Output Structure

```
nsx-backup-YYYYMMDD-HHMMSS/
  policies/
  groups/
  services/
  context-profiles/
  vms/
  vm-tags-summary.json
```

---

## 🧠 Important Behavior

### Only real VM tags are backed up

- No generated or inferred tags
- VMs without tags are skipped

Example:

```json
{
  "name": "Books01-App02",
  "tags": [
    {"scope":"Environment","tag":"Dev"},
    {"scope":"vrniApplication","tag":"Books01"}
  ]
}
```

---

# 🔁 Restore VM Tags

## 🔹 restore-vm-tags.sh

Restores VM tags in a new environment.

```bash
./restore-vm-tags.sh vm-tags-summary.json
```

---

## 🧠 How it works

- Matches VMs by **name**
- Looks up **new external_id automatically**
- Uses Manager API inventory
- Applies tags using Policy API

---

## ✅ Safe Behavior

| Scenario | Result |
|--------|--------|
VM exists | tags merged |
VM missing | skipped |
Tags already exist | no duplicates |
Extra tags present | preserved |

---

## 🔥 Tag Handling

Tags are:

- **merged**, not overwritten
- deduplicated using:

```
scope + tag
```

So:

```json
existing + backup → merged safely
```

---

# ⚠️ Important Limitations

## VMs are NOT restored

NSX does not own VMs.

You must:
1. Restore VMs in vCenter
2. Then apply tags

---

## external_id is NOT portable

- Changes between environments
- Script avoids using it directly
- Uses VM name lookup instead

---

## Groups must not depend on external_id

Avoid:

```json
"external_ids": [...]
```

Prefer:
- tags
- IPs
- names

---

# 🧠 Category Migration

To move a policy between categories:

Edit JSON:

```json
"category": "Application"
```

Then re-import.

---

# 🧠 Ordering Rules

Use:

```
?action=revise
```

Operations:
- insert_top
- insert_bottom
- insert_before
- insert_after

Always include:

```
-d '{}'
```

---

# 🧰 Requirements

- bash
- curl
- jq

Install jq:

```bash
brew install jq
```

---

# 🧪 Example Workflow

## Backup

```bash
./backup-all.sh
```

## Restore tags after rebuild

```bash
./restore-vm-tags.sh nsx-backup-*/vm-tags-summary.json
```

---

# 🧠 Best Practices

- Store backups in Git
- Do not rely on external_id
- Use tag-based grouping
- Avoid modifying PATH in scripts
- Keep one policy per JSON file

---

# ✅ Summary

This toolkit provides:

- Full DFW backup
- Safe restore workflows
- Environment portability
- Automation-friendly operations

---

Enjoy your NSX firewall-as-code 🚀