# Kali Linux Security Scanning Container
# Based on official Kali Docker best practices
# https://www.kali.org/docs/containers/official-kalilinux-docker-images/

FROM kalilinux/kali-rolling:latest

LABEL maintainer="security-scanning"
LABEL description="Kali Linux configured for web application security testing"

ENV DEBIAN_FRONTEND=noninteractive

# Install security tools including OWASP ZAP
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        # OWASP ZAP (includes zap-baseline.py, zap-full-scan.py, zap-api-scan.py)
        zaproxy \
        # Web scanners (CLI)
        nikto \
        sqlmap \
        wapiti \
        dirb \
        gobuster \
        # Network/recon tools
        nmap \
        whatweb \
        wafw00f \
        # SSL/TLS testing
        sslscan \
        testssl.sh \
        sslyze \
        # Wordlists
        seclists \
        # Utilities
        curl \
        wget \
        jq \
        vim-tiny \
        dnsutils \
        # Python for wapiti and other tools
        python3 \
        python3-pip \
        # Firefox for ZAP AJAX spider
        firefox-esr \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install missing Python dependencies for wapiti
RUN pip3 install --break-system-packages structlog

# Create directories for output and targets
RUN mkdir -p /output /targets

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /output

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--help"]
