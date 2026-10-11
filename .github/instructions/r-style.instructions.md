---
applyTo: "**/*.{R,r}"
---

## R Code Style

Follow the [tidyverse style guide](https://style.tidyverse.org) for all R in
this repository (scripts, snippets, and examples).

### Tidyverse
- Use tidyverse idioms: `dplyr`, `tidyr`, `purrr`, `ggplot2`, `readr`, `tibble`
  when they fit the task.
- Use the native pipe `|>` (not `%>%`).
- Prefer `|> filter()`, `|> mutate()`, `|> summarise()` over base R subsetting
  or `apply` families unless there is a clear performance or clarity reason.
- Avoid explicit `for` loops unless no vectorised or `purrr::map*` equivalent
  exists (e.g. stateful side-effects or iteration that depends on prior results).

### Formatting
- 2-space indentation. Aim for a max line width of 80 characters.
- One expression per line; do not chain unrelated operations onto one line.
- Use `snake_case` for variables and functions; follow the style guide for
  spacing around `=`, commas, and parentheses.

### Structure
- Prefer named intermediate objects over deeply nested pipes when it aids
  debugging and readability.
- Keep parameters (paths, package lists, versions) as named objects near the
  top of a script when writing multi-step R.
- Do not change behavior when restyling; style-only edits must be behavior-preserving.

### Comments
- Comment intent and non-obvious constraints, not obvious mechanics.
- When R installs or configures geospatial tooling, note CRS, units, or version
  pins that matter for reproducibility.
