# syntax=docker/dockerfile:1
FROM rocker/geospatial
LABEL maintainer="Adam M. Wilson <adamw@buffalo.edu>"

# Display port (Xvfb / headless plotting)
ENV DISPLAY=:99

# ── Package pin (source of truth for R library versions) ─────────────────────
# Date-stamped Posit Package Manager snapshot. Do NOT use renv in this image;
# consumers (laptop / GHA / Singularity) use the baked site-library as-is.
# Prefer Ubuntu binary URLs (set after apt when VERSION_CODENAME is known).
ENV R_CRAN_DATE=2026-10-01
ENV R_UNIVERSE_STAN=https://stan-dev.r-universe.dev
ENV R_UNIVERSE_ROPENSCI=https://ropensci.r-universe.dev

## System libraries required by geospatial / EMMA R packages
# cmake: required to build RcppParallel (qs2 dependency) from source
# libtbb-dev: optional accel for RcppParallel / CmdStan tooling
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    cmake \
    libtbb-dev \
    libv8-dev \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libglpk-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    libsecret-1-0 \
    libsecret-1-dev \
    gh \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Pin CRAN to P3M Linux binaries for this Ubuntu codename.
# Quoted heredoc: Docker must not touch $… (plain RUN + $$ was passed through as
# shell PID, producing broken URLs like 1{CRAN_BIN}).
RUN <<'EOF'
set -eux
. /etc/os-release
mkdir -p /etc/R
CRAN_BIN="https://packagemanager.posit.co/cran/__linux__/${VERSION_CODENAME}/${R_CRAN_DATE}"
echo "${CRAN_BIN}" > /etc/R/cran-url
printf '%s\n' \
  "options(repos = c(" \
  "  stan = Sys.getenv('R_UNIVERSE_STAN', 'https://stan-dev.r-universe.dev')," \
  "  ropensci = Sys.getenv('R_UNIVERSE_ROPENSCI', 'https://ropensci.r-universe.dev')," \
  "  CRAN = '${CRAN_BIN}'" \
  "))" \
  > /usr/local/lib/R/etc/Rprofile.site
echo "CRAN pin: ${CRAN_BIN}"
EOF

# PROJ database path — required under Docker and Apptainer/Singularity
ENV PROJ_LIB=/usr/share/proj

## Quarto
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then QUARTO_ARCH="amd64"; \
    elif [ "$ARCH" = "arm64" ]; then QUARTO_ARCH="arm64"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    wget -q https://quarto.org/download/latest/quarto-linux-${QUARTO_ARCH}.deb && \
    dpkg -i quarto-linux-${QUARTO_ARCH}.deb && \
    rm -f quarto-linux-${QUARTO_ARCH}.deb

## git-lfs
RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get install -y --no-install-recommends git-lfs && \
    git lfs install && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

## Miniforge Python (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then CONDA_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then CONDA_ARCH="aarch64"; \
    else echo "Unsupported arch: $ARCH" && exit 1; fi && \
    wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${CONDA_ARCH}.sh -O miniforge.sh && \
    bash miniforge.sh -b -p /opt/conda && \
    rm miniforge.sh
ENV PATH="/opt/conda/bin:${PATH}"

# ── R packages from pinned P3M snapshot (image = source of truth) ────────────
# Explicit list only — no renv::restore(), no update.packages().
# Install qs2 deps (RcppParallel, stringfish) first so a failed parallel dep
# cannot leave qs2 half-resolved under install2.r --error.
RUN <<'EOF'
set -eux
CRAN_URL="$(cat /etc/R/cran-url)"
install2.r --error -r "${CRAN_URL}" \
  RcppParallel \
  stringfish
install2.r --error -r "${CRAN_URL}" \
  testthat \
  remotes \
  globals \
  fs \
  writexl \
  rio \
  tidyverse \
  listenv \
  RCurl \
  questionr \
  stringr \
  knitr \
  cptcity \
  geojsonio \
  targets \
  tarchetypes \
  visNetwork \
  googleCloudStorageR \
  janitor \
  qpdf \
  RefManageR \
  svMisc \
  jose \
  cubelyr \
  rdryad \
  doParallel \
  piggyback \
  arrow \
  bibtex \
  proto \
  slam \
  ape \
  fasterize \
  exactextractr \
  RcppEigen \
  jpeg \
  interp \
  latticeExtra \
  hexbin \
  prioritizr \
  dygraphs \
  ggridges \
  GSODR \
  gt \
  leafem \
  leaflet \
  lubridate \
  mapview \
  plotly \
  quarto \
  raster \
  rinat \
  rmarkdown \
  sf \
  SPEI \
  stars \
  terra \
  tidyterra \
  xts \
  reticulate \
  cowplot \
  appeears \
  keyring \
  filelock \
  ncdf4 \
  colourvalues \
  kableExtra \
  future \
  viridis \
  qs2 \
  smoothr \
  crew \
  webshot2 \
  memoise \
  htmlwidgets \
  patchwork \
  languageserver \
  parallelly \
  gdalUtilities \
  webshot
EOF

# r-universe / non-CRAN packages (still versioned by their published builds)
RUN <<'EOF'
set -eux
CRAN_URL="$(cat /etc/R/cran-url)"
R -e "options(repos = c( \
          stan = Sys.getenv('R_UNIVERSE_STAN'), \
          ropensci = Sys.getenv('R_UNIVERSE_ROPENSCI'), \
          CRAN = '${CRAN_URL}' \
        )); \
        install.packages(c('cmdstanr', 'posterior', 'bayesplot', 'geotargets', 'stantargets')); \
        install.packages( \
          'https://gitlab.rrz.uni-hamburg.de/helgejentsch/climdatdownloadr/-/archive/master/climdatdownloadr-master.tar.gz', \
          repos = NULL, type = 'source' \
        ); \
        if (requireNamespace('webshot', quietly = TRUE)) webshot::install_phantomjs()"
EOF

# CmdStan under /opt (not $HOME) so Apptainer home binds do not hide it
RUN mkdir -p /opt/cmdstan \
 && R -e "cmdstanr::install_cmdstan(dir = '/opt/cmdstan')" \
 && chmod -R a+rX /opt/cmdstan \
 && ln -sfn "$(find /opt/cmdstan -maxdepth 1 -type d -name 'cmdstan-*' | sort | tail -n 1)" /opt/cmdstan/current
ENV CMDSTAN=/opt/cmdstan/current
ENV CMDSTAN_PATH=/opt/cmdstan/current

# Quarto headless Chrome under /opt (readable by non-root Singularity users)
RUN quarto install chrome-headless-shell \
 && mkdir -p /opt \
 && cp -a /root/.local/share/quarto/chrome-headless-shell /opt/chrome-headless-shell \
 && chmod -R a+rX /opt/chrome-headless-shell
ENV CHROMOTE_CHROME=/opt/chrome-headless-shell/chrome-linux/headless_shell

# Writable scratch defaults that survive typical Apptainer binds of $HOME
ENV HOME=/home/rstudio
WORKDIR /home/rstudio
RUN mkdir -p /home/rstudio /tmp /var/tmp \
 && chmod 1777 /tmp /var/tmp
