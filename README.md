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

## License

[MIT](LICENSE)
