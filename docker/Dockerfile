FROM ubuntu:24.04

ARG UID=1000
ARG GID=1000
ARG FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.50.0-stable.tar.xz
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5
ARG CMDLINE_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
ARG NODE_VERSION=22.23.5
ARG NODE_SHA256=cdeb8670a0c81f51b4dc4ac61919f9b1ad917b304bf8221eb939570663d240f8

ENV DEBIAN_FRONTEND=noninteractive

# Emulator runtime libraries (X11/xcb, GL, audio) plus the Flutter prerequisites.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip zip xz-utils bash make sudo \
        openjdk-17-jdk-headless \
        libglu1-mesa libgl1 libpulse0 libnss3 libxcomposite1 libxcursor1 libxdamage1 \
        libxi6 libxrandr2 libxtst6 libxkbfile1 libasound2t64 libdbus-1-3 \
        libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
        libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 libxcb-xkb1 \
        libxkbcommon-x11-0 libxkbcommon0 libx11-xcb1 libxshmfence1 libgbm1 \
        libbz2-1.0 libtinfo6 libncurses6 iproute2 procps \
        libice6 libsm6 libfontconfig1 libfreetype6 libpng16-16t64 libpcre2-16-0 libxext6 \
        libxrender1 libxfixes3 libxcb-xfixes0 libxcb-sync1 libxcb-util1 \
    && apt-get clean && rm -r /var/lib/apt/lists/*

# ubuntu:24.04 ships a user "ubuntu" with uid 1000; replace it with "dev".
RUN userdel -r ubuntu 2>/dev/null || true; \
    groupdel ubuntu 2>/dev/null || true; \
    groupadd -g ${GID} dev && useradd -m -u ${UID} -g ${GID} -s /bin/bash dev

# Flutter, checksum verified.
RUN curl -fsSL -o /tmp/flutter.tar.xz "${FLUTTER_URL}" \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && chown -R dev:dev /opt/flutter

# Node 22 LTS, checksum verified against the published SHASUMS256.txt value.
RUN curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/dist/latest-v22.x/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    && echo "${NODE_SHA256}  /tmp/node.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz

ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=/opt/flutter/bin:/home/dev/.pub-cache/bin:/home/dev/.npm-global/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator:${PATH}

# Directories that become named volumes: created here so they inherit dev ownership.
RUN mkdir -p /opt/android-sdk/cmdline-tools /home/dev/.pub-cache /home/dev/.gradle \
        /home/dev/.android /home/dev/.config /work \
    && chown -R dev:dev /opt/android-sdk /home/dev /work

USER dev
WORKDIR /work

RUN curl -fsSL -o /tmp/cmdline-tools.zip "${CMDLINE_TOOLS_URL}" \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# Licenses accepted by Gustavo on 2026-11-19.
RUN yes | sdkmanager --licenses >/dev/null \
    && sdkmanager "platform-tools" "emulator" "system-images;android-34;google_apis_playstore;x86_64" \
        "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"

RUN flutter config --no-analytics --no-cli-animations \
    && flutter precache --android --web \
    && npm config set prefix /home/dev/.npm-global \
    && dart pub global activate flutterfire_cli \
    && npm install -g firebase-tools

# The bind-mounted repo can look foreign to git; trust it.
RUN git config --global --add safe.directory '*'
