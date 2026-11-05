# Variables
IMAGE_NAME = etiehuot/rt1sa05:latest
CONTAINER_NAME = rt1sa05

.PHONY: all install-docker fix-dns start-env shell stop-env

all: install-docker fix-dns
	@echo ""
	@echo "======================================================================"
	@echo " INSTALLATION TERMINÉE AVEC SUCCÈS "
	@echo " Vous pouvez maintenant lancer : make start-env "
	@echo "======================================================================"

install-docker:
	@echo "=== Mise à jour et installation des prérequis ==="
	sudo apt update
	sudo apt install -y ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	@echo "=== Ajout du dépôt Docker officiel ==="
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt update
	sudo apt upgrade -y
	@echo "=== Installation des paquets Docker ==="
	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	@echo "=== Ajout de l'utilisateur courant au groupe docker ==="
	sudo usermod -aG docker $$USER

fix-dns:
	@echo "=== Configuration des DNS (contournement du problème de DNS de VMWare) ==="
	sudo apt install -y dnsutils
	sudo nmcli connection modify "Wired connection 1" ipv4.dns "1.1.1.1 8.8.8.8" ipv4.ignore-auto-dns yes
	sudo nmcli connection up "Wired connection 1"
	sudo systemctl restart docker

start-env:
	@echo "=== Lancement de l'environnement de développement ==="
	@echo "Autorisation de l'affichage graphique local..."
	xhost +local:docker
	@echo "Démarrage du conteneur en tâche de fond..."
	# pour que le  groupe docker soit pris en compte dans le Makefile, on utilise sg
	sg docker -c 'docker run -d \
		--name $(CONTAINER_NAME) \
		-p 8080:80 \
		-e DISPLAY=$$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix:ro \
		-v $$(pwd):/home/etudiant/RT1SA05 \
		$(IMAGE_NAME)'

shell:
	@echo "=== Connexion au conteneur ==="
	sg docker -c 'docker exec -it $(CONTAINER_NAME) bash'

stop-env:
	@echo "=== Arrêt et suppression du conteneur ==="
	sg docker -c 'docker rm -f $(CONTAINER_NAME)'

