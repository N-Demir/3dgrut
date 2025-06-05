import subprocess
from pathlib import Path

import modal

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
    ### Add local code (at the very end to not reinstall everything)
    .workdir("/workspace")
    .add_local_file("requirements.txt", "/workspace/requirements.txt", copy=True)
    .run_commands("/opt/conda/bin/conda run -n 3dgrut pip install -r requirements.txt")
    .add_local_dir(".", "/workspace")
)

@app.function(gpu="T4", volumes={
    "/root/data": modal.Volume.from_name("data", create_if_missing=True),
    "/root/output": modal.Volume.from_name("output", create_if_missing=True),
},
    timeout=600,
)
@modal.concurrent(max_inputs=10)
@modal.web_server(8888, startup_timeout=90)
def run():
    print("Starting the viewer!")
    subprocess.Popen(
        "/opt/conda/bin/conda run -n 3dgrut python /workspace/viser_gui.py --gs_object /root/output/sofia-0206_202149/ours_7000/ckpt_7000.pt",
        shell=True,
    )
# TODO: This isn't working for some goddamn reason. WHYYYYY. It's so fucking simmple! Just use the conda env damnit...