# README Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refresh the repository README into a hero-first bilingual format and add a Simplified Chinese companion README.

**Architecture:** Rewrite the top-level documentation only. Keep the output GitHub-friendly by using mostly Markdown with a light centered hero block, aligned English and Chinese section structure, and updated signing/package guidance that matches the existing build script.

**Tech Stack:** Markdown, GitHub-flavored Markdown, repository documentation files

---

### Task 1: Update ignore rules for visual companion artifacts

**Files:**
- Modify: `.gitignore`

**Step 1: Add `.superpowers/` to ignore rules**

Add a single ignore entry for the brainstorming browser artifacts.

**Step 2: Verify the rule is present**

Run: `sed -n '1,120p' .gitignore`
Expected: output includes `.superpowers/`

### Task 2: Rewrite the English README

**Files:**
- Modify: `README.md`

**Step 1: Replace the current README structure**

Add:
- centered hero block
- language and section links
- overview
- features
- quick start
- build/run/test
- packaging
- signing
- project layout

**Step 2: Keep signing behavior accurate**

Document:
- automatic `Developer ID Application` selection when available
- local self-signed fallback
- `SIGN_IDENTITY=-` override
- notarization still required for external distribution

**Step 3: Review anchor targets and command blocks**

Make sure links and commands are readable in GitHub Markdown.

### Task 3: Add the Simplified Chinese README

**Files:**
- Create: `README.zh-CN.md`

**Step 1: Mirror the English information architecture**

Use the same high-level sections while adapting language naturally for Chinese readers.

**Step 2: Add cross-links**

Include links back to `README.md` and section anchors within the Chinese file.

### Task 4: Verify documentation consistency

**Files:**
- Review: `README.md`
- Review: `README.zh-CN.md`
- Review: `scripts/build-dmg.sh`

**Step 1: Compare signing text against the packaging script**

Check that README claims match current script behavior.

**Step 2: Inspect file status**

Run: `git status --short`
Expected: only intended documentation and ignore-file edits appear.
