FROM rocker/geospatial
MAINTAINER "Adam M. Wilson" adamw@buffalo.edu

# set display port to avoid crash
ENV DISPLAY=:99

## RUN apt-get remove $(tasksel --task-packages desktop) # from https://unix.stackexchange.com/questions/56316/can-i-remove-gui-from-debian
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

RUN install2.r --error \
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
    posterior \
    bayesplot \
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
    geojsonio \
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
    arrow \
    tidyverse \
    dygraphs \
    ggridges \
    GSODR \
    gt \
    leafem \
    leaflet \
    lubridate \
    mapview \
    piggyback \
    plotly \
    quarto \
    raster \
    rinat \
    rmarkdown \
    sf \
    SPEI \
    stars \
    tarchetypes \
    targets \
    geotargets \
	terra \
    tidyterra \
    xts \
    reticulate \
    cowplot \
	appeears \
	rdryad \
	keyring \
	filelock \
	ncdf4 \
	stars \
	colourvalues \
	kableExtra \
	future \
	viridis \
	colourvalues \
	qs2 \
	smoothr \
	crew \
	webshot2 \
	memoise \
  	htmlwidgets \
  	patchwork \
	languageserver

	
## install additional libraries from custom repos including cmdstanr - note the path below is important for loading library in container
RUN R -e "remotes::install_github('futureverse/parallelly', ref='master'); \
          install.packages('cmdstanr', repos = c('https://stan-dev.r-universe.dev', getOption('repos'))) ; \
          dir.create('/home/rstudio/.cmdstanr', recursive=T); cmdstanr::install_cmdstan(dir='/home/rstudio/.cmdstanr'); \
          remotes::install_github('ropensci/stantargets'); \
          install.packages('geotargets', repos = c('https://ropensci.r-universe.dev', 'https://cran.r-project.org')); \
          install.packages('https://gitlab.rrz.uni-hamburg.de/helgejentsch/climdatdownloadr/-/archive/master/climdatdownloadr-master.tar.gz', repos = NULL, type = 'source'); \
          install.packages('webshot'); \
          webshot::install_phantomjs(); \
          devtools::install_github('JoshOBrien/gdalUtilities')"
