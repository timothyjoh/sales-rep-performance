# Sales Rep Performance — Project Brief

## What
A rep-wise productivity scoring system that creates fair, bias-free performance scores for sales reps. Normalizes across experience levels so new and senior reps are comparable. Built in R.

## Tech Stack
- **R** — Core language
- **Shiny** — Interactive dashboard (manager tool with live weight adjustment)
- **Quarto** — Static executive reports (HTML/PDF, no server needed)
- **tidyverse** — Data wrangling
- **ggplot2** — Visualizations
- **testthat** — Unit testing

## Core Features

### 1. Activity Tracking
Track per-rep metrics:
- Calls made
- Follow-ups done
- Meetings scheduled
- Deals closed

### 2. Normalized Scoring
- Normalize scores so new & senior reps are fairly comparable
- Account for tenure, territory size, and opportunity volume
- Output: Productivity score (0–100)

### 3. Configurable Weights
Adjustable scoring dimensions:
- **Activity quality** — Are they doing the right things?
- **Conversion efficiency** — Are activities turning into results?
- **Revenue contribution** — What's the dollar impact?

### 4. Shiny Dashboard (Interactive)
- Rep rankings with score breakdowns
- Visual comparisons across dimensions
- Trend over time (improving/declining)
- **Live weight sliders** — adjust activity/conversion/revenue weights and see rankings update instantly
- Filter by rep, team, time period

### 5. Quarto Executive Report (Static)
- Polished HTML/PDF output for leadership
- Quarter/month summary with top performers and trends
- Score distribution charts and improvement highlights
- Shareable via email or GitHub Pages — no R server needed

### 6. Improvement Suggestions
- Identify specific gaps per rep
- Example: "Rep C has high activity but low conversion → needs skill coaching"
- Actionable recommendations based on score patterns

## Business Value
- Removes bias from performance reviews
- Data-driven coaching recommendations
- Fair comparison across experience levels
- Identifies high-effort/low-result reps who need skill development vs low-effort reps who need motivation

## Data Model
Sample rep data should include:
- `rep_id`, `rep_name`, `tenure_months`
- `calls_made`, `followups_done`, `meetings_scheduled`, `deals_closed`
- `revenue_generated`, `quota`, `territory_size`
- `period` (monthly/quarterly)

## Quality Bar
- Unit tests for all scoring functions (testthat)
- Reproducible sample dataset for demos
- Well-documented scoring methodology
- Clean, idiomatic R code

## Phase Approach
Build iteratively. Each phase should produce working, tested code.
1. Data model + sample data generation + project scaffolding
2. Scoring engine with normalization + configurable weights
3. Shiny dashboard with rankings, visualizations, and live weight sliders
4. Quarto executive report + improvement suggestions engine

Write "PROJECT COMPLETE" in REFLECTIONS.md when all features above are working.
