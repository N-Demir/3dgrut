#!/bin/bash
set -e

# Check if data_folder and output_folder arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <data_folder> <output_folder>"
    echo "Example: $0 /nvs-bench/data/mipnerf360/bicycle /nvs-bench/methods/3dgs/mipnerf360/bicycle"
    exit 1
fi
data_folder=$1
output_folder=$2

######## START OF YOUR CODE ########
# 1) Train 
#   python train.py --data $data_folder --output $output_folder --eval
# 2) Render the test split
#   python render.py --data $data_folder/test --output $output_folder --eval
# 3) Move the renders into `$output_folder/test_renders`
#   mv $output_folder/test/ours_30000/renders $output_folder/test_renders


# 3DGRUT is a little tricky because the outputs have a unique random identifier that cannot be
# set in the run config, so we don't know in advance what the checkpoint path will be or the
# renders output. Hence using newly created folders in which this run's output folder will be
# the only subfolder. 
rm -fr runs/
rm -fr output_renders/

python train.py --config-name apps/colmap_3dgut_mcmc.yaml \
    path=$data_folder \
    optimizer.type=selective_adam \
    n_iterations=10

checkpoint_path="$(find runs/ -name "ckpt_last.pt")"
python render.py \
    --checkpoint $checkpoint_path \
    --path $data_folder \
    --out-dir output_renders/

renders_folder="$(find output_renders/ -type d -name "renders")"
mv $renders_folder $output_folder