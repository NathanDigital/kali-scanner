#!/bin/bash
# Security Scanning Entrypoint
# Usage: docker run security-scanning <tool> <target> [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

usage() {
    echo "Usage: docker run security-scanning <tool> <target> [options]"
    echo ""
    echo "Tools:"
    echo "  nikto           - Web server scanner"
    echo "  sqlmap          - SQL injection scanner"
    echo "  nmap            - Network scanner"
    echo "  wapiti          - Web application vulnerability scanner"
    echo "  wapiti-gentle   - Wapiti with rate limiting (prod-safe)"
    echo "  whatweb         - Web technology fingerprinting"
    echo "  wafw00f         - Web application firewall detector"
    echo "  sslscan         - SSL/TLS scanner"
    echo "  testssl         - SSL/TLS testing tool (comprehensive)"
    echo "  sslyze          - SSL/TLS configuration analyzer"
    echo "  dirb            - Directory brute-forcer"
    echo "  gobuster        - Directory/DNS brute-forcer"
    echo "  zap-baseline    - ZAP baseline scan (passive, ~1 min)"
    echo "  zap-full        - ZAP full scan (active, longer)"
    echo "  zap-full-gentle - ZAP full scan with rate limiting (prod-safe)"
    echo "  zap-api         - ZAP API scan (for OpenAPI/GraphQL)"
    echo "  shell           - Interactive bash shell"
    echo "  check           - Verify all tools are installed correctly"
    echo ""
    echo "Examples:"
    echo "  docker run --rm -v ./output:/output security-scanning nikto https://example.com"
    echo "  docker run --rm -v ./output:/output security-scanning nmap example.com -p 80,443"
    echo "  docker run --rm -v ./output:/output security-scanning zap-baseline https://example.com"
    echo "  docker run --rm -it -v ./output:/output security-scanning shell"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

TOOL="$1"
shift

case "$TOOL" in
    nikto)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: nikto <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        OUTPUT_FILE="/output/nikto_${TIMESTAMP}.html"
        echo -e "${GREEN}Running Nikto scan against: $TARGET${NC}"
        nikto -h "$TARGET" -o "$OUTPUT_FILE" -Format htm "$@"
        echo -e "${GREEN}Report saved to: nikto_${TIMESTAMP}.html${NC}"
        ;;

    zap-baseline)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: zap-baseline <target-url>"
            exit 1
        fi
        TARGET="$1"
        REPORT="zap_baseline_${TIMESTAMP}.html"
        YAML_FILE="/tmp/.zap_scan_${TIMESTAMP}.yaml"
        cat > "$YAML_FILE" << EOF
env:
  contexts:
  - name: baseline
    urls:
    - $TARGET
  parameters:
    failOnError: false
    progressToStdout: true
jobs:
- type: passiveScan-config
  parameters:
    maxAlertsPerRule: 10
- type: spider
  parameters:
    maxDuration: 2
    maxDepth: 10
    url: $TARGET
- type: passiveScan-wait
- type: report
  parameters:
    template: traditional-html
    reportDir: /output
    reportFile: $REPORT
    reportTitle: ZAP Baseline Scan
EOF
        echo -e "${GREEN}Running ZAP baseline scan against: $TARGET${NC}"
        /usr/share/zaproxy/zap.sh -Xmx10g -daemon -autorun "$YAML_FILE"
        rm -f "$YAML_FILE"
        echo -e "${GREEN}Report saved to: $REPORT${NC}"
        ;;

    zap-full)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: zap-full <target-url>"
            exit 1
        fi
        TARGET="$1"
        REPORT="zap_full_${TIMESTAMP}.html"
        YAML_FILE="/tmp/.zap_scan_${TIMESTAMP}.yaml"
        cat > "$YAML_FILE" << EOF
env:
  contexts:
  - name: full-scan
    urls:
    - $TARGET
  parameters:
    failOnError: false
    progressToStdout: true
jobs:
- type: passiveScan-config
  parameters:
    maxAlertsPerRule: 10
- type: spider
  parameters:
    maxDuration: 5
    url: $TARGET
- type: passiveScan-wait
- type: activeScan
  parameters:
    maxRuleDurationInMins: 5
    maxScanDurationInMins: 60
- type: report
  parameters:
    template: traditional-html
    reportDir: /output
    reportFile: $REPORT
    reportTitle: ZAP Full Scan
