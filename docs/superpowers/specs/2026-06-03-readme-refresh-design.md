# README Refresh Design

Date: 2026-06-03
Project: AppIconExporter
Status: Draft approved in conversation, awaiting file review before implementation

## Goal

Refresh the repository README presentation to match the general structure of the provided reference:

- centered hero section
- stronger product identity
- bilingual entry points near the top
- clearer documentation flow below the hero

Also add a Simplified Chinese companion document at `README.zh-CN.md`.

## Constraints

- Preserve GitHub README practicality; do not turn the document into a landing page that hides setup and packaging details.
- Keep the implementation maintainable in plain Markdown, with only light HTML where GitHub rendering benefits from it.
- Do not copy the reference project's branding, logo language, or exact copy.
- Keep English and Chinese READMEs structurally aligned.
- Do not commit as part of this step unless explicitly requested by the user.

## Approved Direction

The approved direction is:

- visual direction `A`: hero-first README
- similarity level `2`: keep the reference layout skeleton, but adapt the visual tone to AppIconExporter
- English hero title: `App Icon Exporter`
- top link row style: documentation anchors and language switch links

## README.md Structure

`README.md` will be rewritten with this order:

1. Centered hero section
2. Top navigation row:
   - `English`
   - `简体中文`
   - `Features`
   - `Quick Start`
   - `Signing`
3. Overview
4. Features
5. Quick Start
6. Build / Run / Test
7. Package
8. Developer ID Signing
9. Project Layout

## README Hero Design

The hero should include:

- centered product name: `App Icon Exporter`
- one short subtitle explaining the utility in plain English
- optional centered app icon image from repository assets if it improves recognition
- a compact anchor row below the subtitle

The hero should feel more product-oriented than the current README, but still restrained and tool-like.

## English Content Strategy

The English README should:

- describe the app in one sentence near the top
- highlight the core workflows: single export, batch export, preview, output directory, duplicate handling, recursive scan
- keep command sections easy to copy
- keep packaging/signing guidance explicit:
  - automatic use of local `Developer ID Application` identity when available
  - fallback to project-local test signing when no Apple identity exists
  - explicit `SIGN_IDENTITY=-` ad-hoc override
  - note that notarization is still needed for full external distribution

## Chinese README Strategy

`README.zh-CN.md` should mirror the English structure, but be written naturally for Chinese readers instead of doing line-by-line translation.

It should include:

- Chinese title and subtitle
- a top link row back to the English README and Chinese sections
- equivalent command and signing guidance
- terminology adapted for Chinese readers:
  - `Developer ID` preserved where needed
  - packaging, signing, and notarization terminology explained in plain Chinese

## File Changes

Implementation is expected to modify or create:

- `README.md`
- `README.zh-CN.md`

No code changes are required.

## Error Handling / Risks

- GitHub Markdown rendering can differ from local preview, so formatting should avoid fragile HTML layouts.
- Too much decorative formatting would reduce maintainability; the implementation should stay mostly Markdown-based.
- The current signing behavior in the README must match the actual packaging script.

## Verification

After implementation:

- inspect both README files in plain text for structure and anchor correctness
- verify intra-document anchor links are reasonable for GitHub
- confirm bilingual cross-links are correct
- ensure signing documentation still matches `scripts/build-dmg.sh`

