#!/bin/bash
# this is intended for running DPS jobs; the input directory is where four files have been pulled because download=TRUE in the algorithm_config.yaml file
# a tar file of biomass models, a data table csv, and two raster stack geotiff files
set -xuo pipefail
source activate icesat2_boreal
basedir=$( cd "$(dirname "$0")" ; pwd -P )

#unset PROJ_LIB

#pip install --user -r ${basedir}/requirements.txt

mkdir output

# Note: the numbered args are fed in with the in_param_dict in the Run DPS chunk of 3.4_dps.ipynb
ATL08_tindex_master_fn=${1}
TOPO_TIF=${2}
LANDSAT_TIF=${3}
LC_TIF=${4}
DO_SLOPE_VALID_MASK=${5}
ATL08_SAMPLE_CSV=${6}
in_tile_num=${7}
in_tile_fn=${8}
in_tile_field=${9}
iters=${10}
ppside=${11}
minDOY=${12}
maxDOY=${13}
max_sol_el=${14}
expand_training=${15}
local_train_perc=${16}
min_n=${17}
boreal_vect_fn=${18}
predict_var=${19}

TAR_FILE=${basedir}/../../lib/bio_models.tar

#unpack biomass models tar
#tar -xvf input/bio_models.tar

# This will put the *rds in the same dir as the R script
tar -xf ${TAR_FILE}

# This PWD is wherever the job is run (where the .sh is called from) 
OUTPUTDIR="${PWD}/output"

# Get the output merged CSV of filtered ATL08 for the input tile and its neighbors
cmd="python ${basedir}/../../lib/merge_neighbors_atl08.py -in_tile_num ${in_tile_num} -in_tile_fn ${in_tile_fn} -in_tile_field ${in_tile_field} -csv_list_fn ${ATL08_tindex_master_fn} -out_dir ${OUTPUTDIR}"

echo $cmd
eval $cmd

# Set the output merged CSV name to a var
MERGED_ATL08_CSV=$(ls ${OUTPUTDIR}/atl08_004_30m_filt_merge_neighbors* | head -1)

source activate r-with-gdal

echo $MERGED_ATL08_CSV
echo $ATL08_SAMPLE_CSV

# Run mapBoreal with merged CSV as input
Rscript ${basedir}/../../lib/mapBoreal_simple.R ${MERGED_ATL08_CSV} ${TOPO_TIF} ${LANDSAT_TIF} ${LC_TIF} ${DO_SLOPE_VALID_MASK} ${ATL08_SAMPLE_CSV} ${iters} ${ppside} ${minDOY} ${maxDOY} ${max_sol_el} ${expand_training} ${local_train_perc} ${min_n} ${boreal_vect_fn} ${predict_var}

#convert output to cog - downgraded gdal to 3.3.3 in build_command_main.sh
#source activate base

#IN_TIF_NAME=$(ls ${PWD}/output/*tmp.tif)
#OUT_TIF_NAME=$(echo ${IN_TIF_NAME%tmp.tif}.tif)

#gdal_translate -of COG $IN_TIF_NAME $OUT_TIF_NAME -r average
#rm $IN_TIF_NAME
