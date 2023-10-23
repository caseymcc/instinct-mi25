FROM ubuntu:20.04

ARG ROCM_VERSION=5.3
ARG AMDGPU_VERSION=5.3
ARG RENDER_GROUP_ID

RUN if [ ${RENDER_GROUP_ID:-0} -ne 0 ]; then \
    groupadd -g ${RENDER_GROUP_ID} render \
;fi

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg \
  && curl -sL http://repo.radeon.com/rocm/rocm.gpg.key | apt-key add - \
  && sh -c 'echo deb [arch=amd64] http://repo.radeon.com/rocm/apt/$ROCM_VERSION/ focal main > /etc/apt/sources.list.d/rocm.list' \
  && sh -c 'echo deb [arch=amd64] https://repo.radeon.com/amdgpu/$AMDGPU_VERSION/ubuntu focal main > /etc/apt/sources.list.d/amdgpu.list' \
  && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo \
    libelf1 \
    libnuma-dev \
    build-essential \
    git \
    wget \
    aria2 \
    vim-nox \
    cmake-curses-gui \
    kmod \
    file \
    python3 \
    python3-dev \
    python3-pip \
    rocm-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/pip \
    /usr/bin/python3 -m pip install -U pip

RUN --mount=type=cache,target=/root/.cache/pip \
    /usr/bin/python3 -m pip install --break-system-packages torch torchvision \
        --index-url https://download.pytorch.org/whl/rocm$ROCM_VERSION

RUN --mount=type=cache,target=/root/.cache/pip \
    /usr/bin/python3 -m pip install --break-system-packages -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    /usr/bin/python3 -m pip install --break-system-packages -r https://raw.githubusercontent.com/Fannovel16/comfyui_controlnet_aux/main/requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/rocm$ROCM_VERSION

#RUN echo '%sudo   ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sudo-nopasswd
RUN useradd --create-home -G sudo,video,render --shell /bin/bash runner

USER runner:runner
VOLUME /home/runner
WORKDIR /home/runner
EXPOSE 8188
#CMD ["bash","/home/scripts/entrypoint.sh"]
CMD ["bash","-l"]
