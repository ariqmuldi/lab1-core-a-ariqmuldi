# COSC 407 / 507 -- one toolchain for every lab this term.
#
# The point of this image is that nobody spends lab time on installation, and
# that every measurement in the course is taken on a comparable toolchain. It is
# used two ways, from the same definition:
#
#   * GitHub Codespaces -- nothing to install, runs in a browser
#   * Docker or Podman on your own machine -- for working offline
#
# Built and published by the course, not by students. See labs/_devcontainer/README.md.

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# build-essential  gcc, make, libc headers
# clang            a second opinion on your code, and ThreadSanitizer -- also
#                  the exact toolchain mull-18 below is built against (18.1.3)
# gdb, valgrind    debugging, and Helgrind for race detection
# libomp-dev       OpenMP runtime, needed from Lab 4 onward
# hwloc            lstopo, so you can report what machine you measured on
# python3 + matplotlib  plotting scaling curves from Lab 4 onward
# libcriterion-dev unit-testing framework for C, from Lab 1 onward
# curl, ca-certificates  needed once, below, to fetch the mull .deb
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      clang \
      gdb \
      valgrind \
      libomp-dev \
      hwloc \
      python3 \
      python3-matplotlib \
      python3-pip \
      libcriterion-dev \
      curl \
      ca-certificates \
      less \
      procps \
      time \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# gcovr -- coverage reporting on top of gcc's --coverage/-fprofile-arcs output.
# Plain pip package, no matching-version concerns the way mull has below.
RUN pip install --break-system-packages --no-cache-dir gcovr

# mull -- mutation testing for C/C++. This is the one dependency in this file
# that is version-pinned on purpose: mull ships a separate .deb per LLVM
# version, and it must match the clang installed above exactly, or mull
# silently fails to find mutants instead of erroring loudly. Ubuntu 24.04's
# `clang` package is LLVM 18.1.3 -- confirmed with `clang --version` -- so we
# pull the matching mull-18 release built for ubuntu-amd64-24.04. If a future
# Ubuntu base image bumps its default clang, this URL needs to be bumped to
# match (check https://github.com/mull-project/mull/releases for the asset
# built against the new version) or mutation testing will quietly find zero
# mutants on every file.
RUN curl -sL -o /tmp/mull.deb \
      "https://github.com/mull-project/mull/releases/download/0.34.1/Mull-18-0.34.1-LLVM-18.1.3-ubuntu-amd64-24.04.deb" \
 && dpkg -i /tmp/mull.deb \
 && rm -f /tmp/mull.deb

# Make the core count obvious the moment a shell opens: every lab asks you to
# report it, and a timing without it is not a measurement.
RUN printf '%s\n' \
    'echo "COSC 407 lab container. $(nproc) cores visible. gcc $(gcc -dumpversion)."' \
    >> /etc/bash.bashrc

WORKDIR /workspaces
