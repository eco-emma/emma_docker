# Agent instructions — emma_docker

This repository builds and documents the EMMA Docker / Apptainer container
(`adamwilsonlab/emma`). It is mostly shell, Dockerfile, and HPC launch scripts.
There is little or no application R source here today; still follow these rules
whenever you write or edit R (including snippets in docs, examples, or future
scripts).

## R code style (required)

Any R must follow the [tidyverse style guide](https://style.tidyverse.org).

- Prefer tidyverse idioms (`dplyr`, `tidyr`, `purrr`, `ggplot2`, `readr`, `tibble`)
  when they fit the task.
- Use the native pipe `|>` (not magrittr `%>%`).
- Use 2-space indentation; keep lines within ~80 characters where practical.
- Prefer `snake_case` for object and function names; reserve `CamelCase` for
  classes/S3 constructors as the style guide describes.
- Prefer named intermediate objects over deeply nested one-liners when it aids
  readability.
- Restyle existing R only when touching it; do not change behavior for style-only
  churn across unrelated files.

Authoritative detail for editors/agents that apply per-file rules:

- [`.github/instructions/r-style.instructions.md`](.github/instructions/r-style.instructions.md)
  (GitHub Copilot `applyTo` for `*.R` / `*.r`)
- [`.cursor/rules/r-tidyverse-style.mdc`](.cursor/rules/r-tidyverse-style.mdc)
  (Cursor project rule)

Project overview for Copilot:

- [`.github/copilot-instructions.md`](.github/copilot-instructions.md)

## Non-R work

Dockerfile, shell, Singularity/Apptainer, and CI changes should stay focused on
reproducible container builds and documented launch paths. Do not invent R
pipeline code in this repo unless the task explicitly requires it.
