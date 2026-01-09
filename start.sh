#!/bin/bash

echo "================================================"
echo " Stack Monitoring Proxmox - Démarrage"
echo "================================================"
echo ""

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Installez Docker avant de continuer."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Installez Docker Compose avant de continuer."
    exit 1
fi

# Vérifier si le fichier .env existe
if [ ! -f .env ]; then
    echo "⚠️  Le fichier .env n'existe pas."
    echo "📝 Copie de .env.example vers .env..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT : Éditez le fichier .env avec vos informations Proxmox !"
    echo ""
    echo "Ouvrez le fichier .env et configurez :"
    echo "  - GRAFANA_ADMIN_PASSWORD"
    echo "  - PVE_HOST (ex: https://192.168.1.100:8006)"
    echo "  - PVE_USER (ex: monitoring@pve)"
    echo "  - PVE_PASSWORD"
    echo ""
    read -p "Appuyez sur Entrée une fois le fichier .env configuré..."
fi

echo "🚀 Démarrage de la stack de monitoring..."
echo ""

# Démarrer les conteneurs
docker-compose up -d

# Attendre que les services démarrent
echo ""
echo "⏳ Attente du démarrage des services..."
sleep 10

# Vérifier l'état des conteneurs
echo ""
echo "📊 État des conteneurs :"
docker-compose ps

echo ""
echo "================================================"
echo "✅ Stack démarrée avec succès !"
echo "================================================"
echo ""
echo "🌐 Accès aux interfaces :"
echo "  - Grafana     : http://localhost:3000"
echo "  - Prometheus  : http://localhost:9090"
echo "  - cAdvisor    : http://localhost:8080"
echo ""
echo "📖 Consultez le README.md pour les prochaines étapes"
echo "   (configuration Grafana, import des dashboards, etc.)"
echo ""
echo "📝 Commandes utiles :"
echo "  - Arrêter     : docker-compose down"
echo "  - Logs        : docker-compose logs -f"
echo "  - Redémarrer  : docker-compose restart"
echo ""
