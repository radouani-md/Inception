DATA_PATH = /home/mradouan/data

COMPOSE = docker compose -f srcs/docker-compose.yml

all :
	mkdir -p $(DATA_PATH)/mariadb
	mkdir -p $(DATA_PATH)/wordpress
	mkdir -p $(DATA_PATH)/portainer
	$(COMPOSE) up --build -d


up : 
	$(COMPOSE) up --build -d

build :
	$(COMPOSE) build

down :
	$(COMPOSE) down
ps :
	$(COMPOSE) ps

clean :
	$(COMPOSE) down --rmi all

fclean: clean
	$(COMPOSE) down --volumes
	sudo rm -rf $(DATA_PATH)

re : fclean all
