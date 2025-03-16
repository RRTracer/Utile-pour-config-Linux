#!/bin/bash
set -euo pipefail

# Configuration réseau
WIFI_IFACE="wlo1"        # Interface connectée à Internet (Wi-Fi)
ETH_IFACE="enp4s0"       # Interface vers le réseau local (Ethernet)
SUBNET="192.168.50.0"
RANGE_START="192.168.50.100"
RANGE_END="192.168.50.200"
NETMASK="24"             # Format CIDR (/24)
GATEWAY="192.168.50.1"

# Fichier PID pour dnsmasq
DNSMASQ_PID="/var/run/dnsmasq_nat.pid"

# Fonction de log
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

start_nat() {
  log "Démarrage du partage de connexion NAT & DHCP..."

  # Activation de l'IP forwarding
  sysctl -w net.ipv4.ip_forward=1 >/dev/null
  
  # Configuration de l'interface Ethernet
  ip link set "$ETH_IFACE" up
  ip addr flush dev "$ETH_IFACE"
  ip addr add "$GATEWAY/$NETMASK" dev "$ETH_IFACE"
  
  # Mise en place des règles iptables pour NAT
  if ! iptables -t nat -C POSTROUTING -o "$WIFI_IFACE" -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o "$WIFI_IFACE" -j MASQUERADE
  fi
  if ! iptables -C FORWARD -i "$WIFI_IFACE" -o "$ETH_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; then
    iptables -A FORWARD -i "$WIFI_IFACE" -o "$ETH_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
  fi
  if ! iptables -C FORWARD -i "$ETH_IFACE" -o "$WIFI_IFACE" -j ACCEPT 2>/dev/null; then
    iptables -A FORWARD -i "$ETH_IFACE" -o "$WIFI_IFACE" -j ACCEPT
  fi
  
  # Démarrage de dnsmasq pour fournir le DHCP
  if [ -f "$DNSMASQ_PID" ]; then
    kill "$(cat $DNSMASQ_PID)" 2>/dev/null || true
    rm -f "$DNSMASQ_PID"
  fi

  dnsmasq --interface="$ETH_IFACE" \
          --bind-interfaces \
          --except-interface=lo \
          --dhcp-range="$RANGE_START","$RANGE_END",12h \
          --dhcp-option=3,"$GATEWAY" \
          --dhcp-option=6,8.8.8.8 \
          --pid-file="$DNSMASQ_PID" \
          --log-facility=- >/dev/null 2>&1 &
  
  sleep 1
  if ! ps -p "$(cat "$DNSMASQ_PID")" >/dev/null 2>&1; then
    log "ERROR: dnsmasq n'a pas pu démarrer"
    exit 1
  fi
  log "Partage de connexion démarré avec succès."
}

stop_nat() {
  log "Arrêt du partage de connexion NAT & DHCP..."

  # Arrêt de dnsmasq
  if [ -f "$DNSMASQ_PID" ]; then
    kill "$(cat "$DNSMASQ_PID")" && rm -f "$DNSMASQ_PID"
  fi
  
  # Suppression des règles iptables
  iptables -t nat -D POSTROUTING -o "$WIFI_IFACE" -j MASQUERADE 2>/dev/null || true
  iptables -D FORWARD -i "$WIFI_IFACE" -o "$ETH_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -i "$ETH_IFACE" -o "$WIFI_IFACE" -j ACCEPT 2>/dev/null || true
  
  # Désactivation de l'IP forwarding
  sysctl -w net.ipv4.ip_forward=0 >/dev/null
  
  # Nettoyage de l'interface Ethernet
  ip addr flush dev "$ETH_IFACE"
  
  log "Partage de connexion arrêté."
}

case "${1:-}" in
  start)
    start_nat
    ;;
  stop)
    stop_nat
    ;;
  restart)
    stop_nat
    sleep 1
    start_nat
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac
