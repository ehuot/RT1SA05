CC = gcc
CGIDIR = /usr/lib/cgi-bin/
LOGDIR = /var/log/apache2/
WWWDIR = /var/www/
HTMLDIR= $(WWWDIR)/html/

# --- DÉTECTION DE L'ARCHITECTURE (VM Debian 13) ---
ARCH_DIR = $(shell uname -m)
# --------------------------------------------------

# all lance la compilation PUIS l'installation
all: compile 

# Délégation de la compilation au Makefile du dossier src/
compile:
	@echo "Compilation du code étudiant dans src/..."
	@$(MAKE) -C src

install: install-html install-cgi install-dependencies install-apache-config
	@sudo chmod a+rx $(LOGDIR) 
	@sudo chmod a+r $(LOGDIR)/access.log 

install-dependencies: 
	@if ! dpkg -s libsdl1.2debian libsdl1.2-dev libsdl-ttf2.0-dev libsdl-ttf2.0-0 fonts-freefont-ttf > /dev/null 2>&1; then \
		echo "Installation des dépendances manquantes..."; \
		echo "Rappel : le mot de passe du compte est tplinux :"; \
		sudo apt install -y libsdl1.2debian libsdl1.2-dev libsdl-ttf2.0-dev libsdl-ttf2.0-0 fonts-freefont-ttf; \
	fi

install-apache-config:
	@if ! dpkg -s apache2 > /dev/null 2>&1; then \
		echo "apache n'est pas installé, installons-le"; \
		sudo apt install -y apache2 ; \
	fi
	@if [ ! -f /etc/apache2/conf-available/servername.conf ]; then \
		echo "ServerName sae1.05" | sudo tee /etc/apache2/conf-available/servername.conf > /dev/null; \
		sudo a2enconf servername > /dev/null; \
		sudo systemctl reload apache2; \
	fi
	@if ! /sbin/apache2ctl -M | grep -q cgi; then \
		sudo a2enmod cgid; \
		sudo systemctl restart apache2; \
	fi

install-cgi:
	@echo "Installation des programmes de référence ($(ARCH_DIR)) et fichiers textes dans $(CGIDIR)..."
	@sudo cp bin/aecrire.html bin/versiondynamique-txt $(CGIDIR)
	@sudo cp bin/$(ARCH_DIR)/versionstatique $(CGIDIR)
	@sudo cp bin/$(ARCH_DIR)/versiondynamique $(CGIDIR)

install-html:
	@echo "Déploiement des fichiers web de la SAÉ..." 
	@sudo mkdir -p $(HTMLDIR)
	@sudo cp -a www/html/* $(HTMLDIR)/
	@sudo chown -R www-data:www-data $(HTMLDIR)
	@echo "Décompression et copie du fichier de log..." 
	@zcat log/access.log.big.gz | sudo tee $(LOGDIR)/access.log > /dev/null

pdf:
	@if ! dpkg -s  weasyprint > /dev/null 2>&1; then \
		sudo apt install -y weasyprint; \
	fi
	weasyprint www/html/index.html 1.pdf
	weasyprint www/html/sujet.html 2.pdf
	weasyprint www/html/logs.html 3.pdf
	weasyprint www/html/cgi-bin.html 4.pdf
	weasyprint www/html/statique.html 5.pdf
	weasyprint www/html/soumission.html 6.pdf
	weasyprint www/html/bibliographie.html 7.pdf
	pdfunite 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf compterendu/sujet_en.pdf
	rm -f 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf
	@echo "Génération de sujet_en.pdf terminée."

clean: 
	@echo "Nettoyage de l'installation système..."
	@sudo rm -rf $(WWWDIR)/*
	@sudo mkdir -p $(HTMLDIR)
	@echo "Restauration de la page d'accueil par défaut d'Apache..."
	@sudo cp www/index.html $(HTMLDIR)/index.html
	@sudo chown www-data:www-data $(HTMLDIR)/index.html
	@sudo rm -rf $(CGIDIR)/*
	@echo "Nettoyage des fichiers compilés dans src/..."
	@$(MAKE) -C src clean
