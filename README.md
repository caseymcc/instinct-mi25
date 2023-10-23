# How to work with the AMD Instinct MI-25

First off I started my journey after watching Wendell on [LevelOne Techs](https://www.level1techs.com/) on the MI-25, which led me to this post on their [forums](https://forum.level1techs.com/t/mi25-stable-diffusions-100-hidden-beast/194172). Although it is a great post and I likely would not have gotten it working with out it, actually getting something running took a lot more than just that post.

First and foremost, you have to have a PC that supports both `4G Decoding` (likely `Resizable BAR` as well). I started with a PC without both, then one with `4G Decode` using an AMD A10 (which did not work) and finally got it working with the same motherboard with a Ryzen (Instead of the A10) which opend up the `Re Size BAR Support`.

You need to set the following in the bios, each bios varies so it will be something like the below.

```
Above 4G Decoding - Enabled
Re Size BAR Support - Enabled

CSM - Disabled
```

If you are not planning to use the `MI-25` as a gpu then you can skip everything about changing the bios. I did not test the bios changes as I never planned to use it as a gpu.

## Installing Linux

As the Levelone post notes you need spedific Linux kernels to get it working, AMD's ROCm only support certain [ones](https://rocm.docs.amd.com/en/latest/release/gpu_os_support.html). I can say for sure that you do not need the specific kernel called out in the post as mine is 5.15.0-XX. In the end I went with the Ubuntu version in the post however I ended up working fine on the updated Kernel it had (if I get a chance I want to try other versions)

Grab the Unbuntu version `20.04.03` from [here](https://old-releases.ubuntu.com/releases/20.04.3/). It comes with the kernel version
```
Linux zeus 5.15.0-87-generic #97~20.04.1-Ubuntu SMP Thu Oct 5 08:25:28 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```
Again not sure if other kernels can be handled yet so it is in your best interest to not let it update after the install.

## Installing ROCm

You will need to install ROCm, get the [5.2.5 deb](http://repo.radeon.com/amdgpu-install/22.20.5/ubuntu/focal/). Support for the `MI-25` has been discontinued after `ROCm 4.5.2` however this version seems to still supported it (later version need to be tested as well). [AMD's install instructions](https://rocm.docs.amd.com/en/latest/deploy/linux/installer/install.html)

Once the downloaded completes you can then install it with the following
```
sudo dpkg -i amdgpu-install_22.20.50205-1_all.deb
```
Once the install completes you will need to run `amdgpu-install`
```
amdgpu-install --usecase=rocm
```
the post list more usecases, however it seems rocm covers all those cases as all the others will be installed.

When the install is complete, you need to add the current user to the `video` and `render` groups.
```
sudo usermod -a -G video
sudo usermod -a -G render
```
Now make sure to reboot the system. After the reboot you can check if ROCm is able to talk with the `MI-25` using the following

```
/opt/rocm/bin/rocminfo
ROCk module is loaded
=====================
HSA System Attributes
=====================
Runtime Version:         1.1
System Timestamp Freq.:  1000.000000MHz
Sig. Max Wait Duration:  18446744073709551615 (0xFFFFFFFFFFFFFFFF) (timestamp count)
Machine Model:           LARGE
System Endianness:       LITTLE

==========
HSA Agents
==========
*******
Agent 1
*******
  Name:                    AMD Ryzen 5 5600G with Radeon Graphics
  ...
  Device Type:             CPU
  ...
*******
Agent 2
*******
  Name:                    gfx900
  ...
  Device Type:             GPU
  ...
*******
Agent 3
*******
  Name:                    gfx90c
  ...
  Device Type:             GPU
  ...
*** Done ***
```
You can see that on my machine ROCm has picked up the
```
Agent 1 - CPU
Agent 2 - Integrated GPU
Agent 3 - MI-25
```

You can also use
```
/opt/rocm/bin/rocm-smi --showproductname


======================= ROCm System Management Interface =======================
================================= Product Info =================================
GPU[0]		: Card series: 		Vega 10 [Radeon Instinct MI25]
GPU[0]		: Card model: 		Radeon PRO V320
GPU[0]		: Card vendor: 		Advanced Micro Devices, Inc. [AMD/ATI]
GPU[0]		: Card SKU: 		D05135
GPU[1]		: Card series: 		0x1638
GPU[1]		: Card model: 		Radeon RX Vega 11
GPU[1]		: Card vendor: 		Advanced Micro Devices, Inc. [AMD/ATI]
GPU[1]		: Card SKU: 		CEZANN
================================================================================
============================= End of ROCm SMI Log ==============================

```
To get a list of devices, this will show the `device index` used by anything calling ROCm. As you can see, although the `MI-25` is `Agent 3` it is seen as device `0` (`GPU[0]`). This can be helpfull as if you have multiple ROCm supported devices those device may not be supported by the tools (pytorch, etc...) and you will need to force the tool to use a specific device.

## ROCm with Docker/Pytorch

As you can see from this repo I went with running the apps in dockers. AMD does not require anything special about the Docker install to use the device in the docker, other than adding the device to the container.

Install docker like [normal](https://docs.docker.com/desktop/install/ubuntu/). Once installed you can test that docker is working with [AMD's ROCm dockers](https://github.com/RadeonOpenCompute/ROCm-docker).

```
sudo docker pull rocm/rocm-terminal
sudo docker run -it --device=/dev/kfd --device=/dev/dri --security-opt seccomp=unconfined --group-add video rocm/rocm-terminal
```
Once in the docker you should be able to run the above `/opt/rocm/bin/rocminfo`/`rocm-smi`. If you run into any issues (I did) see [Troubleshooting/Docker](#docker---unable-to-open-devkfd-read-write-permission-denied)


## Runing automatic1111 Stable Diffusion
Working on it

## Runing ConfyUI
I started with the dockers/scripts from [YanWenKan/ComfyUI-Docker](https://github.com/YanWenKun/ComfyUI-Docker), however I ran into a few issues so I altered it to what is in this repo.

Main things:
- Use Ubuntu base
- Install ROCm 5.3
- Setup render group
- add start script
- set CUDA_VISIBLE_DEVICES (maybe turn into config file)

Assuming your setup is similar to my own you can start the ComfyUI by running
```
./run_docker.sh
```

## Running LLama-cpp
Working on it

## Troubleshooting

### “[amdgpu] trn=2 ack should not assert”!
If you are getting the above either on Ubuntu boot or via `dmesg`. There seems to be two main things that cause it
1. Missing `Above 4G Decoding`/`Resizable BAR` support (either not enabled or system does not support)
2. `CSM` is enabled

check your bios for the above and try again.

### Docker - "Unable to open /dev/kfd read-write: Permission denied"
This generally means that the user of the docker is not a member of the `video`/`render` groups. The ROCm documentation seems to imply that this works fine with just including `--group-add video` in the `docker run` call. However on my system the `render` group owns `/dev/kfd`.
```
ls -al /dev/kfd
crw-rw---- 1 root render 511, 0 Oct 21 12:09 /dev/kfd

```
I am assuming this is because I have a supported AMD gpu that is somehow changing who the final owner is. You can change the ownership of the `/dev/kfd` to the `video` group, however on reboot it seems to be reset to the `render` group. My solution to this is to copy to the docker image the `render` group id using docker `BUILDKIT` and the following code

```
DOCKER_BUILDKIT=1 docker build \
    ...
    --build-arg RENDER_GROUP_ID=$(getent group render | cut -d: -f3)
    ...
```
and creating and assigning the group to the docker user (in this case `runner`) in the docker using
```
RUN if [ ${RENDER_GROUP_ID:-0} -ne 0 ]; then \
    groupadd -g ${RENDER_GROUP_ID} render \
;fi
...
RUN useradd --create-home -G sudo,video,render --shell /bin/bash runner
```

### Docker - RuntimeError: HIP error: invalid argument
This is likely caused by the docker containing an incompatible version of `ROCm` than the `ROCm` drivers on the host. Try to installing the same `ROCm` version in the docker as what is on the host. If you are trying to use `pytorch` with `ROCm` and using the pip installer, rather than using the nightly with
```
pip install --break-system-packages --pre torch torchvision \
        --index-url https://download.pytorch.org/whl/nightly/rocm5.7
```
use the standard version with `ROCm`` 5.2 or 5.3
```
pip install --break-system-packages torch torchvision \
        --index-url https://download.pytorch.org/whl/rocm5.3
```

### Docker - "hipErrorNoBinaryForGpu: Unable to find code object for all current devices!"
This is likely caused by `pytorch` trying to open an unsupported device. You can tell `pytorch` which devices to use by setting `CUDA_VISIBLE_DEVICES`. In my case since the `MI-25` is index 0 (see `rocm-smi` above), using the following fixes the issue
```
export CUDA_VISIBLE_DEVICES=0
```
you can also add the above to the `./run_docker.sh` vi the `CLI_ARGS`
```
docker create -it --name $CONTAINER_NAME \
    ...
    --env CUDA_VISIBLE_DEVICES=0 \
    ...
    $DOCKER_NAME
```