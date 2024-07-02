#!/usr/bin/env bash

echo "Starting Stable Diffusion WebUI Forge"
export PYTHONUNBUFFERED=1
export HF_HOME="/workspace"
VENV_PATH=$(cat /workspace/stable-diffusion-webui-forge/venv_path)
source ${VENV_PATH}/bin/activate
cd /workspace/stable-diffusion-webui-forge
nohup ./webui.sh -f > /workspace/logs/forge.log 2>&1 &
echo "Stable Diffusion WebUI Forge started"
echo "Log file: /workspace/logs/forge.log"
deactivate
