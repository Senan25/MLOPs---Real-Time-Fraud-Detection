FROM jenkins/jenkins:lts-jdk17

USER root

# Optional: tools Jenkins jobs often need
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl unzip python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

# Preinstall plugins (edit plugins.txt to taste)
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Skip the setup wizard only if you configure security yourself (e.g. JCasC)
# ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"