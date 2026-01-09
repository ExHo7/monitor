# Stack de Monitoring Proxmox avec Grafana + Prometheus

Stack complète de monitoring pour serveur Proxmox VE utilisant Docker Compose, Grafana et Prometheus.

## Composants

- **Prometheus** : Collecte et stockage des métriques
- **Grafana** : Visualisation et dashboards
- **Proxmox Exporter** : Collecte des métriques Proxmox (VMs, conteneurs, backups)
- **Node Exporter** : Métriques système (CPU, RAM, disk, network)
- **cAdvisor** : Métriques des conteneurs Docker

## Prérequis

- Docker et Docker Compose installés
- Accès à votre serveur Proxmox
- Un utilisateur Proxmox avec permissions de lecture (voir configuration ci-dessous)

## Installation

### 1. Créer un utilisateur de monitoring sur Proxmox

Connectez-vous à votre serveur Proxmox via SSH et créez un utilisateur dédié :

```bash
# Créer un utilisateur
pveum user add monitoring@pve --password <votre_mot_de_passe>

# Créer un rôle de lecture seule
pveum role add PVEAuditor -privs VM.Audit

# Assigner le rôle à l'utilisateur
pveum aclmod / -user monitoring@pve -role PVEAuditor
```

### 2. Configuration de la stack

#### a) Configuration Grafana (.env)

```bash
cp .env.example .env
nano .env
```

Modifiez le mot de passe admin dans le fichier `.env` :

```env
# Identifiants Grafana (modifiez le mot de passe)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=votre_mot_de_passe_securise
```

#### b) Configuration Proxmox Exporter (pve.yml)

```bash
cp prometheus/pve.yml.example prometheus/pve.yml
nano prometheus/pve.yml
```

Configurez les identifiants Proxmox :

```yaml
default:
  user: monitoring@pve
  password: votre_mot_de_passe_monitoring
  verify_ssl: false
```

#### c) Configuration de l'IP Proxmox (prometheus.yml)

```bash
nano prometheus/prometheus.yml
```

Trouvez la section `job_name: 'proxmox'` et remplacez `192.168.1.23:8006` par l'IP et le port de votre serveur Proxmox :

```yaml
  - job_name: 'proxmox'
    static_configs:
      - targets:
        - 192.168.1.100:8006  # CHANGEZ CETTE IP
```

### 3. Démarrer la stack

```bash
docker-compose up -d
```

### 4. Vérifier que tout fonctionne

```bash
# Vérifier les conteneurs
docker-compose ps

# Vérifier les logs
docker-compose logs -f
```

## Accès aux interfaces

- **Grafana** : http://localhost:3000
  - User : admin (ou celui défini dans .env)
  - Password : celui défini dans .env

- **Prometheus** : http://localhost:9090

- **cAdvisor** : http://localhost:8080

## Configuration de Grafana

### 1. Première connexion

1. Accédez à http://localhost:3000
2. Connectez-vous avec les identifiants définis dans `.env`
3. Prometheus sera automatiquement configuré comme source de données

### 2. Importer des dashboards Proxmox

Grafana propose des dashboards prêts à l'emploi pour Proxmox :

1. Allez dans **Dashboards** > **Import**
2. Entrez l'ID du dashboard Grafana :
   - **10347** : Proxmox VE Summary
   - **10048** : Proxmox VE Cluster
   - **1860** : Node Exporter Full
   - **193** : Docker monitoring (cAdvisor)

3. Sélectionnez **Prometheus** comme source de données
4. Cliquez sur **Import**

### Dashboards recommandés

| ID    | Nom                          | Description                           |
|-------|------------------------------|---------------------------------------|
| 10347 | Proxmox VE Summary           | Vue d'ensemble Proxmox                |
| 10048 | Proxmox VE Cluster           | Monitoring cluster Proxmox            |
| 1860  | Node Exporter Full           | Métriques système détaillées          |
| 193   | Docker monitoring            | Monitoring conteneurs Docker          |
| 11074 | Node Exporter for Prometheus | Alternative Node Exporter             |

## Métriques disponibles

### Proxmox
- État des VMs et conteneurs (running, stopped)
- Utilisation CPU, RAM, Disk par VM/CT
- Statut des backups
- Uptime des VMs
- Trafic réseau

