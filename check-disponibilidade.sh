url="http://bia-alb-1501318525.us-east-1.elb.amazonaws.com/"
docker build -t check_disponibilidade -f Dockerfile_checkdisponibilidade .
docker run --rm -ti -e URL=$url check_disponibilidade
