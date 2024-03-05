# Dockerfile
# Specify an ML Runtime base image
FROM docker.repository.cloudera.com/cloudera/cdsw/ml-runtime-jupyterlab-python3.10-cuda:2024.02.1-b4
# Before installation you should install portaudio before installing pyaudio
# Install requirements in the new image// Before install you must copy local files to docker.
COPY meta-human-requirements.txt .
RUN apt-get update
RUN apt-get install libportaudio2 libportaudiocpp0 portaudio19-dev libsndfile1-dev -y \
        && pip3 install pyaudio
RUN pip install -r meta-human-requirements.txt
# Upgrade packages in the base image
# Override Runtime label and environment variables metadata
ENV ML_RUNTIME_EDITION="Meta Human Edition" \
       	ML_RUNTIME_SHORT_VERSION="1.0" \
        ML_RUNTIME_MAINTENANCE_VERSION=1 \
        ML_RUNTIME_DESCRIPTION="This runtime includes meta-human-packages"
ENV ML_RUNTIME_FULL_VERSION="${ML_RUNTIME_SHORT_VERSION}.${ML_RUNTIME_MAINTENANCE_VERSION}"
LABEL com.cloudera.ml.runtime.edition=$ML_RUNTIME_EDITION \
        com.cloudera.ml.runtime.full-version=$ML_RUNTIME_FULL_VERSION \
        com.cloudera.ml.runtime.short-version=$ML_RUNTIME_SHORT_VERSION \
        com.cloudera.ml.runtime.maintenance-version=$ML_RUNTIME_MAINTENANCE_VERSION \
        com.cloudera.ml.runtime.description=$ML_RUNTIME_DESCRIPTION