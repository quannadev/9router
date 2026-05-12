docker stop 9router
docker rm 9router
docker build -t 9router .
# Ensure the host directory exists before mounting
mkdir -p $HOME/.9router/data
docker run -d --name 9router -p 20128:20128 --env-file .env -v $HOME/.9router/data:/app/data_local 9router