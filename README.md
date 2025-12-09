# Security Scanning Toolkit

A Docker-based security scanning toolkit that provides a unified interface for running multiple web application security tools. Works on any platform with Docker - no Kali Linux installation required.

## Features

- **Cross-Platform**: Works on Windows, macOS, and Linux
- **Containerized**: All tools run in a Kali Linux Docker container
- **Simple Interface**: Single command to run any security tool
- **HTML Reports**: Most tools generate HTML reports for easy viewing
- **Production-Safe Modes**: "Gentle" scan options with rate limiting

## Prerequisites

- Docker

## Quick Start

```bash
# Build the Docker image
docker build -t security-scanning .

# Run a scan
docker run --rm -it -v $(pwd)/output:/output security-scanning nikto https://example.com
```

**Windows PowerShell:**
```powershell
docker build -t security-scanning .
docker run --rm -it -v ${PWD}/output:/output security-scanning nikto https://example.com
```

## Available Tools

| Tool | Description | Output |
|------|-------------|--------|
| `nikto` | Web server vulnerability scanner | HTML |
| `sqlmap` | SQL injection scanner | Directory |
| `nmap` | Network/port scanner | Multiple formats |
| `wapiti` | Web application vulnerability scanner | HTML |
| `wapiti-gentle` | Wapiti with rate limiting (1 req/sec) | HTML |
| `whatweb` | Web technology fingerprinting | JSON |
| `wafw00f` | Web application firewall detector | Text |
| `sslscan` | SSL/TLS configuration scanner | Text |
| `testssl` | Comprehensive SSL/TLS testing | HTML |
| `sslyze` | SSL/TLS configuration analyzer | JSON + Text |
| `dirb` | Directory brute-forcer | Text |
| `gobuster` | Directory/DNS brute-forcer | Text |
| `zap-baseline` | OWASP ZAP passive scan (~1 min) | HTML |
| `zap-full` | ZAP active scan (longer) | HTML |
| `zap-full-gentle` | ZAP active scan with rate limiting | HTML |
| `zap-api` | ZAP OpenAPI/GraphQL scan | HTML |
| `shell` | Interactive Kali bash shell | - |

## Usage

### Basic Syntax

**Linux/macOS:**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning <tool> <target> [options]
```

**Windows PowerShell:**
```powershell
docker run --rm -it -v ${PWD}/output:/output security-scanning <tool> <target> [options]
```

- `--rm` removes the container after the scan completes
- `-it` enables interactive mode (allows Ctrl-C to stop scans)
- `-v .../output:/output` mounts the output directory for reports

### Examples

**Web server scan with Nikto:**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning nikto https://example.com        # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning nikto https://example.com        # PowerShell
```

**Network scan with Nmap:**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning nmap example.com -p 80,443       # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning nmap example.com -p 80,443       # PowerShell
```

**SQL injection testing:**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning sqlmap "https://example.com/page?id=1"   # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning sqlmap "https://example.com/page?id=1"   # PowerShell
```

**SSL/TLS analysis:**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning sslscan example.com:443          # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning sslscan example.com:443          # PowerShell
```

### OWASP ZAP Scans

**Quick passive scan (recommended first):**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning zap-baseline https://example.com   # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning zap-baseline https://example.com   # PowerShell
```

**Full active scan (performs attacks - authorized targets only):**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning zap-full https://example.com       # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning zap-full https://example.com       # PowerShell
```

**Rate-limited scan for production systems:**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning zap-full-gentle https://example.com    # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning zap-full-gentle https://example.com    # PowerShell
```

**API security scan (OpenAPI/Swagger):**
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning zap-api https://example.com/api/openapi.json   # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning zap-api https://example.com/api/openapi.json   # PowerShell
```

### Directory Discovery

```bash
# Linux/macOS
docker run --rm -it -v $(pwd)/output:/output security-scanning dirb https://example.com
docker run --rm -it -v $(pwd)/output:/output security-scanning gobuster https://example.com

# PowerShell
docker run --rm -it -v ${PWD}/output:/output security-scanning dirb https://example.com
docker run --rm -it -v ${PWD}/output:/output security-scanning gobuster https://example.com
```

### Interactive Shell

Drop into a Kali shell with all tools available:
```bash
docker run --rm -it -v $(pwd)/output:/output security-scanning shell       # Linux/macOS
docker run --rm -it -v ${PWD}/output:/output security-scanning shell       # PowerShell
```

## Output

All scan reports are saved to the mounted `output/` directory with timestamped filenames:

```
output/
├── nikto_20241208_162801.html
├── zap_baseline_20241208_160823.html
├── nmap_20241208_163000.xml
└── ...
```

## Production-Safe Scanning

For scanning production systems, use the "gentle" variants which include rate limiting:

- `wapiti-gentle` - 1 request per second, limited depth
- `zap-full-gentle` - Single thread, 1 second delay between requests, shallow crawl

These modes help avoid overwhelming target servers or triggering rate limiting.

## Unix Wrapper Script (Optional)

For convenience on Unix systems, a `scan.sh` wrapper is provided:

```bash
./scan.sh nikto https://example.com
./scan.sh zap-baseline https://example.com
```

This wrapper handles Docker commands automatically.

## Container Contents

The Docker image is based on `kalilinux/kali-rolling` and includes:

- OWASP ZAP
- Nikto
- SQLMap
- Nmap
- Wapiti
- WhatWeb
- SSLScan, testssl.sh, SSLyze
- Dirb, Gobuster
- SecLists wordlists
- Firefox ESR (for ZAP AJAX spider)

## Directory Structure

```
security-scanning/
├── Dockerfile           # Container definition with embedded scanner
├── entrypoint.sh        # Scanner entrypoint script
├── docker-compose.yml   # Docker Compose configuration
├── scan.sh              # Optional Unix wrapper script
├── output/              # Scan reports (git-ignored)
├── targets/             # Target lists (git-ignored)
└── README.md
```

## Legal Disclaimer

**This toolkit is intended for authorized security testing only.**

Only use these tools against systems you own or have explicit written permission to test. Unauthorized scanning or penetration testing is illegal and unethical.

The authors are not responsible for misuse of this software.

## License

MIT License - See [LICENSE](LICENSE) for details.
