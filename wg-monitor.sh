#!/bin/bash

TOTAL=0
OK_COUNT=0
WARN_COUNT=0
OFFLINE_COUNT=0
NEVER_COUNT=0


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WG_IF="wg0"
NOW=$(date +%s)

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

echo " "
echo -e  "${RED}[WireGuard Status]${NC}"
echo "------------------------------------------------------"

sudo wg show "$WG_IF" dump | tail -n +2 | while IFS=$'\t' read -r public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive
do
    IP=$(echo "$allowed_ips" | cut -d'/' -f1)
    NAME=${PEERS[$IP]:-"Unbekannt"}

if [ "$latest_handshake" -eq 0 ]; then
    RX_TEXT=$(numfmt --to=iec --suffix=B "$transfer_rx")
    TX_TEXT=$(numfmt --to=iec --suffix=B "$transfer_tx")

    echo -e "${RED}[OFFLINE]${NC} $NAME ($IP) - noch kein Handshake | gesendet: $RX_TEXT | erhalten: $TX_TEXT"
    echo "---------------------------------------------------"
    echo
    continue
fi
AGE=$((NOW - latest_handshake))

RX_TEXT=$(numfmt --to=iec --suffix=B "$transfer_rx")
TX_TEXT=$(numfmt --to=iec --suffix=B "$transfer_tx")

if [ "$AGE" -lt 300 ]; then
    STATUS="OK"
elif [ "$AGE" -lt 3600 ]; then
    STATUS="WARN"
else
    STATUS="OFFLINE"
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
    echo -e "${GREEN}[OK]${NC} $NAME ($IP) - letzter Handshake vor $AGE_TEXT | gesendet: $RX_TEXT | erhalten: $TX_TEXT"
elif [ "$STATUS" = "WARN" ]; then
    echo -e "${YELLOW}[WARN]${NC} $NAME ($IP) - letzter Handshake vor $AGE_TEXT | gesendet: $RX_TEXT | erhalten: $TX_TEXT"
else
    echo -e "${RED}[OFFLINE]${NC} $NAME ($IP) - letzter Handshake vor $AGE_TEXT | gesendet: $RX_TEXT | erhalten: $TX_TEXT"
fi

echo "---------------------------------------------------------- "
echo
done
