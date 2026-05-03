up:
	mkdir -p /home/jaoh/data/mariadb /home/jaoh/data/wordpress
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

logs:
	docker logs nginx --tail 50

clean:
	docker compose -f ./srcs/docker-compose.yml down --remove-orphans --volumes

fclean:
	docker compose -f ./srcs/docker-compose.yml down --remove-orphans --volumes
	docker system prune -a
	sudo rm -rf /home/jaoh/data/mariadb /home/jaoh/data/wordpress
