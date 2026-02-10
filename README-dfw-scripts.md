# NSX DFW CLI Toolkit

Simple, repeatable bash scripts for managing Distributed Firewall (DFW) **sections (policies)** and **rules** using the VMware NSX Policy API.

These tools replace most UI actions with deterministic CLI commands.

---

# 🚀 Typical Workflow (Start Here)

Most common tasks follow this order.

---

## 1) Login (once per shell)

```bash
source set-nsx-env.sh
```

Prompts for:
- NSX Manager
- Username
- Password

Exports:

```
NSX_MGR
NSX_USER
NSX_PASS
```

All scripts reuse these automatically.

---

## 2) Export a Section

```bash
./export-dfw-policy.sh
```

Exports an existing section to JSON so you can:
- edit rules
- clone
- migrate
- change category
- modify behavior safely offline

---

## ⭐ Change Category (Move Between Sections)

To move a policy between categories (for example **Emergency → Application → Infrastructure → Environment**):

### Simply edit the exported JSON

Find:

```json
"category": "Emergency"
```

Change to:

```json
"category": "Application"
```

or

```json
"category": "Infrastructure"
```

or

```json
"category": "Environment"
```

Then re-import.

### Example workflow

```bash
./export-dfw-policy.sh
# edit JSON → change "category"
./import-bottom.sh mypolicy.json
./delete-policy.sh old-policy-id
```

This is the **official and safest way** to move policies between categories in NSX.

NSX does NOT support cross-category moves via API.

You must:
1. export
2. change category
3. import new
4. delete old

---

## 3) Import to TOP of category

```bash
./import-top.sh mypolicy.json
```

Result:

```
Application
  NEW SECTION   ← here
  existing
  existing
-------------------
Default Layer 3
```

---

## 4) Import to BOTTOM of category (recommended)

```bash
./import-bottom.sh mypolicy.json
```

Result:

```
Application
  existing
  existing
  NEW SECTION   ← here
-------------------
Default Layer 3
```

Safest placement option.

---

## 5) Delete a Section

```bash
./delete-policy.sh section-id
```

or

```bash
./delete-policy.sh /infra/domains/default/security-policies/section-id
```

Requires confirmation before deleting.

---

## 6) Move a Rule Between Sections

```bash
./move-rule.sh
```

Prompts for:
- rule path
- target section

Internally performs:

```
export → sanitize → recreate → delete original
```

Because NSX cannot directly move rules.

---

---

# 📦 Script Reference

---

## export-dfw-policy.sh

Export a section to JSON.

```bash
./export-dfw-policy.sh
```

Prompts for:
- policy path
- output filename

---

## import.sh

Import only (no reordering).

```bash
./import.sh mypolicy.json
```

Behavior:
- preserves display name
- ID = filename + date
- strips system metadata

---

## import-top.sh

Place section at top of its category.

Uses:

```
?action=revise&operation=insert_top
```

---

## import-bottom.sh

Place section at bottom of its category.

Uses:

```
?action=revise&operation=insert_bottom
```

Most reliable option.

---

## delete-policy.sh

Delete a section safely.

```bash
./delete-policy.sh section-id
```

Requires typing:

```
DELETE
```

---

## move-rule.sh

Move rule between sections.

```bash
./move-rule.sh
```

Because NSX:
- does not support rule move
- rules must be recreated

---

---

# 🧠 Important NSX Behaviors

These explain most "why did this fail?" situations.

---

## Policy ordering

You CANNOT:
- anchor to default-layer3-section
- move across categories directly

You MUST use:

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
-H "Content-Type: application/json" -d '{}'
```

Or NSX returns:

```
BAD_REQUEST: Required request body is missing
```

---

## Rule moves

Rules are not movable objects.

They only exist inside their parent section.

To move:

```
PUT new → DELETE old
```

Scripts automate this.

---

## Metadata must be removed before PUT

Exported JSON contains:

```
_revision
_path
_create_time
_last_modified_time
_system_owned
sequence_number
rule_id
```

These break PUT requests.

Scripts automatically strip them.

---

## ID strategy

Sections use:

```
filename + YYYYMMDD
```

Example:

```
detect-unencrypted-20260210
```

Benefits:
- unique
- safe
- repeatable
- avoids overwriting

Display name stays the same.

---

---

# 🛠 Setup (Requirements)

Install jq:

macOS:
```bash
brew install jq
```

Linux:
```bash
sudo apt install jq
# or
sudo yum install jq
```

Requires:
- curl
- bash
- jq

---

# ✅ Summary

These scripts provide:

- export
- import
- reorder
- category migration
- delete
- move rules

All safely, repeatably, and without the NSX UI.

Ideal for:
- lab → prod migrations
- bulk edits
- automation
- scripting

---

Enjoy your NSX DFW CLI superpowers 🚀
