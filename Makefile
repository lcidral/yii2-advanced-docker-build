NAME = lcidral/alpine.php
VERSION = 7.1.8

.PHONY: all build push tag_latest release selenium chromedriver

all: build

docker-build:
	@docker build -t $(NAME):$(VERSION) .

docker-push:
	@docker push $(NAME):$(VERSION)

docker-release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make docker-build'"; false; fi
	@docker push $(NAME)

docker-tag_latest:
	@docker tag -f $(NAME):$(VERSION) $(NAME):latest

selenium:
	cd bin && java -jar selenium-server-standalone-3.4.0.jar

chromedriver:
	cd bin && ./chromedriver --url-base=/wd/hub

database-create:
	@Criando banco de dados...
	@mysql -u root -padmin -h mariadb -e "DROP DATABASE IF EXISTS yii2advanced"
	@mysql -u root -padmin -h mariadb -e "CREATE DATABASE IF NOT EXISTS yii2advanced"

github-token:
	@composer config -g github-oauth.github.com $$GITHUB_TOKEN


prestissimo:
	@composer global require "fxp/composer-asset-plugin" "hirak/prestissimo"

project-create:
	@echo 'Criando projeto...'
	@composer create-project --prefer-dist yiisoft/yii2-app-advanced src

project-init-dev:
	@echo 'Inicializando projeto em modo DEV...'
	@cd src && ./init --env=Development --overwrite=no

project-migrate:
	@cd src && ./yii migrate

test: setup
	@echo 'run tests'

emoji:
	@echo 😊😂

mailcatcher-test:
	@php -r 'mail("local@alpine.php","Testing php -v ".phpversion(),"php on ".gethostname());'

project-config:
	@echo 'Copiando configurações'
	@cp -R conf/app/* src/

clean:
	@echo 'Limpando pasta SRC/'
	@rm -rf src/

build: clean prestissimo github-token project-create project-config project-init-dev database-create project-migrate docker-compose-up
	@echo 'what is build?'

docker-compose-up:
	@echo 'Subindo containeres...'
	@docker-compose up -d --force-recreate