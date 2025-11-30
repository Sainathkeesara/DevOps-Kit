FROM debian:stable-slim

# Install base packages, sudo, and git
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    wget \
    ca-certificates \
    procps \
    sudo \
    git \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN apt-get update && apt-get install -y ansible

# Create a non-root user with passwordless sudo
RUN useradd -ms /bin/bash developer \
    && usermod -aG sudo developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to developer user (optional; remove if you prefer root)
USER developer
WORKDIR /home/developer

CMD ["sh", "-c", "sleep infinity"]