FROM eclipse-temurin:17-jdk

ENV DEBIAN_FRONTEND=noninteractive

# Harbor/Terminus runtime tools + build utilities (cached early)
RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip wget curl ca-certificates tmux asciinema \
    && rm -rf /var/lib/apt/lists/*
RUN command -v tmux && command -v asciinema

# --- Android SDK ---
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk

# Pin every cache the airgapped verifier reads to an absolute path. Left unset, Gradle derives
# its home from the JVM's user.home, which follows the uid the container happens to run as
# rather than $HOME. If that resolves anywhere other than the path warmed at build time, the
# wrapper cannot find the Gradle distribution, tries to fetch it from services.gradle.org, and
# dies on UnknownHostException because the verifier has no network. That failure is identical
# on every run and invisible from outside the platform.
ENV GRADLE_USER_HOME=/opt/gradle-home
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline.zip && \
    unzip -q /tmp/cmdline.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm /tmp/cmdline.zip

RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

WORKDIR /app
COPY repo/ .
RUN chmod +x ./gradlew
RUN echo "sdk.dir=${ANDROID_HOME}" > local.properties

# test.sh (the verifier) runs on python3; make sure it's present.
RUN command -v python3 >/dev/null 2>&1 || \
    (apt-get update && apt-get install -y --no-install-recommends python3 && rm -rf /var/lib/apt/lists/*)

# Warm the Gradle dependency cache + Robolectric's android-all jars at build time
# so the airgapped test run resolves everything offline. First the base tree as
# shipped. A resolution failure must be loud (broken cache -> hard offline failure
# later), so the exit status is propagated; only the trailing socket/pipe cleanup
# that the vfs storage driver needs before committing a layer is ignored.
RUN set -e; \
    ./gradlew --no-daemon test; \
    find /tmp / -xdev \( -type s -o -type p \) -delete

# The 3.0 Settings feature upgrades a few test dependencies in lib/build.gradle
# (robolectric 4.11.1, core-ktx 1.12.0, androidx.test rules 1.5.0, fest-android
# dropped). The verifier runs under --network=none, so warm that dependency set
# too: apply the bumps, prefetch the matching android-all jars for the SDK levels
# the Settings tests run on (24 for the below-Android-8 default check, 28 for both
# graded classes, and 34 which the module targets) via a
# throwaway Robolectric test, confirm the same run works offline, then restore the
# build.gradle the solver starts from.
RUN set -e; \
    cp lib/build.gradle /tmp/build.gradle.orig; \
    sed -i \
      -e "s/org.robolectric:robolectric:4\.9/org.robolectric:robolectric:4.11.1/" \
      -e "s#testImplementation 'com.squareup:fest-android:1.0.8@aar'#//testImplementation 'com.squareup:fest-android:1.0.8@aar'#" \
      -e "s/androidx.test:rules:1\.1\.0/androidx.test:rules:1.5.0/" \
      -e "s/androidx.core:core-ktx:1\.3\.2/androidx.core:core-ktx:1.12.0/" \
      lib/build.gradle; \
    mkdir -p lib/src/test/java/org/altbeacon/warmup; \
    printf '%s\n' \
      'package org.altbeacon.warmup;' \
      'import org.junit.Test;' \
      'import org.junit.runner.RunWith;' \
      'import org.robolectric.RobolectricTestRunner;' \
      'import org.robolectric.annotation.Config;' \
      '@RunWith(RobolectricTestRunner.class)' \
      '@Config(sdk = {24, 28, 34})' \
      'public class WarmupTest {' \
      '    @Test public void warm() {}' \
      '}' \
      > lib/src/test/java/org/altbeacon/warmup/WarmupTest.java; \
    ./gradlew --no-daemon testDebugUnitTest --tests 'org.altbeacon.warmup.WarmupTest'; \
    ./gradlew --no-daemon --offline testDebugUnitTest --tests 'org.altbeacon.warmup.WarmupTest'; \
    rm -rf lib/src/test/java/org/altbeacon/warmup; \
    cp /tmp/build.gradle.orig lib/build.gradle; \
    find /tmp / -xdev \( -type s -o -type p \) -delete

CMD ["sh", "-c", "./gradlew --no-daemon test"]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
