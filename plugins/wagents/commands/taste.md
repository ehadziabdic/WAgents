---
description: "Calibrate frontend design taste dials (DESIGN_VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY) for the frontend-designer agent."
argument-hint: "[e.g. variance=7 motion=4 density=8]"
---

# Taste Command (`/wagents:taste`)

Configure aesthetic dials and design posture for `frontend-designer` based on the project's brand and functional needs.

## Tunable Dials

| Parameter | Default | Range | Purpose |
| :--- | :---: | :---: | :--- |
| **`DESIGN_VARIANCE`** | 7 | 1–10 | 1 = rigid symmetrical corporate grid; 10 = avant-garde editorial asymmetry |
| **`MOTION_INTENSITY`** | 5 | 1–10 | 1 = static / instantaneous; 10 = fluid cinematic choreography |
| **`VISUAL_DENSITY`** | 6 | 1–10 | 1 = airy luxury landing page; 10 = Bloomberg console / data-dense IDE |

## Presets

- **Modern SaaS Dashboard**: `variance=5 motion=4 density=7`
- **Consumer Landing Page**: `variance=8 motion=6 density=3`
- **Developer CLI / Console**: `variance=3 motion=2 density=9`
- **Editorial / Magazine**: `variance=9 motion=5 density=5`

