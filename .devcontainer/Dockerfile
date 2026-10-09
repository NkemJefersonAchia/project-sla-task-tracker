FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install dependencies needed by Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Set up user environment
USER vscode
ENV HOME=/home/vscode
ENV FLUTTER_HOME=${HOME}/flutter
ENV PATH=${PATH}:${FLUTTER_HOME}/bin

# Clone Flutter stable branch
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME}

# Enable Flutter Web and run initial precache
RUN flutter config --enable-web && flutter precache