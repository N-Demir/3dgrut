#!/bin/bash
echo "Starting experiment"
/opt/conda/bin/conda run -n 3dgrut python train.py --config-name apps/colmap_3dgut_mcmc.yaml path=~/data/vilcek/sofia optimizer.type=selective_adam n_iterations=30000 num_workers=1 experiment_name=sofia-3dgut 

gcloud storage cp -r ~/output/sofia-3dgut/ gs://tour_storage/output/