EOF
        echo -e "${GREEN}Running ZAP full scan against: $TARGET${NC}"
        echo -e "${YELLOW}Warning: Full scan performs active attacks and may take a long time${NC}"
        /usr/share/zaproxy/zap.sh -Xmx10g -daemon -autorun "$YAML_FILE"
        rm -f "$YAML_FILE"
        echo -e "${GREEN}Report saved to: $REPORT${NC}"
        ;;

    zap-full-gentle)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: zap-full-gentle <target-url>"
            exit 1
        fi
        TARGET="$1"
        REPORT="zap_full_gentle_${TIMESTAMP}.html"
        YAML_FILE="/tmp/.zap_scan_${TIMESTAMP}.yaml"
        cat > "$YAML_FILE" << EOF
env:
  contexts:
  - name: full-scan-gentle
    urls:
    - $TARGET
    excludePaths:
    - ".*[?&](session|sid|token|timestamp|ts|_|rand|cache|v)=.*"
    - ".*/(page|p)/[0-9]+$"
    - ".*/calendar/[0-9]{4}/[0-9]{2}.*"
  parameters:
    failOnError: false
    progressToStdout: true
jobs:
- type: passiveScan-config
  parameters:
    maxAlertsPerRule: 10
- type: spider
  parameters:
    maxDuration: 2
    maxDepth: 3
    maxChildren: 5
    url: $TARGET
- type: passiveScan-wait
- type: activeScan
  parameters:
    maxRuleDurationInMins: 3
    maxScanDurationInMins: 30
    threadPerHost: 1
    delayInMs: 1000
    maxAlertsPerRule: 3
- type: report
  parameters:
    template: traditional-html
    reportDir: /output
    reportFile: $REPORT
    reportTitle: ZAP Full Scan (Gentle)
EOF
        echo -e "${GREEN}Running ZAP full scan (gentle mode) against: $TARGET${NC}"
        echo -e "${YELLOW}Rate limited: 1 thread, 1s delay, shallow crawl (depth 3)${NC}"
        /usr/share/zaproxy/zap.sh -Xmx10g -daemon -autorun "$YAML_FILE"
        rm -f "$YAML_FILE"
        echo -e "${GREEN}Report saved to: $REPORT${NC}"
        ;;

    zap-api)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: API definition URL required${NC}"
            echo "Usage: zap-api <openapi-url>"
            exit 1
        fi
        TARGET="$1"
        REPORT="zap_api_${TIMESTAMP}.html"
        YAML_FILE="/tmp/.zap_scan_${TIMESTAMP}.yaml"
        cat > "$YAML_FILE" << EOF
env:
  contexts:
  - name: api-scan
    urls:
    - $TARGET
  parameters:
    failOnError: false
    progressToStdout: true
jobs:
- type: openapi
  parameters:
    apiUrl: $TARGET
- type: passiveScan-wait
- type: activeScan
  parameters:
    maxRuleDurationInMins: 5
    maxScanDurationInMins: 30
- type: report
  parameters:
    template: traditional-html
    reportDir: /output
    reportFile: $REPORT
    reportTitle: ZAP API Scan
