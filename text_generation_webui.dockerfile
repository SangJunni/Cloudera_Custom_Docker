# Dockerfile
# Specify an ML Runtime base image
FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-jupyterlab-python3.10-cuda:2024.02.1-b4 AS app_base
# Install requirements in the new image// Before install you must copy local files to docker.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install --no-install-recommends -y \
    git vim build-essential python3-dev python3-venv python3-pip
# Instantiate venv and pre-activate
RUN pip3 install virtualenv
RUN virtualenv /venv
# Credit, Itamar Turner-Trauring: https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip3 install --upgrade pip setuptools
# Copy and enable all scripts
COPY ./scripts /scripts
RUN chmod +x /scripts/*
### DEVELOPERS/ADVANCED USERS ###
# Clone oobabooga/text-generation-webui
RUN git clone https://github.com/oobabooga/text-generation-webui /src
# Use script to check out specific version
ARG VERSION_TAG
ENV VERSION_TAG=${VERSION_TAG}
RUN . /scripts/checkout_src_version.sh
# To use local source: comment out the git clone command then set the build arg `LCL_SRC_DIR`
#ARG LCL_SRC_DIR="text-generation-webui"
#COPY ${LCL_SRC_DIR} /src
#################################
# Copy source to app
RUN cp -ar /src /app


# NVIDIA-CUDA [Daily driver. Well done - you are the incumbent, Nvidia! Don't exploit your position.]
# Base
FROM app_base AS app_nvidia
# Install pytorch for CUDA 12.1
RUN pip3 install torch==2.2.1 torchvision==0.17.1 torchaudio==2.2.1 \
    --index-url https://download.pytorch.org/whl/cu121 
# Install oobabooga/text-generation-webui
RUN pip3 install -r /app/requirements.txt

# Extended
FROM app_nvidia AS app_nvidia_x
# Install extensions
RUN chmod +x /scripts/build_extensions.sh && \
    . /scripts/build_extensions.sh
# Upgrade packages in the base image
# Override Runtime label and environment variables metadata
ENV ML_RUNTIME_EDITION="Obabooga Edition" \
       	ML_RUNTIME_SHORT_VERSION="1.0" \
        ML_RUNTIME_MAINTENANCE_VERSION=1 \
        ML_RUNTIME_DESCRIPTION="This runtime includes text-generation-webui settings"
ENV ML_RUNTIME_FULL_VERSION="${ML_RUNTIME_SHORT_VERSION}.${ML_RUNTIME_MAINTENANCE_VERSION}"
LABEL com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
        com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
        com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
        com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
        com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION