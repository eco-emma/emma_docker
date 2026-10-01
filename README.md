# EMMA Docker Container



# Instructions


## Quickstart
```
docker run --rm -p 8787:8787 -e PASSWORD=yourpasswordhere adamwilsonlab/emma:latest
```

Visit `localhost:8787` in your browser and log in with username rstudio and the password you set. NB: Setting a password is now REQUIRED. Container will error otherwise.


## Local machine (no password)

If you are running on a local machine with other security mechanisms, you can use the following:

```
docker run --rm \
  -p 127.0.0.1:8787:8787 \
  -e DISABLE_AUTH=true \
  adamwilsonlab/emma:latest
```

# HPC
To use this container in an HPC environment like UB's CCR, you need to use singularity (a wrapper for docker that keeps things secure in a networked environment).

You must be on campus or in the [UB VPN to use this service](https://www.buffalo.edu/ubit/service-guides/connecting/vpn/computer.html).

## Set up Apptainer (Singularity)

You only need to run this once (unless you want to update the container). Before building the container, you will need to set some temp/cache folders or the build will fail because the home directory doesn't have much room.

First, you can log into a compute node.  For example:

```
ssh vortex.ccr.buffalo.edu

salloc --cluster=faculty --qos=adamw --partition=adamw  --job-name "InteractiveJob" --nodes=1 --ntasks=2 --mem=5G -C INTEL --time=05:20:00
```

Then set the following environment variables, create a few directories, and build the container.

```
# define groupname for paths
export GROUP="adamw"

# mount project folder inside container:
export PROJECT_FOLDER="/projects/academic/"$GROUP/

# define local working folder to build the SIF file (this is faster than network storage)
export APPTAINER_CACHEDIR=$PROJECT_FOLDER"/users/"$USER"/apptainer"
export APPTAINER_TMPDIR=$APPTAINER_CACHEDIR"/tmp"
export APPTAINER_LOCALCACHEDIR=$APPTAINER_CACHEDIR"/tmp"

# set singularity cache and tmp directories to the same as apptainer
# needed because CCR is still using singularity and it will use these directories
export SINGULARITY_CACHEDIR=$APPTAINER_CACHEDIR
export SINGULARITY_TMPDIR=$APPTAINER_TMPDIR
export SINGULARITY_LOCALCACHEDIR=$APPTAINER_LOCALCACHEDIR

# path to singularity container file.  If you want to use a different image, you'll need
# to update this line.
export DOCKER_PATH="docker://adamwilsonlab/emma:latest"
export SIF_FILE="AdamWilsonLab-emma_docker-latest.sif"
export SIF_PATH=$PROJECT_FOLDER"/users/"$USER"/apptainer/"

# Create the folders if they don't already exist
mkdir -p $PROJECT_FOLDER"/users/"$USER"/apptainer" # create project folder
mkdir -p $APPTAINER_CACHEDIR/tmp # create apptainer cache directory
mkdir -p $APPTAINER_CACHEDIR/run # create apptainer run directory
mkdir -p $APPTAINER_CACHEDIR/rstudio # create apptainer RStudio directory

# go to cachedir for faster build
cd $APPTAINER_CACHEDIR

## Build the singularity image (.SIF) directly from Docker image locally
### If it takes too long, you can use `nohup` first to allow it to keep running if the SSH connection is broken.

singularity build --force $SIF_FILE $DOCKER_PATH & nohup


# Move it to its permanent home
mkdir -p $SIF_PATH # create SIF path if it doesn't exist
mv $SIF_FILE $SIF_PATH # move the SIF file to its permanent location
```

Now the container exists at $SIF_PATH and is ready to be used.  You only need to repeat the above steps if you want to update the container. 

## Run the container for interactive computation

SSH to vortex.ccr.buffalo.edu and then request an interactive job with something like: 

```
ssh vortex.ccr.buffalo.edu
salloc --cluster=faculty --qos=adamw --partition=adamw  --job-name "InteractiveJob" --nodes=1 --ntasks=2 --mem=5G -C INTEL --time=05:20:00
```

Then run the following to start using R from the container:

```
export GROUP="adamw"
export PROJECT_FOLDER="/projects/academic/"$GROUP
export APPTAINER_CACHEDIR=$PROJECT_FOLDER"/users/"$USER"/apptainer"
export SIF_PATH=$PROJECT_FOLDER"/users/"$USER"/singularity"
export SIF_FILE="AdamWilsonLab-emma_docker-latest.sif"

# set singularity cache and tmp directories to the same as apptainer
# needed because CCR is still using singularity and it will use these directories
export SINGULARITY_CACHEDIR=$APPTAINER_CACHEDIR
export SINGULARITY_TMPDIR=$APPTAINER_TMPDIR
export SINGULARITY_LOCALCACHEDIR=$APPTAINER_LOCALCACHEDIR


apptainer run \
      --bind $PROJECT_FOLDER:$PROJECT_FOLDER \
      --bind $APPTAINER_CACHEDIR/tmp:/tmp \
      --bind $APPTAINER_CACHEDIR/run:/run \
      $SIF_PATH/$SIF_FILE R
```
## Local VSCode Method

1) Install Extensions:
   - R
   - R Syntax
   - Quarto (optional)
3) Mount CCR via SSHFS or Mountain Duck
4) Use this folder for project data storage: `/projects/academic/adamw/users/$USER`
5) VSCode
   - Confirm R extension settings:
      - r.alwaysUseActiveTerminal True: Forces code to be sent to whatever terminal is active, no questions asked.
    -  Open project directory on CCR (vortex) through the mounted path
    -  Open a Local Integrated Terminal (Terminal → New Terminal)
    -  In VS Code Terminal: 

```
ssh vortex.ccr.buffalo.edu
salloc --cluster=faculty --qos=adamw --partition=adamw \
       --job-name=InteractiveJob --nodes=1 --ntasks=4 \
       --mem=10G -C INTEL --time=03:00:00
```
Then open the container using the code above.  

## Use CCR OnDemand
You can also use CCR OnDemand
Use [CCR's OnDemand portal](https://ondemand.ccr.buffalo.edu/pun/sys/dashboard/)
