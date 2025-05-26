# Global ARG
ARG VARIANT="3-alpine"

# Stage 1: py_builder - Install build dependencies -----------------------------
FROM python:$VARIANT AS base
FROM base AS py_builder

COPY requirements*.txt /

# Install dependencies to the local user directory (eg. /root/.local)
RUN for req in /requirements*.txt; do \
        pip3 --disable-pip-version-check install --user -r "$req"; \
    done


# Stage 2: ytarchive_builder - Install build dependencies ----------------------
FROM golang:alpine AS ytarchive_builder

RUN go install github.com/Kethsar/ytarchive@dev


# Stage 3: ffmpeg_builder - download and extract FFmpeg ------------------------
FROM debian:bullseye-slim AS ffmpeg_builder

# Install required tools
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
    curl \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set FFmpeg version and download URL
ENV FFMPEG_URL=https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz

# Download and extract FFmpeg
WORKDIR /tmp
RUN curl -SsL "$FFMPEG_URL" -o ffmpeg.tar.xz \
    && tar -xf ffmpeg.tar.xz --strip-components=1 \
    && rm ffmpeg.tar.xz


# Final - Copy only necessary files to the runner stage ------------------------
FROM base AS final

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
    # curl \
    # git \
    # zsh \
    # vim \
    # less \
    locales \
    tzdata \
    # Set up timezone
    && export TZ=Asia/Taipei \
	&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
	&& echo $TZ > /etc/timezone \
	&& dpkg-reconfigure -f noninteractive tzdata \
    # Set up locale
    && echo "zh_TW.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# This Dockerfile adds a non-root 'vscode' user. However, for Linux,
# this user's GID/UID must match your local user UID/GID to avoid permission issues
# with bind mounts. Update USER_UID / USER_GID if yours is not 1000. See
# https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
# Workaround for the vscode remote ssh error Group with GID exists (users=100).
# Fix "remoteUser" does not switch to UID/GID when docker host user has GID=100.
    && groupdel users

# Set the default locale, port and working directory
ENV LANG=zh_TW.UTF-8 LC_TIME=C PORT=8000
EXPOSE $PORT
WORKDIR /workspace

# Copy FFmpeg binaries directly into /usr/local/bin
COPY --from=ffmpeg_builder /tmp/ffmpeg /usr/local/bin/
# Copy ytarchive binaries from the 2nd stage image
COPY --from=ytarchive_builder /go/bin/ytarchive /usr/local/bin/
# Copy only the dependencies installation from the 1st stage image
COPY --from=py_builder /root/.local /usr/local
# Copy the rest of the application code
COPY src ./src

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--reload"]
