# 🎬 Media Server

Stack de médias auto-hébergée tournant sous Docker, avec VPN intégré via Gluetun. Elle permet de télécharger, indexer et streamer des contenus de manière automatisée et sécurisée.

## 📦 Services inclus

| Service | Description | Port |
|---|---|---|
| [Gluetun](https://github.com/qdm12/gluetun) | Conteneur VPN (killswitch réseau pour les autres services) | — |
| [Jellyfin](https://jellyfin.org/) | Serveur de streaming multimédia | `8096` |
| [qBittorrent](https://www.qbittorrent.org/) | Client torrent (via VPN) | `8085` |
| [Jackett](https://github.com/Jackett/Jackett) | Proxy d'indexeurs de torrents | `9117` |
| [Sonarr](https://sonarr.tv/) | Gestionnaire automatique de séries TV | `8989` |
| [Prowlarr](https://prowlarr.com/) | Gestionnaire centralisé d'indexeurs | `9696` |

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│                   Gluetun (VPN)              │
│  ┌────────────┐  ┌────────┐  ┌───────────┐  │
│  │ qBittorrent│  │Jackett │  │  Sonarr   │  │
│  └────────────┘  └────────┘  └───────────┘  │
│                              ┌───────────┐  │
│                              │ Prowlarr  │  │
│                              └───────────┘  │
└──────────────────────────────────────────────┘
          ↕ réseau direct (hors VPN)
┌──────────────────────────────────────────────┐
│                  Jellyfin                    │
└──────────────────────────────────────────────┘
```

qBittorrent, Jackett, Sonarr et Prowlarr passent **intégralement par le VPN** Gluetun. Jellyfin est accessible directement sur le réseau local.

## ⚙️ Configuration

### Prérequis

- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
- Un abonnement VPN compatible Gluetun

### Variables d'environnement

Crée un fichier `.env` à la racine du projet avec les variables suivantes :

```env
VPN_SERVICE_PROVIDER=your_vpn_provider   # ex: nordvpn, cyberghostvpn
VPN_TYPE=openvpn                         # openvpn ou wireguard
OPENVPN_USER=your_vpn_username
OPENVPN_PASSWORD=your_vpn_password
SERVER_COUNTRIES=France                  # pays du serveur VPN
```

> Pour Wireguard, décommente les lignes correspondantes dans le `docker-compose.yml` et renseigne ta clé privée.

### Volumes & chemins

Les chemins suivants sont utilisés pour les médias (à adapter selon ta machine) :

```
~/medias/movies     → Films (Jellyfin + qBittorrent)
~/medias/tvseries   → Séries TV (Jellyfin)
```

## 🚀 Démarrage

```bash
# Cloner le repo
git clone https://github.com/nahugondev/media-server.git
cd media-server

# Créer le fichier .env (voir section Configuration)
cp .env.example .env

# Lancer la stack
docker compose up -d
```

## 🌐 Accès aux interfaces

Une fois la stack démarrée :

| Interface | URL |
|---|---|
| Jellyfin | http://localhost:8096 |
| qBittorrent | http://localhost:8085 |
| Jackett | http://localhost:9117 |
| Sonarr | http://localhost:8989 |
| Prowlarr | http://localhost:9696 |

## 📁 Structure des dossiers

```
media-server/
├── docker-compose.yml
├── .env                  # Variables d'environnement (à créer)
├── gluetun/              # Config & données Gluetun
├── jellyfin/
│   ├── data/             # Config Jellyfin
│   └── cache/
├── qbittorrent/          # Config qBittorrent
├── jackett/data/         # Config Jackett
├── sonarr/data/          # Config Sonarr
├── prowlarr/data/        # Config Prowlarr
└── downloads/            # Dossier de téléchargements temporaires
```

## 🔒 Sécurité

Tous les services de téléchargement (qBittorrent, Jackett, Sonarr, Prowlarr) sont routés via Gluetun. Si le VPN tombe, le trafic est coupé automatiquement (killswitch).

## 🔜 Améliorations prévues

L'objectif est de faire passer tout le trafic par un reverse proxy comme Traefik afin de sécuriser les accès et d'exposer chaque service sur son propre sous-domaine.