EOF
        echo -e "${GREEN}Running ZAP API scan against: $TARGET${NC}"
        /usr/share/zaproxy/zap.sh -Xmx10g -daemon -autorun "$YAML_FILE"
        rm -f "$YAML_FILE"
        echo -e "${GREEN}Report saved to: $REPORT${NC}"
        ;;

    sqlmap)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: sqlmap <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running SQLMap against: $TARGET${NC}"
        sqlmap -u "$TARGET" --batch --output-dir="/output/sqlmap_${TIMESTAMP}" "$@"
        ;;

    nmap)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target required${NC}"
            echo "Usage: nmap <target> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running Nmap scan against: $TARGET${NC}"
        nmap "$TARGET" -oA "/output/nmap_${TIMESTAMP}" "$@"
        echo -e "${GREEN}Reports saved to: nmap_${TIMESTAMP}.*${NC}"
        ;;

    wapiti)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: wapiti <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running Wapiti scan against: $TARGET${NC}"
        echo -e "${YELLOW}Limiting crawl: depth=3, max-links=100${NC}"
        wapiti -u "$TARGET" -o "/output/wapiti_${TIMESTAMP}.html" -f html --max-depth 3 --max-links-per-page 10 --max-scan-time 600 "$@"
        echo -e "${GREEN}Report saved to: wapiti_${TIMESTAMP}.html${NC}"
        ;;

    wapiti-gentle)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: wapiti-gentle <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running Wapiti scan (gentle mode) against: $TARGET${NC}"
        echo -e "${YELLOW}Rate limited: 1 req/sec, depth=3, 10 min timeout${NC}"
        wapiti -u "$TARGET" -o "/output/wapiti_gentle_${TIMESTAMP}.html" -f html --max-depth 3 --max-links-per-page 10 --max-scan-time 600 --delay 1 "$@"
        echo -e "${GREEN}Report saved to: wapiti_gentle_${TIMESTAMP}.html${NC}"
        ;;

    whatweb)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: whatweb <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running WhatWeb against: $TARGET${NC}"
        whatweb "$TARGET" --log-json="/output/whatweb_${TIMESTAMP}.json" "$@"
        echo -e "${GREEN}Report saved to: whatweb_${TIMESTAMP}.json${NC}"
        ;;

    wafw00f)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: wafw00f <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running wafw00f against: $TARGET${NC}"
        wafw00f "$TARGET" -o "/output/wafw00f_${TIMESTAMP}.txt" "$@"
        echo -e "${GREEN}Report saved to: wafw00f_${TIMESTAMP}.txt${NC}"
        ;;

    sslscan)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target required${NC}"
            echo "Usage: sslscan <host:port>"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running SSLScan against: $TARGET${NC}"
        sslscan "$TARGET" "$@" | tee "/output/sslscan_${TIMESTAMP}.txt"
        echo -e "${GREEN}Report saved to: sslscan_${TIMESTAMP}.txt${NC}"
        ;;

    testssl)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target required${NC}"
            echo "Usage: testssl <host:port>"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running testssl against: $TARGET${NC}"
        testssl --htmlfile "/output/testssl_${TIMESTAMP}.html" "$@" "$TARGET"
        echo -e "${GREEN}Report saved to: testssl_${TIMESTAMP}.html${NC}"
        ;;

    sslyze)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target required${NC}"
            echo "Usage: sslyze <host:port>"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running SSLyze against: $TARGET${NC}"
        sslyze --json_out="/output/sslyze_${TIMESTAMP}.json" "$@" "$TARGET" | tee "/output/sslyze_${TIMESTAMP}.txt"
        echo -e "${GREEN}Reports saved to: sslyze_${TIMESTAMP}.json and sslyze_${TIMESTAMP}.txt${NC}"
        ;;

    dirb)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: dirb <target-url> [wordlist]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running Dirb against: $TARGET${NC}"
        dirb "$TARGET" "$@" -o "/output/dirb_${TIMESTAMP}.txt"
        echo -e "${GREEN}Report saved to: dirb_${TIMESTAMP}.txt${NC}"
        ;;

    gobuster)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Target URL required${NC}"
            echo "Usage: gobuster <target-url> [options]"
            exit 1
        fi
        TARGET="$1"
        shift
        echo -e "${GREEN}Running Gobuster against: $TARGET${NC}"
        gobuster dir -u "$TARGET" -w /usr/share/seclists/Discovery/Web-Content/common.txt -o "/output/gobuster_${TIMESTAMP}.txt" "$@"
        echo -e "${GREEN}Report saved to: gobuster_${TIMESTAMP}.txt${NC}"
        ;;

    shell)
        echo -e "${GREEN}Starting interactive shell...${NC}"
        exec /bin/bash
        ;;

    check)
        echo -e "${GREEN}Checking all security tools...${NC}"
        echo ""
        FAILED=0

        check_tool() {
            local name="$1"
            local cmd="$2"
            if eval "$cmd" > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $name"
            else
                echo -e "  ${RED}✗${NC} $name"
                FAILED=1
            fi
        }

        check_tool "nikto" "nikto -Version"
        check_tool "nmap" "nmap --version"
        check_tool "wafw00f" "wafw00f --version"
        check_tool "sqlmap" "sqlmap --version"
        check_tool "wapiti" "wapiti --version"
        check_tool "whatweb" "whatweb --version"
        check_tool "sslscan" "sslscan --version"
        check_tool "dirb" "which dirb"
        check_tool "gobuster" "gobuster help"
        check_tool "zap" "test -x /usr/share/zaproxy/zap.sh"
        check_tool "testssl" "which testssl"
        check_tool "sslyze" "which sslyze"
        check_tool "wafw00f" "wafw00f --version"

        echo ""
        if [ $FAILED -eq 0 ]; then
            echo -e "${GREEN}All tools are installed correctly!${NC}"
        else
            echo -e "${RED}Some tools are missing or broken.${NC}"
            exit 1
        fi
        ;;

    *)
        echo -e "${RED}Unknown tool: $TOOL${NC}"
        usage
        ;;
esac
