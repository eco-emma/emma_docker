FROM rocker/geospatial
MAINTAINER "Adam M. Wilson" adamw@buffalo.edu

# set display port to avoid crash
ENV DISPLAY=:99

## System libraries required by geospatial / EMMA R packages
RUN apt-get update \
  && apt-get install -y \
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

# Ensure PROJ can find its database in containerised/Apptainer runs
ENV PROJ_LIB=/usr/share/proj

## Install Quarto library
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        QUARTO_ARCH="amd64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        QUARTO_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget https://quarto.org/download/latest/quarto-linux-${QUARTO_ARCH}.deb && \
    dpkg -i quarto-linux-${QUARTO_ARCH}.deb

# Install git-lfs #from https://github.com/git-lfs/git-lfs/blob/main/INSTALLING.md
RUN apt-get update && \
	apt-get install -y gnupg && \
	curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash && \
	apt-get install -f git-lfs && \
	git lfs install

# Install Python
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        CONDA_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        CONDA_ARCH="aarch64"; \
    else \
        echo "Unsupported arch: $ARCH" && exit 1; \
    fi && \
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${CONDA_ARCH}.sh -O miniforge.sh && \
    bash miniforge.sh -b -p /opt/conda && \
    rm miniforge.sh

# ── R packages via renv (canonical lockfile for emma image + sibling repos) ──
# DESCRIPTION + renv.lock are the source of truth; do not use update.packages
# or an unpinned install2.r package list for the image library.
WORKDIR /opt/emma
COPY DESCRIPTION renv.lock .Rprofile ./
COPY renv ./renv
COPY pak.lock ./pak.lock

ENV RENV_CONFIG_REPOS_OVERRIDE=
ENV RENV_PATHS_CACHE=/opt/renv-cache
ENV RENV_PATHS_LIBRARY=/usr/local/lib/R/site-library

RUN mkdir -p /opt/renv-cache \
 && R -e "install.packages('renv', repos = 'https://cloud.r-project.org'); \
          renv::consent(provided = TRUE); \
          options(repos = c( \
            stan = 'https://stan-dev.r-universe.dev', \
            ropensci = 'https://ropensci.r-universe.dev', \
            RSPM = 'https://packagemanager.posit.co/cran/2026-10-01', \
            CRAN = 'https://packagemanager.posit.co/cran/2026-10-01' \
          )); \
          renv::restore(project = '/opt/emma', prompt = FALSE, clean = FALSE)"

# Install Quarto's bundled chrome-headless-shell (a real Chromium binary, works
# in Docker unlike the Ubuntu 'chromium' snap stub).
# Must run AFTER quarto is installed so the 'quarto' CLI is available.
RUN quarto install chrome-headless-shell
# Point chromote (used by webshot2) at Quarto's headless shell.
ENV CHROMOTE_CHROME=/root/.local/share/quarto/chrome-headless-shell/chrome-linux/headless_shell

## Packages / tools not represented cleanly in CRAN lockfiles
RUN R -e "if (!requireNamespace('remotes', quietly=TRUE)) install.packages('remotes', repos='https://packagemanager.posit.co/cran/2026-10-01'); \
          remotes::install_github('futureverse/parallelly', ref='master', upgrade='never'); \
          dir.create('/home/rstudio/.cmdstanr', recursive=TRUE); \
          if (requireNamespace('cmdstanr', quietly=TRUE)) cmdstanr::install_cmdstan(dir='/home/rstudio/.cmdstanr'); \
          remotes::install_github('ropensci/stantargets', upgrade='never'); \
          install.packages('https://gitlab.rrz.uni-hamburg.de/helgejentsch/climdatdownloadr/-/archive/master/climdatdownloadr-master.tar.gz', repos = NULL, type = 'source'); \
          if (requireNamespace('webshot', quietly=TRUE)) webshot::install_phantomjs(); \
          remotes::install_github('JoshOBrien/gdalUtilities', upgrade='never')"

WORKDIR /home/rstudio
