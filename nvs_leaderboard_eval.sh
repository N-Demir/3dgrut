#!/bin/bash
set -e

# Auto-detect repo name as method; fallback to current directory if not a git repo
method_name="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
method_name="${method_name// /_}"

# Check if scene argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <dataset/scene>"
    echo "Example: $0 mipnerf360/bicycle"
    exit 1
fi

scene=$1

expected_output_folder="/nvs-leaderboard-output/$scene/$method_name/test_renders"

# Remove the output folder if it already exists
rm -rf /nvs-leaderboard-output/$scene/$method_name
mkdir -p /nvs-leaderboard-output/$scene/$method_name

# Record start time
start_time=$(date +%s)


######## START OF YOUR CODE ########
# Train using the train split in the dataset folder
# eg: python train.py --data /nvs-leaderboard-data/$scene/train --output /nvs-leaderboard-output/$scene/$method/
# python train.py -s /nvs-leaderboard-data/mipnerf360/bicycle/train -m /nvs-leaderboard-output/mipnerf360/bicycle/3dgrut/ --iterations 10


# To pass the checkpoint path from training to rendering, 
# since we don't know exactly what the generated folder will be
# because it's based on a time stamp, just ensure there's only ever
# one run in the runs/ folder and use find to find the 
# checkpoint path
rm -fr runs/
rm -fr output_renders/

python train.py --config-name apps/colmap_3dgut_mcmc.yaml \
    path=/nvs-leaderboard-data/$scene \
    optimizer.type=selective_adam \
    n_iterations=10 \
    checkpoint.iterations=[10]

# Render the test split
# eg: python render.py --data /nvs-leaderboard-data/$scene/test --output /nvs-leaderboard-output/$scene/$method/ 

checkpoint_path=$(find runs/ -name "ckpt_last.pt")

python render.py \
    --checkpoint $checkpoint_path \
    --path /nvs-leaderboard-data/$scene \
    --out-dir output_renders/

renders_folder=$(find output_renders/ -name "renders")

mv $renders_folder $expected_output_folder

# At the end, move your renders into the `expected_output_folder`
# eg: mv /nvs-leaderboard-output/$scene/$method/train/ours_$iterations/renders $expected_output_folder
######## END OF YOUR CODE ########

# Record end time and show duration
end_time=$(date +%s)
echo $((end_time - start_time)) > /nvs-leaderboard-output/$scene/$method/training_time.txt