### Système (Node Exporter)
- CPU, RAM, Disk
- I/O disques
- Trafic réseau
- Température (si disponible)

### Conteneurs (cAdvisor)
- Utilisation ressources par conteneur
- Métriques réseau
- Filesystem

## Maintenance

### Arrêter la stack

```bash
docker-compose down
```

### Redémarrer un service

```bash
docker-compose restart grafana
docker-compose restart prometheus
```

### Voir les logs

```bash
docker-compose logs -f [service_name]
```

### Mettre à jour les images

```bash
docker-compose pull
docker-compose up -d
```

### Sauvegarder les données

Les données sont stockées dans des volumes Docker :
- `prometheus_data` : Données Prometheus
- `grafana_data` : Dashboards et configurations Grafana

Pour sauvegarder :

```bash
docker run --rm -v monitor_prometheus_data:/data -v $(pwd):/backup ubuntu tar czf /backup/prometheus_backup.tar.gz /data
docker run --rm -v monitor_grafana_data:/data -v $(pwd):/backup ubuntu tar czf /backup/grafana_backup.tar.gz /data
```

## Personnalisation

### Ajouter des nodes Proxmox supplémentaires

Éditez `prometheus/prometheus.yml` et ajoutez :

```yaml
  - job_name: 'proxmox-node-2'
    static_configs:
      - targets: ['<IP_NODE_2>:9100']
        labels:
          instance: 'proxmox-node-2'
```

### Modifier la rétention des données Prometheus

Dans `docker-compose.yml`, modifiez la ligne :

```yaml
- '--storage.tsdb.retention.time=30d'  # Changer 30d selon vos besoins
```

## Dépannage

### Proxmox Exporter ne se connecte pas

1. Vérifiez que l'IP Proxmox est correcte dans `prometheus/prometheus.yml`
2. Vérifiez les identifiants dans `prometheus/pve.yml`
3. Vérifiez que l'utilisateur a les bonnes permissions sur Proxmox
4. Consultez les logs : `docker-compose logs proxmox-exporter`
5. Testez manuellement l'endpoint :
   ```bash
   curl "http://localhost:9221/pve?target=192.168.1.23:8006&module=default"
   ```

### Erreur "401 Unauthorized"

- Vérifiez l'utilisateur et le mot de passe dans `prometheus/pve.yml`
- Vérifiez que l'utilisateur `monitoring@pve` existe sur Proxmox
- Vérifiez les permissions : `pveum aclmod / -user monitoring@pve -role PVEAuditor`

### Grafana ne démarre pas

1. Vérifiez les permissions du volume : `docker-compose logs grafana`
2. Vérifiez que le port 3000 n'est pas déjà utilisé

### Pas de données dans Prometheus

1. Vérifiez la configuration : http://localhost:9090/targets
2. Tous les targets doivent être "UP"
3. Si le target "proxmox" est "DOWN", vérifiez :
   - L'IP dans `prometheus/prometheus.yml`
   - Les logs : `docker-compose logs proxmox-exporter`
   - Que le serveur Proxmox est accessible
4. Testez une requête Prometheus : `pve_up` ou `pve_version_info`

## Sécurité

- Changez les mots de passe par défaut dans `.env`
- Si exposé sur internet, utilisez un reverse proxy avec SSL (Traefik, Nginx)
- Considérez l'activation de SSL pour Proxmox (`PVE_VERIFY_SSL=true`)
- Limitez l'accès réseau avec un firewall

## Architecture

```
┌─────────────────────────────────────────────┐
│           Proxmox VE Server                 │
│  ┌─────────────────────────────────────┐   │
│  │  VMs / Conteneurs / Backups         │   │
│  └─────────────────────────────────────┘   │
└──────────────────┬──────────────────────────┘
                   │ API
                   ▼
         ┌─────────────────┐
         │ Proxmox Exporter│
         └────────┬────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   Prometheus    │◄────┐
         │  (Port 9090)    │     │
         └────────┬────────┘     │
                  │              │
                  │         Node Exporter
                  │         cAdvisor
                  │
                  ▼
         ┌─────────────────┐
         │    Grafana      │
         │  (Port 3000)    │
         └─────────────────┘
```

## Ressources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Proxmox VE Exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

## Licence

MIT
