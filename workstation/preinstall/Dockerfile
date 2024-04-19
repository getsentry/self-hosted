# Use a predefined image with no out-of-the-box IDE set up.
FROM us-west1-docker.pkg.dev/cloud-workstations-images/predefined/base:latest

# Modifications to the `/home` directory must take place outside of the Dockerfile. Add a startup
# script to handle the cloning of the `sentry` and `self-hosted` repositories.
COPY 200_download-self-hosted.sh /etc/workstation-startup.d/
COPY 299_setup-completed.sh /etc/workstation-startup.d/

RUN chmod -R +x /etc/workstation-startup.d

# Avoid prompts from apt by setting it to non-interactive.
ENV DEBIAN_FRONTEND=noninteractive

# Install VSCode and the GitHub CLI.
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > vscode.gpg \
    && install -D -o root -g root -m 644 vscode.gpg /etc/apt/keyrings/vscode.gpg \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && rm -f vscode.gpg \
    && apt-get update \
    && apt-get install -y code \
    && apt-get install -y curl \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/gh.gpg \
    && chmod go+r /usr/share/keyrings/gh.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gh.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && rm -f gh.gpg \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Reset the DEBIAN_FRONTEND environment variable.
ENV DEBIAN_FRONTEND=
