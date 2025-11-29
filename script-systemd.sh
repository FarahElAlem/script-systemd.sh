#!/bin/bash
###############################################################################
# Configuration FINALE et DÉFINITIVE selon schéma
# Avec activation automatique des interfaces au boot
# ens33 : DHCP/NAT
# ens37 : LAN1 (192.168.10.254)
# ens38 : LAN2 (172.16.20.254)
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Configuration DÉFINITIVE - Srv01-farah                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Erreur : exécuter en root"
    exit 1
fi

echo "📋 Configuration à appliquer :"
echo ""
echo "  ens33 : DHCP/NAT (connexion externe)"
echo "  ens37 : 192.168.10.254/24 (LAN1)"
echo "  ens38 : 172.16.20.254/24 (LAN2)"
echo ""
echo "  ✅ Activation automatique au boot"
echo "  ✅ Interfaces configurées même sans câble"
echo ""

read -p "Appliquer cette configuration ? (oui/non) : " confirm

if [ "$confirm" != "oui" ]; then
    echo "❌ Annulé"
    exit 0
fi

echo ""
echo "1. Sauvegarde de la configuration actuelle..."
mkdir -p /root/backup-network-$(date +%Y%m%d-%H%M%S)
cp -r /etc/systemd/network /root/backup-network-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
echo "   ✓ Sauvegarde OK"

echo ""
echo "2. Suppression des anciennes configurations..."
rm -f /etc/systemd/network/*.network
echo "   ✓ Anciennes configs supprimées"

echo ""
echo "3. Création des nouvelles configurations..."

mkdir -p /etc/systemd/network

# ================================================================
# ens33 : DHCP/NAT
# ================================================================
cat > /etc/systemd/network/05-nat.network << 'EOF'
# Srv01-farah - Interface NAT/DHCP
# Connexion externe pour SSH et Internet

[Match]
Name=ens33

[Network]
DHCP=yes

[DHCP]
UseDNS=false
EOF

chmod 644 /etc/systemd/network/05-nat.network
echo "   ✓ ens33 : DHCP/NAT"

# ================================================================
# ens37 : LAN1 - AVEC ACTIVATION AUTOMATIQUE
# ================================================================
cat > /etc/systemd/network/10-lan1.network << 'EOF'
# Srv01-farah - LAN1
# Réseau 192.168.10.0/24
# Activation automatique au boot

[Match]
Name=ens37

[Link]
RequiredForOnline=no

[Network]
Address=192.168.10.254/24
Gateway=192.168.10.1
DNS=192.168.10.254
DNS=8.8.8.8
ConfigureWithoutCarrier=yes
EOF

chmod 644 /etc/systemd/network/10-lan1.network
echo "   ✓ ens37 : 192.168.10.254/24 (LAN1) - Activation auto ✅"

# ================================================================
# ens38 : LAN2 - AVEC ACTIVATION AUTOMATIQUE
# ================================================================
cat > /etc/systemd/network/20-lan2.network << 'EOF'
# Srv01-farah - LAN2
# Réseau 172.16.20.0/24
# Activation automatique au boot

[Match]
Name=ens38

[Link]
RequiredForOnline=no

[Network]
Address=172.16.20.254/24
Gateway=172.16.20.1
ConfigureWithoutCarrier=yes
EOF

chmod 644 /etc/systemd/network/20-lan2.network
echo "   ✓ ens38 : 172.16.20.254/24 (LAN2) - Activation auto ✅"

echo ""
echo "4. Activation physique des interfaces..."
ip link set ens37 up 2>/dev/null || echo "   ⚠ ens37 déjà UP ou erreur"
ip link set ens38 up 2>/dev/null || echo "   ⚠ ens38 déjà UP ou erreur"
echo "   ✓ Interfaces activées"

echo ""
echo "5. Activation de systemd-networkd (si pas déjà fait)..."
systemctl enable systemd-networkd 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true
echo "   ✓ Services activés au boot"

echo ""
echo "6. Désactivation de networking (si présent)..."
systemctl disable networking 2>/dev/null || true
echo "   ✓ Ancien système désactivé"

echo ""
echo "7. Redémarrage de systemd-networkd..."
systemctl restart systemd-networkd
sleep 5

echo ""
echo "8. Vérification de la configuration..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "État des interfaces :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
networkctl list | grep -E "(ens33|ens37|ens38|IDX)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Adresses IP :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ip -br addr show | grep -E "(ens33|ens37|ens38)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Routes :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ip route show | grep -E "(default|192.168.10|172.16.20)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fichiers de configuration créés :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh /etc/systemd/network/*.network

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              ✅ CONFIGURATION TERMINÉE !                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration appliquée :"
echo "  • ens33 : DHCP/NAT (connexion externe)"
echo "  • ens37 : 192.168.10.254/24 (LAN1) ✅ AUTO"
echo "  • ens38 : 172.16.20.254/24 (LAN2) ✅ AUTO"
echo ""
echo "✅ Les interfaces ens37 et ens38 seront activées automatiquement"
echo "   au prochain redémarrage !"
echo ""
echo "Tests recommandés :"
echo "  ping 192.168.10.1      # Gateway LAN1"
echo "  ping 172.16.20.1       # Gateway LAN2"
echo "  ping 8.8.8.8           # Internet via ens33"
echo ""
echo "Pour tester le redémarrage :"
echo "  sudo reboot"
echo ""
echo "Sauvegarde disponible dans :"
echo "  /root/backup-network-$(date +%Y%m%d)*/"
echo ""
