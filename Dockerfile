# syntax=docker/dockerfile:experimental
FROM jupyter/minimal-notebook:6d42503c684f
LABEL maintainer="SonoSim Inc. <teo@sonosim.com>"
ENV LANG C.UTF-8

# Configure bash as the default shell
# -  symlinking bash to `/bin/sh` as a hack since accepted configuration method
#   (setting `c.NotebookApp.terminado_settings = { "shell_command": ["/bin/bash"] }`
#   in jupyter_config.py) fails and `/bin/sh` is still the shell invoked by
#   notebooks for shell commands.
USER root
# hadolint ignore=DL4005
RUN ln -sf /bin/bash /bin/sh

# Reset user and working directory back to default
USER 1000
# Exception: see (https://github.com/hadolint/hadolint/wiki/DL3000)
# hadolint ignore=DL3000
WORKDIR "${HOME}"

# Update Anaconda and expose envs as jupyter kernels
RUN conda update -n base conda && \
    conda install nb_conda_kernels

#Provision environment
ENV FASTAI_BOOK_ENV fastbook
RUN git clone "https://github.com/fastai/${FASTAI_BOOK_ENV}.git"
RUN conda env create -f "${FASTAI_BOOK_ENV}/environment.yml" && \
    conda install -n "${FASTAI_BOOK_ENV}" -c fastai "${FASTAI_BOOK_ENV}" -y

# Configure user env.
# 1. Specify user-installable local env dir
# 2. Truncate prompt for activated env (i.e. env name as opposed to full path)
# 3. Configure bash to init conda
# 4. Symlink `.bashrc` to `.bash_profile` since older jupyter versions read from `.bash_profile`
# 5. Configure bash to automatically activate fastbook env for login shells
#
# NOTE:
# Since everything below occurs in the user's home dir, all files written will
# be overwritten if a volume is mounted at this location (i.e., K8s PVC mount)
# In this case, the operations in this layer will need to be redone in the container
RUN conda config --add envs_dirs "${HOME}/.user_conda_envs/" && \
    conda config --set env_prompt '({name})' && \
    conda init bash && \
    ln -s .bashrc .bash_profile && \
    echo "conda activate ${FASTAI_BOOK_ENV}" >> .bashrc
