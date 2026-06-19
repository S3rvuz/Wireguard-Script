#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

WG_IF="wg0"
NOW=$(date +%s)

TOTAL=0
OK_COUNT=0
WARN_COUNT=0
OFFLINE_COUNT=0
NEVER_COUNT=0
TOTAL_RX=0
TOTAL_TX=0

OK_LIST=""
WARN_LIST=""
OFFLINE_LIST=""
NEVER_LIST=""

declare -A PEERS
PEERS["10.10.10.2"]="Iphone 16 von Marvin"
PEERS["10.10.10.3"]="Ubuntu-Client"
PEERS["10.10.10.4"]="Handy von Andrea"
PEERS["10.10.10.5"]="Marvin Win Laptop"
PEERS["10.10.10.6"]="Laptop"
PEERS["10.10.10.7"]="Jason Arbeitslaptop"
PEERS["10.10.10.8"]="Jonathan Arbeitslaptop"
PEERS["10.10.10.9"]="Jason Home-Rechner"
PEERS["10.10.10.10"]="Test10"
PEERS["10.10.10.11"]="Marvin Tablet"

while IFS=$'\t' read -r public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive
do
    IP=$(echo "$allowed_ips" | cut -d'/' -f1)
    NAME=${PEERS[$IP]:-"Unbekannt"}
if ping -c 1 -W 1 "$IP" > /dev/null 2>&1; then
    PING_STATUS="${GREEN}OK${NC}"
else
    PING_STATUS="${RED}FAIL${NC}"
fi

    TOTAL=$((TOTAL + 1))
    TOTAL_RX=$((TOTAL_RX + transfer_rx))
    TOTAL_TX=$((TOTAL_TX + transfer_tx))

    RX_TEXT=$(numfmt --to=iec --suffix=B "$transfer_rx")
    TX_TEXT=$(numfmt --to=iec --suffix=B "$transfer_tx")

    if [ -z "$endpoint" ]; then
        ENDPOINT_TEXT="kein Endpoint"
    else
        ENDPOINT_TEXT="$endpoint"
    fi

    if [ "$latest_handshake" -eq 0 ]; then
        NEVER_COUNT=$((NEVER_COUNT + 1))

        ENTRY=$(cat <<EOF
${RED}[NEVER]${NC} $NAME
VPN-IP: $IP
Endpoint: $ENDPOINT_TEXT
Handshake: noch nie verbunden
Traffic: gesendet: $RX_TEXT | erhalten: $TX_TEXT
----------------------------------------------------------
EOF
)
        NEVER_LIST="${NEVER_LIST}${ENTRY}"$'\n'
        continue
    fi

    AGE=$((NOW - latest_handshake))

    if [ "$AGE" -lt 300 ]; then
        STATUS="OK"
        OK_COUNT=$((OK_COUNT + 1))
    elif [ "$AGE" -lt 3600 ]; then
        STATUS="WARN"
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        STATUS="OFFLINE"
        OFFLINE_COUNT=$((OFFLINE_COUNT + 1))
    fi

    if [ "$AGE" -lt 60 ]; then
        AGE_TEXT="${AGE}s"
    elif [ "$AGE" -lt 3600 ]; then
        AGE_TEXT="$((AGE / 60))min"
    elif [ "$AGE" -lt 86400 ]; then
        AGE_TEXT="$((AGE / 3600))h"
    else
        AGE_TEXT="$((AGE / 86400))d"
    fi

    if [ "$STATUS" = "OK" ]; then
        ENTRY=$(cat <<EOF
${GREEN}[OK]${NC} $NAME
VPN-IP: $IP
Endpoint: $ENDPOINT_TEXT
Handshake: vor $AGE_TEXT
VPN-Ping: $PING_STATUS
Traffic: gesendet: $RX_TEXT | erhalten: $TX_TEXT
----------------------------------------------------------
EOF
)
        OK_LIST="${OK_LIST}${ENTRY}"$'\n'

    elif [ "$STATUS" = "WARN" ]; then
        ENTRY=$(cat <<EOF
${YELLOW}[WARN]${NC} $NAME
VPN-IP: $IP
Endpoint: $ENDPOINT_TEXT
Handshake: vor $AGE_TEXT
VPN-Ping: $PING_STATUS
Traffic: gesendet: $RX_TEXT | erhalten: $TX_TEXT
----------------------------------------------------------
EOF
)
        WARN_LIST="${WARN_LIST}${ENTRY}"$'\n'

    else
        ENTRY=$(cat <<EOF
${RED}[OFFLINE]${NC} $NAME
VPN-IP: $IP
Endpoint: $ENDPOINT_TEXT
Handshake: vor $AGE_TEXT
Traffic: gesendet: $RX_TEXT | erhalten: $TX_TEXT
----------------------------------------------------------
EOF
)
        OFFLINE_LIST="${OFFLINE_LIST}${ENTRY}"$'\n'
    fi

done < <(sudo wg show "$WG_IF" dump | tail -n +2)

TOTAL_RX_TEXT=$(numfmt --to=iec --suffix=B "$TOTAL_RX")
TOTAL_TX_TEXT=$(numfmt --to=iec --suffix=B "$TOTAL_TX")

echo
echo -e "${RED}[WireGuard Status]${NC}"
echo "----------------------------------------------------------"
echo "Clients: $TOTAL"
echo -e "${GREEN}OK:${NC} $OK_COUNT"
echo -e "${YELLOW}WARN:${NC} $WARN_COUNT"
echo -e "${RED}OFFLINE:${NC} $OFFLINE_COUNT"
echo -e "${GRAY}NEVER:${NC} $NEVER_COUNT"
echo
echo "Gesamt gesendet: $TOTAL_RX_TEXT"
echo "Gesamt erhalten: $TOTAL_TX_TEXT"
echo "----------------------------------------------------------"
echo

echo -e "$OK_LIST"
echo -e "$WARN_LIST"
echo -e "$OFFLINE_LIST"
echo -e "$NEVER_LIST"
