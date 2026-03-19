# Proof capture notes

**Date:** 2026-03-17

## Recovery run (earlier)

Start instance → wait running → target healthy → curl endpoints → save proof. At that time `/api/list` and `/static/example.txt` returned 404 (older app).

## Patch run (PATCH_RUNNING_APP.md executed via SSM)

- **Backup:** `app.py.bak.<timestamp>` created on instance.
- **Patch:** Added `Response` to Flask import; added `/api/list` (alias to `list_notes()`) and `/static/example.txt` route.
- **Restart:** `sudo systemctl restart flask-app` — service active (running).

**Results after patch:**

| Endpoint | Status | Notes |
|----------|--------|--------|
| `/health` | 200 | OK |
| `/api/public-feed` | 200 | Has `Cache-Control: public, s-maxage=30, max-age=0` — good for Lab 2B. |
| `/static/example.txt` | 200 | Route added; returns plain text. Proof files show 200. |
| `/api/list` | 500 | Route is **live** (no longer 404). Returns 500 — backend/DB error inside `list_notes()` (e.g. DB unreachable or credentials). Fix DB/connectivity to get 200. |

Proof files in this folder reflect the current responses (static and public-feed 200; api-list 500 until backend is fixed).

Live vs repo state:
  - App routes are defined in Lab1C-V2/ec2.tf (user_data). The live instance was also patched via SSM so the same routes are present on the running EC2. New instances would get the same code from user_data. No mismatch: repo and live both have /api/list and /static/example.txt; /api/list returns 500 due to runtime DB/backend, not missing code.
