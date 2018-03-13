NAME = lcidral/dev.php
VERSION = 7.1.15-fpm-alpine
REPO = yiisoft/yii2-app-advanced

.PHONY: all build push tag_latest release selenium chromedriver

all: build

docker:
	@docker exec -it php bash

docker-build:
	@docker build -t $(NAME):$(VERSION) .

docker-push:
	@docker push $(NAME):$(VERSION)

composer:
	@curl -s https://getcomposer.org/installer | php

docker-release: tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make docker-build'"; false; fi
	@docker push $(NAME)

docker-tag_latest:
	@docker tag -f $(NAME):$(VERSION) $(NAME):latest

selenium:
	cd bin && java -jar selenium-server-standalone-3.4.0.jar

chromedriver:
	cd bin && ./chromedriver --url-base=/wd/hub

database:
	@echo 'Criando banco de dados...'
	@docker exec -it /mariadb mysql -u $$APP_MYSQL_USERNAME --password=$$APP_MYSQL_PASSWORD -h $$APP_MYSQL_HOST -e "CREATE DATABASE IF NOT EXISTS $$APP_MYSQL_DBNAME" -vvv

github-token:
	@echo 'Github Token:' $$GITHUB_TOKEN
	@composer config -g github-oauth.github.com $$GITHUB_TOKEN

create:
	@echo 'Criando projeto...'
	@composer self-update && composer --version
	@composer global require "fxp/composer-asset-plugin" "hirak/prestissimo"
	@composer create-project --prefer-dist $(REPO) src

init:
	@echo 'Inicializando projeto em modo DEV...'
	@cd src && ./init --env=Development --overwrite=no

migrate:
	@cd src && ./yii migrate --interactive=0

test:
	@echo 'Executando testes'
	@cd src/ && composer validate --strict
	@cd src/ && composer update --prefer-dist --no-interaction
	@cd src/ && php yii_test migrate --interactive=0
	@cd src/ && vendor/bin/codecept build
	@cd src/ && vendor/bin/codecept run

emoji:
	@echo 😊😂

mailcatcher-test:
	@php -r 'mail("local@alpine.php","Testing php -v ".phpversion(),"php on ".gethostname());'

config:
	@echo 'Copiando configurações'
	@cp -R conf/app/* src/

clean:
	@echo 'Limpando pasta SRC/'
	@rm -rf src/
	@echo 'Removendo banco de dados'
	@docker exec -it /mariadb mysql -u $$APP_MYSQL_USERNAME  --password=$$APP_MYSQL_PASSWORD -h $$APP_MYSQL_HOST -e "DROP DATABASE IF EXISTS $$APP_MYSQL_DBNAME" -vvv

portainer:
	@docker run -d --privileged -p 9001:9000 --name portainer -v /var/run/docker.sock:/var/run/docker.sock -v /opt/portainer:/data portainer/portainer

build: clean composer github-token create config init database migrate test
	@echo 'this message not printed by segmentation fault... :o['

down:
	@docker-compose down

up:
	@docker-compose up -d --force-recreate
