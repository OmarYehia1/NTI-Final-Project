# Local setup

Run TaskBoard on your laptop with Docker Compose.

## Start

```bash
cd local-setup
docker compose up --build
```

Open http://localhost:3000. Add, complete and delete tasks.

- Frontend (nginx): http://localhost:3000
- Backend API docs: http://localhost:8000/api/docs
- Database: PostgreSQL, data kept in a Docker volume

## Stop

```bash
docker compose down
```

Your tasks are kept. To also delete the data, use `docker compose down -v`.

## Optional: SonarQube

```bash
docker compose --profile sonar up -d
```

Open http://localhost:9000 (login: admin / admin, then change the password).

## Local Kubernetes (minikube)

```bash
./local-setup/minikube/up.sh           # install with Helm
./local-setup/minikube/up.sh argocd    # install with Argo CD (GitOps)
./local-setup/minikube/down.sh         # remove everything
```