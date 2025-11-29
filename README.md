# Script de Configuration Réseau - Srv01-farah

## 📋 Description

Script Bash automatisé pour configurer de manière définitive les interfaces réseau d'un serveur Debian 13 avec systemd-networkd. Ce script configure trois interfaces réseau selon une topologie définie, avec activation automatique au démarrage.

## 🎯 Objectif

Configurer automatiquement les interfaces réseau du serveur avec :
- **ens33** : Interface DHCP/NAT pour connexion externe (SSH + Internet)
- **ens37** : Interface LAN1 avec IP statique (192.168.10.254/24)
- **ens38** : Interface LAN2 avec IP statique (172.16.20.254/24)

## ⚙️ Configuration Appliquée

| Interface | Type | Adresse IP | Réseau | Rôle |
|-----------|------|------------|---------|------|
| ens33 | DHCP | Automatique | NAT | Connexion externe |
| ens37 | Statique | 192.168.10.254/24 | LAN1 | Réseau local 1 |
| ens38 | Statique | 172.16.20.254/24 | LAN2 | Réseau local 2 |

## 🔧 Prérequis

- **Système** : Debian 13 (ou supérieur)
- **Permissions** : Accès root (sudo)
- **Services** : systemd-networkd installé
- **Réseau** : Trois interfaces réseau disponibles (ens33, ens37, ens38)

## 📥 Installation

1. Télécharger le script :
```bash
wget <URL_du_script> -O configure_network.sh
```

2. Rendre le script exécutable :
```bash
chmod +x configure_network.sh
```

## 🚀 Utilisation

### Exécution Standard
```bash
sudo ./configure_network.sh
```

Le script vous demandera confirmation avant d'appliquer les modifications.

### Processus d'Exécution

1. Vérification des permissions root
2. Affichage de la configuration à appliquer
3. Demande de confirmation utilisateur
4. Sauvegarde de la configuration actuelle
5. Suppression des anciennes configurations
6. Création des nouveaux fichiers de configuration
7. Activation des interfaces réseau
8. Activation de systemd-networkd
9. Redémarrage du service réseau
10. Vérification et affichage de l'état final

## 📁 Fichiers Créés

Le script crée trois fichiers de configuration dans `/etc/systemd/network/` :

### 1. `/etc/systemd/network/05-nat.network`
```ini
[Match]
Name=ens33

[Network]
DHCP=yes

[DHCP]
UseDNS=false
```

### 2. `/etc/systemd/network/10-lan1.network`
```ini
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
```

### 3. `/etc/systemd/network/20-lan2.network`
```ini
[Match]
Name=ens38

[Link]
RequiredForOnline=no

[Network]
Address=172.16.20.254/24
Gateway=172.16.20.1
ConfigureWithoutCarrier=yes
```

## 🔍 Caractéristiques Importantes

### ✅ Activation Automatique au Boot

Les interfaces ens37 et ens38 utilisent le paramètre `ConfigureWithoutCarrier=yes`, ce qui permet :
- Configuration de l'interface même sans câble réseau branché
- Activation automatique au démarrage du système
- Pas besoin de commandes manuelles après un reboot

### 🔒 Sécurité

- Sauvegarde automatique de la configuration existante
- Confirmation requise avant toute modification
- Vérification des permissions root
- Historique des sauvegardes horodatées

## 🧪 Tests Après Configuration

Une fois le script exécuté, testez la connectivité :
```bash
# Test LAN1
ping -c 4 192.168.10.1

# Test LAN2
ping -c 4 172.16.20.1

# Test Internet
ping -c 4 8.8.8.8

# Vérifier l'état des interfaces
networkctl list

# Afficher les adresses IP
ip -br addr show

# Afficher les routes
ip route show
```

## 🔄 Restauration

En cas de problème, restaurez la configuration précédente :
```bash
# Localiser la sauvegarde
ls -ld /root/backup-network-*

# Restaurer (remplacer DATE par la date de sauvegarde)
sudo cp -r /root/backup-network-DATE/network/* /etc/systemd/network/
sudo systemctl restart systemd-networkd
```

## 🛠️ Dépannage

### Les interfaces ne s'activent pas
```bash
# Vérifier l'état de systemd-networkd
sudo systemctl status systemd-networkd

# Redémarrer le service
sudo systemctl restart systemd-networkd

# Vérifier les logs
sudo journalctl -u systemd-networkd -n 50
```

### Pas d'adresse IP sur une interface
```bash
# Vérifier la configuration
cat /etc/systemd/network/*.network

# Forcer l'activation
sudo ip link set ens37 up
sudo ip link set ens38 up

# Recharger networkd
sudo networkctl reload
```

### Conflit avec l'ancien système de réseau
```bash
# Désactiver networking traditionnel
sudo systemctl disable networking
sudo systemctl stop networking

# Activer systemd-networkd
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
```

## 📊 Vérification de l'État du Réseau

### Commandes Utiles
```bash
# État général
networkctl status

# État d'une interface spécifique
networkctl status ens37

# Liste toutes les interfaces
networkctl list

# Adresses IP de toutes les interfaces
ip -br addr show

# Table de routage
ip route show

# Statistiques réseau
ip -s link show ens37
```

## 🔐 Sécurité et Bonnes Pratiques

1. **Toujours tester** dans un environnement de test avant la production
2. **Sauvegarder** la configuration avant toute modification
3. **Documenter** les changements effectués
4. **Vérifier** la connectivité après chaque modification
5. **Planifier** une fenêtre de maintenance pour l'application

## 📝 Notes Importantes

- Ce script utilise **systemd-networkd**, pas le système traditionnel `/etc/network/interfaces`
- Les configurations sont persistantes après redémarrage
- Le paramètre `ConfigureWithoutCarrier=yes` est crucial pour l'activation automatique
- Les sauvegardes sont horodatées et stockées dans `/root/backup-network-*/`

## 🆘 Support et Contact

Pour toute question ou problème :
- Vérifiez les logs : `journalctl -u systemd-networkd`
- Consultez la documentation Debian : `man systemd.network`
- Revoyez la configuration : `cat /etc/systemd/network/*.network`

## 📜 Licence

Script créé pour un usage éducatif et administratif.

## 📌 Version

- **Version** : 1.0 (Configuration Finale et Définitive)
- **Date** : 2025
- **Système cible** : Debian 13
- **Serveur** : Srv01-farah

---

**⚠️ Avertissement** : L'exécution de ce script modifiera la configuration réseau de votre système. Assurez-vous d'avoir un accès physique ou console en cas de perte de connectivité SSH.
