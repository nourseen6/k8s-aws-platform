# Kubernetes Platform on AWS

Running a containerized application on Kubernetes — first on a local cluster, then on **AWS EKS** provisioned with **Terraform** — with private networking for the backend and database, packaging with **Helm**, autoscaling, and monitoring with **Prometheus** and **Grafana**.

Project 2 of my [DevOps roadmap](https://github.com/nourseen6/roadmap). The application is the URL shortener from [Project 1](https://github.com/nourseen6/secure-cicd-pipeline); this project runs the image that Project 1's pipeline builds and scans.

> 🚧 **Work in progress.** Each step is tracked as an issue in the [Project 2 milestone](https://github.com/nourseen6/k8s-aws-platform/milestone/1).

## Requirements

- The app runs with **at least two replicas** and recovers on its own when a pod fails.
- Only the entry point is **public**. The backend and the database are reachable only inside the cluster or VPC.
- Secrets are never stored in Git.
- All AWS infrastructure is created with **Terraform** — no manual console changes.
- The app is **monitored**, and an alert fires when something breaks.
- Everything is built and tested on a **local cluster first**. AWS resources are destroyed at the end of each working session to keep costs low.

## Target architecture

```mermaid
flowchart LR
    user([User]) -->|HTTPS| alb[AWS Load Balancer<br/>public]
    subgraph vpc[AWS VPC]
        alb --> ing[Ingress controller]
        subgraph eks[EKS cluster — private subnets]
            ing -->|/| fe[Frontend Service<br/>2 pods]
            ing -->|/api| be[Backend Service<br/>2 pods]
            fe -.->|internal| be
            prom[Prometheus + Grafana] -.->|scrape| be
        end
        be -->|5432| rds[(RDS PostgreSQL<br/>private subnet)]
    end
```

| Component | Public? | Why |
|---|---|---|
| Load Balancer | ✅ Yes | The only way in from the internet |
| Ingress controller | No | Routes `/` to the frontend and `/api` to the backend |
| Frontend and backend | No | `ClusterIP` services, reachable only inside the cluster |
| PostgreSQL (RDS) | No | Private subnet; only the backend's security group can connect |

## Plan

| Step | What | Where | Cost |
|---|---|---|---|
| 1 | Local Kubernetes cluster | Laptop | Free |
| 2 | Deploy the app: Deployment with 2 replicas and health probes | Laptop | Free |
| 3 | Expose it with a Service | Laptop | Free |
| 4 | PostgreSQL with a Secret and persistent storage | Laptop | Free |
| 5 | Frontend and Ingress routing | Laptop | Free |
| 6 | Package everything as a Helm chart | Laptop | Free |
| 7 | Terraform: VPC, EKS, and RDS | AWS | Paid by the hour — destroy after each session |
| 8 | Deploy to EKS, and let the pipeline deploy on every release | AWS | Paid |
| 9 | Autoscaling and monitoring with Prometheus and Grafana | Laptop, then AWS | — |
| 10 | Documentation and lessons learned | — | — |

## How the work is done

Every step follows the same workflow:

```
issue → branch → commits → pull request → CI passes → merge → issue closed
```

Nothing is pushed directly to `main`.

## What's built so far

### Local cluster (Step 1)

Docker Desktop's Kubernetes with kind: one node that is both the control plane and the worker.

### The app (Steps 2–3) — [`k8s/deployment.yaml`](k8s/deployment.yaml), [`k8s/service.yaml`](k8s/service.yaml)

- A **Deployment** keeps **2 replicas** of the Project 1 image running. Deleting a pod makes Kubernetes create a new one.
- **Readiness and liveness probes** call `/health`. During a rolling update, an old pod is removed only after its replacement is ready — no downtime.
- **Resource requests and limits** stop one pod from starving the others.
- A **ClusterIP Service** gives the pods one stable name and IP inside the cluster.

### The database (Step 4) — [`k8s/postgres.yaml`](k8s/postgres.yaml)

- PostgreSQL runs as a **StatefulSet** with a stable pod name (`postgres-0`) and a **1Gi PersistentVolumeClaim**.
- The credentials live in a **Secret** created with `kubectl`, never in Git. The app reads them through `secretKeyRef` and builds `DATABASE_URL` from them.
- An **init container** waits for PostgreSQL before the app starts, so the app doesn't crash-loop after a cluster restart.
- **Tested:** a link created on one replica opens from the other, and it survives deleting the database pod — the new `postgres-0` mounts the same volume.

### Run it

```bash
kubectl apply -f k8s/namespace.yaml

kubectl create secret generic postgres-credentials -n dev \
  --from-literal=POSTGRES_USER=shortener \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -hex 16)" \
  --from-literal=POSTGRES_DB=shortener

kubectl apply -f k8s/
kubectl port-forward -n dev service/url-shortener 8080:80
curl http://127.0.0.1:8080/health
```

> Kubernetes Secrets are base64-encoded, not encrypted. On a real cluster, access to them is limited with RBAC and they are encrypted at rest or kept in a secrets manager.

## License

[MIT](LICENSE)
