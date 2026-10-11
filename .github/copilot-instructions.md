# EMMA Docker — Copilot instructions

## Project overview

`emma_docker` builds the shared EMMA container image (`adamwilsonlab/emma`) used
by the EMMA R pipelines (envdata, model, report) on local machines and HPC
(Apptainer/Singularity). Typical contents: `Dockerfile`, launch scripts, and
HPC/Singularity helpers. Application analysis code lives in the other EMMA
repos, not here.

## R style (required)

Whenever you write or edit R—including future scripts, examples, or snippets in
docs—follow the [tidyverse style guide](https://style.tidyverse.org).

See also always-on file instructions:

- [`.github/instructions/r-style.instructions.md`](instructions/r-style.instructions.md)
  (applies to `*.R` / `*.r`)

Summary for agents:

- Native pipe `|>`, tidyverse idioms when appropriate
- 2-space indent, ~80-character lines, `snake_case` names
- Restyle without changing behavior

## When making changes

- Prefer minimal, documented Dockerfile and shell changes that keep the image
  buildable on GitHub Actions and usable on CCR/Apptainer.
- Do not add analysis pipelines or large R packages here unless the task
  explicitly calls for a container-level dependency.
- Keep secrets and host-specific paths out of committed scripts; follow existing
  env-var patterns in the README and launch scripts.
