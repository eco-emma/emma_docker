#!/bin/bash
#SBATCH --job-name=build_emma_apptainer
#SBATCH --output=build_emma_apptainer_%j.log
#SBATCH --error=build_emma_apptainer_%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=general-compute
#SBATCH --qos=general-compute
#SBATCH --cluster=ub-hpc
#SBATCH --account=adamw

echo "=========================================="
echo "Job started:  $(date)"
echo "Job ID:       $SLURM_JOB_ID"
echo "Running on:   $(hostname)"
echo "=========================================="

# define groupname for paths
export GROUP="adamw"

# mount project folder inside container:
export PROJECT_FOLDER="/projects/academic/${GROUP}"

# define local working folder to build the SIF file (this is faster than network storage)
export APPTAINER_CACHEDIR="/vscratch/grp-adamw/${USER}/apptainer"

# Use node-local /tmp for the actual build temp dir — vscratch is often mounted
# noexec which prevents proot/mksquashfs from executing binaries during the build.
export APPTAINER_TMPDIR="/tmp/${USER}_apptainer_$$"
export APPTAINER_LOCALCACHEDIR=$APPTAINER_TMPDIR

# set singularity cache and tmp directories to the same as apptainer
# needed because CCR is still using singularity and it will use these directories
export SINGULARITY_CACHEDIR=$APPTAINER_CACHEDIR
export SINGULARITY_TMPDIR=$APPTAINER_TMPDIR
export SINGULARITY_LOCALCACHEDIR=$APPTAINER_LOCALCACHEDIR

# also set TMPDIR so mksquashfs and other subprocesses use local /tmp
export TMPDIR=$APPTAINER_TMPDIR

# path to docker image and name of the resulting SIF file
export DOCKER_PATH="docker://adamwilsonlab/emma:latest"
export SIF_FILE="AdamWilsonLab-emma_docker-latest.sif"
export SIF_PATH="${PROJECT_FOLDER}/users/${USER}/apptainer"

echo "APPTAINER_CACHEDIR: ${APPTAINER_CACHEDIR}"
echo "SIF destination:    ${SIF_PATH}/${SIF_FILE}"
echo ""

# Create the folders if they don't already exist
mkdir -p "${SIF_PATH}"
mkdir -p "${APPTAINER_CACHEDIR}/run"
mkdir -p "${APPTAINER_CACHEDIR}/rstudio"
# create the node-local build temp dir and clean it up when the job exits
mkdir -p "${APPTAINER_TMPDIR}"
trap "rm -rf '${APPTAINER_TMPDIR}'" EXIT

# go to cachedir for faster build
cd "${APPTAINER_CACHEDIR}" || { echo "ERROR: could not cd to ${APPTAINER_CACHEDIR}"; exit 1; }

## Build the singularity/apptainer image (.SIF) directly from Docker image
# PROOT_NO_SECCOMP=1 is required on kernels that block ptrace via seccomp,
# which causes mksquashfs to fail with "ptrace(TRACEME): Operation not permitted"
# See: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1202161
export PROOT_NO_SECCOMP=1

echo "Starting apptainer build at $(date) ..."
singularity build --force "${SIF_FILE}" "${DOCKER_PATH}"
BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo "ERROR: apptainer build failed with exit code ${BUILD_STATUS}"
    exit $BUILD_STATUS
fi

echo "Build completed successfully at $(date)"

# Move it to its permanent home
echo "Moving ${SIF_FILE} to ${SIF_PATH} ..."
mv "${SIF_FILE}" "${SIF_PATH}/"

echo ""
echo "=========================================="
echo "Done! SIF file located at:"
echo "  ${SIF_PATH}/${SIF_FILE}"
echo "Job finished: $(date)"
echo "=========================================="
