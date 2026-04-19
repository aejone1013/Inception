NAME = inception

# Create volume directories on host if they don't exist
VOLUMES_DIR = /home/jaoh/data

all: setup
	docker compose -f srcs/docker-compose.yml up --build -d

setup:
	@mkdir -p $(VOLUMES_DIR)/wordpress
	@mkdir -p $(VOLUMES_DIR)/mariadb

down:
	docker compose -f srcs/docker-compose.yml down

stop:
	docker compose -f srcs/docker-compose.yml stop

start:
	docker compose -f srcs/docker-compose.yml start

restart:
	docker compose -f srcs/docker-compose.yml restart

logs:
	docker compose -f srcs/docker-compose.yml logs -f

# Stop and remove containers, networks
clean: down

# Also remove volumes and images
fclean: down
	docker compose -f srcs/docker-compose.yml down -v --rmi all 2>/dev/null || true
	@sudo rm -rf $(VOLUMES_DIR)/wordpress/*
	@sudo rm -rf $(VOLUMES_DIR)/mariadb/*

re: fclean all

.PHONY: all setup down stop start restart logs clean fclean re
