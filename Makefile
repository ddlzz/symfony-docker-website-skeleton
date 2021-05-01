ifndef DOCKER_PROJECT_NAME
override DOCKER_PROJECT_NAME = sf5_app # override this in CI or manually
endif

up: docker-up
down: docker-down
restart: down up
rebuild: down docker-build
reset: rebuild up

docker-up:
	docker-compose -p $(DOCKER_PROJECT_NAME) up -d

docker-down:
	docker-compose -p $(DOCKER_PROJECT_NAME) down --remove-orphans

docker-down-clear:
	docker-compose -p $(DOCKER_PROJECT_NAME) down -v --remove-orphans

docker-pull:
	docker-compose -p $(DOCKER_PROJECT_NAME) pull

docker-build:
	docker-compose -p $(DOCKER_PROJECT_NAME) build

init: configs-setup composer-install db-create db-migrations permissions-fix

test:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli php /app/bin/phpunit

composer-install:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli sh -c "umask 002 && composer install --no-interaction"

console:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli zsh

cs:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli sh -c "php /app/vendor/bin/php-cs-fixer -v --config=/app/.php_cs.dist fix /app/src/* /app/tests/*"

db-create:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli sh -c "php /app/bin/console doctrine:database:create --if-not-exists"

db-migrations:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli sh -c "php /app/bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration"

permissions-fix:
	docker-compose -p $(DOCKER_PROJECT_NAME) run --rm php-cli sh -c "chmod -R u+rwX,g+w,go+rX,o-w .; [ -d ./var/log ] && chmod -R 777 ./var/log; [ -d ./var/cache ] && chmod -R 777 ./var/cache; chmod -R o+rX ./public"

configs-setup:
	[ -f docker-compose.override.yaml ] && echo "Skip docker-compose.override.yaml" || cp docker-compose.override.yaml.dist docker-compose.override.yaml
	[ -f ./app/.env.local ] && echo "Skip .env.local" || cp ./app/.env ./app/.env.local
	[ -f ./.env ] && echo "Skip docker .env" || cp ./.env.dist ./.env
	[ -f ./app/phpunit.xml ] && echo "Skip phpunit.xml" || cp ./app/phpunit.xml.dist ./app/phpunit.xml
	[ -d ./.git/hooks ] && echo "./.git/hooks exists" || mkdir -p .git/hooks
	[ -d ./app/var/data/.composer ] && echo "./var/data/.composer exists" || mkdir -p ./app/var/data/.composer
	[ -f ./app/var/data/.composer/auth.json ] && echo "Skip ./var/data/.composer/auth.json" || echo '{}' > ./app/var/data/.composer/auth.json

prepare-commit-msg:
	[ -f .git/hooks/prepare-commit-msg ] && echo "Skip .hooks/prepare-commit-msg" || cp docker/dev/hooks/prepare-commit-msg .git/hooks/prepare-commit-msg && chmod +x .git/hooks/prepare-commit-msg
