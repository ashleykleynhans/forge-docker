#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="stable-diffusion-webui-forge"
DOCKER_IMAGE_VERSION_FILE="/workspace/${APP}/docker_image_version"

echo "Template version: ${TEMPLATE_VERSION}"
echo "venv: ${VENV_PATH}"

if [[ -e ${DOCKER_IMAGE_VERSION_FILE} ]]; then
    EXISTING_VERSION=$(cat ${DOCKER_IMAGE_VERSION_FILE})
else
    EXISTING_VERSION="0.0.0"
fi

rsync_with_progress() {
    stdbuf -i0 -o0 -e0 rsync -au --info=progress2 "$@" | stdbuf -i0 -o0 -e0 tr '\r' '\n' | stdbuf -i0 -o0 -e0 grep -oP '\d+%|\d+.\d+[mMgG]' | tqdm --bar-format='{l_bar}{bar}' --total=100 --unit='%' > /dev/null
}

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync venv to workspace to support Network volumes
        echo "Syncing venv to workspace, please wait..."
        mkdir -p ${VENV_PATH}
        rsync_with_progress --remove-source-files /venv/ ${VENV_PATH}/

        # Sync application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        rsync_with_progress --remove-source-files /${APP}/ /workspace/${APP}/

        echo "${TEMPLATE_VERSION}" > ${DOCKER_IMAGE_VERSION_FILE}
        echo "${VENV_PATH}" > "/workspace/${APP}/venv_path"
    fi
}

fix_venvs() {
    # Fix the venv to make it work from VENV_PATH
    echo "Fixing venv..."
    /fix_venv.sh /venv ${VENV_PATH}
}

link_models() {
   if [[ ! -L /workspace/stable-diffusion-webui-forge/models/Stable-diffusion/realisticVisionV51_v51VAE.safetensors ]]; then
       ln -s /sd-models/realisticVisionV51_v51VAE.safetensors /workspace/stable-diffusion-webui-forge/models/Stable-diffusion/realisticVisionV51_v51VAE.safetensors
   fi
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs
        link_models

        # Add VENV_PATH to webui-user.sh
         sed -i "s|venv_dir=VENV_PATH|venv_dir=${VENV_PATH}\"\"|" /workspace/stable-diffusion-webui-forge/webui-user.sh
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
else
    echo "Existing version is newer than the template version, not syncing!"
fi

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   /start_forge.sh"
else
    /start_forge.sh
fi

echo "All services have been started"
