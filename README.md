# EMMA Docker Container

One image — `adamwilsonlab/emma` — is the **source of truth** for the R package
library used everywhere EMMA runs:

| Where | How |
|---|---|
| Laptop | `docker run … adamwilsonlab/emma:latest` |
| GitHub Actions | `container: adamwilsonlab/emma:latest` |
| HPC (CCR) | Apptainer/Singularity pull of the same DockerHub tag → `.sif` |

Packages are pinned in the **Dockerfile** via a Posit Package Manager (P3M)
date snapshot (`R_CRAN_SNAPSHOT`) plus explicit `install.packages` for
r-universe / GitLab extras. There is **no `renv` in the image** and no
host-side `renv::restore()` for pipelines — always run inside this image.

To change package versions: edit the Dockerfile pin / package list, rebuild,
push `adamwilsonlab/emma:latest` (master builder workflow).

---

## Laptop (Docker)

RStudio Server:

```bash
docker run --rm -p 8787:8787 -e PASSWORD=yourpasswordhere adamwilsonlab/emma:latest
```

Visit `http://localhost:8787` (user `rstudio`). Password is required unless:

```bash
docker run --rm \
  -p 127.0.0.1:8787:8787 \
  -e DISABLE_AUTH=true \
  -v "$PWD":/home/rstudio/project \
  adamwilsonlab/emma:latest
```

One-shot targets / Rscript (mount the project):

```bash
docker run --rm \
  -v "$PWD":/work -w /work \
  -e GITHUB_PAT \
  adamwilsonlab/emma:latest \
  Rscript -e 'targets::tar_make()'
```

---

## GitHub Actions

Use the published image as the job container (emma_report already does this):

```yaml
jobs:
  targets:
    runs-on: ubuntu-latest
    container: adamwilsonlab/emma:latest
    env:
      GITHUB_PAT: ${{ secrets.GH_PAT_BSM }}
    steps:
      - uses: actions/checkout@v4
      - run: Rscript -e 'targets::tar_make()'
```

Do **not** call `update.packages()` or `renv::restore()` in CI — the image
already has the library.

---

## HPC / Singularity (Apptainer)

Must be on campus or the [UB VPN](https://www.buffalo.edu/ubit/service-guides/connecting/vpn/computer.html).

### One-time: pull DockerHub → `.sif`

```bash
export GROUP="adamw"
export PROJECT_FOLDER="/projects/academic/${GROUP}"
export APPTAINER_CACHEDIR="${PROJECT_FOLDER}/users/${USER}/apptainer"
export APPTAINER_TMPDIR="${APPTAINER_CACHEDIR}/tmp"
export SINGULARITY_CACHEDIR="${APPTAINER_CACHEDIR}"
export SINGULARITY_TMPDIR="${APPTAINER_TMPDIR}"
mkdir -p "${APPTAINER_CACHEDIR}/tmp" "${APPTAINER_CACHEDIR}/run"

cd "${APPTAINER_CACHEDIR}"
apptainer pull --force AdamWilsonLab-emma_docker-latest.sif \
  docker://adamwilsonlab/emma:latest
```

Or use `build_apptainer.slurm` on a compute node.

### Run R / targets

```bash
export SIF="${APPTAINER_CACHEDIR}/AdamWilsonLab-emma_docker-latest.sif"
export PROJECT_FOLDER="/projects/academic/adamw"

# Bind project + writable tmp/run (image keeps CmdStan/Chrome under /opt)
apptainer exec \
  --bind "${PROJECT_FOLDER}:${PROJECT_FOLDER}" \
  --bind "${APPTAINER_CACHEDIR}/tmp:/tmp" \
  --bind "${APPTAINER_CACHEDIR}/run:/run" \
  "${SIF}" \
  Rscript -e 'targets::tar_make()'
```

Interactive R:

```bash
apptainer run \
  --bind "${PROJECT_FOLDER}:${PROJECT_FOLDER}" \
  --bind "${APPTAINER_CACHEDIR}/tmp:/tmp" \
  --bind "${APPTAINER_CACHEDIR}/run:/run" \
  "${SIF}" R
```

### Singularity-safe paths baked into the image

| Path | Purpose |
|---|---|
| `/usr/local/lib/R/site-library` | Pinned R packages |
| `/opt/cmdstan/current` | CmdStan (`CMDSTAN` / `CMDSTAN_PATH`) |
| `/opt/chrome-headless-shell/.../headless_shell` | `CHROMOTE_CHROME` for webshot2 |
| `/usr/share/proj` | `PROJ_LIB` |

Avoid writing into image layers; bind a project directory and `/tmp`.

---

## Local VSCode on CCR

1. Extensions: R, R Syntax, Quarto (optional)
2. Mount CCR (SSHFS / Mountain Duck); project under `/projects/academic/adamw/users/$USER`
3. `r.alwaysUseActiveTerminal: true`
4. SSH → `salloc` → `apptainer run … R` as above

## CCR OnDemand

[CCR OnDemand](https://ondemand.ccr.buffalo.edu/pun/sys/dashboard/)
