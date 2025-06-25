from pathlib import Path
import socket
import subprocess
import threading
import time
import modal

# app = modal.App("3dgrut", image=modal.Image.from_dockerfile(Path(__file__).parent / "Dockerfile"))
app = modal.App("3dgrut", image=modal.Image.from_registry("nikitademir/3dgrut:latest")
    # GCloud
    #TODO: Install gcloud
    .run_commands("apt-get update && apt-get install -y curl gnupg && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo \"deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main\" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && apt-get install -y google-cloud-cli")
    .add_local_file(Path.home() / "gcs-tour-project-service-account-key.json", "/root/gcs-tour-project-service-account-key.json", copy=True)
    .run_commands(
        "gcloud auth activate-service-account --key-file=/root/gcs-tour-project-service-account-key.json",
        "gcloud config set project tour-project-442218",
        "gcloud storage ls"
    )
    .env({"GOOGLE_APPLICATION_CREDENTIALS": "/root/gcs-tour-project-service-account-key.json"})
    .run_commands("gcloud storage ls")
    # # SSH server
    .apt_install("openssh-server")
    .run_commands(
        "mkdir -p /run/sshd" #, "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config", "echo 'root: ' | chpasswd" #TODO: uncomment this if the key approach doesn't work
    )
    .add_local_file(Path.home() / ".ssh/id_rsa.pub", "/root/.ssh/authorized_keys", copy=True)
    # Install and configure Git
    .run_commands("apt-get install -y git")
    .run_commands("git config --global pull.rebase true")
    .run_commands("git config --global user.name 'Nikita Demir'")
    .run_commands("git config --global user.email 'nikitde1@gmail.com'")
    # Build the ninja code
    .workdir("/workspace")
    .run_commands("gcloud storage rsync -r gs://tour_storage/data/tandt/truck /build_data/tandt/truck")
    .run_commands("/opt/conda/bin/conda run -n 3dgrut python train.py --config-name apps/colmap_3dgut_mcmc.yaml path=/build_data/tandt/truck optimizer.type=selective_adam n_iterations=5 num_workers=1", gpu="T4")
    # TODO: Remove these after testing the viewer works
    ### Add local code (at the very end to not reinstall everything)
    .add_local_file("requirements.txt", "/workspace/requirements.txt", copy=True)
    .run_commands("/opt/conda/bin/conda run -n 3dgrut pip install -r requirements.txt")
    .add_local_dir(".", "/workspace")
)

@app.function(
    timeout=3600 * 24,
    gpu="T4",
    secrets=[modal.Secret.from_name("wandb-secret"), modal.Secret.from_name("github-token")],
    volumes={"/root/.cursor-server": modal.Volume.from_name("cursor-server", create_if_missing=True), 
             "/root/data": modal.Volume.from_name("data", create_if_missing=True),
             "/root/output": modal.Volume.from_name("output", create_if_missing=True)
             }
)
def run_experiment():
    # Added these commands to get the env variables that docker loads in through ENV to show up in my ssh
    import os
    import shlex
    from pathlib import Path

    output_file = Path.home() / "env_variables.sh"

    with open(output_file, "w") as f:
        for key, value in os.environ.items():
            escaped_value = shlex.quote(value)
            f.write(f'export {key}={escaped_value}\n')
    subprocess.run("echo 'source ~/env_variables.sh' >> ~/.bashrc", shell=True)

    subprocess.run(["bash experiment.sh"], shell=True)

@app.local_entrypoint()
def main():
    run_experiment.remote()

