# Cloud Resume Challenge
Through the Cloud Resume Challenge, I've implemented a solution that showcases my expertise with multiple Azure and AWS services throughout the years, demonstrating practical cloud architecture and deployment skills.

## Architecture
```mermaid
flowchart TD

    Web[Web] --> ContApp[Container App]
    ContApp <--> AzFile[Azure File: Visitor Count]
    ContApp <--> AzBlob[Azure Blob: Image Assests]
    ContApp --> CAE[Container App Environment]
    ContApp <--> MI[Managed Identity]
    CAE --> LAW[Log Analytics Workspace]
    AzBlob <--> SA[Storage Account]
    AzFile <--> SA[Storage Account]
    
    %% Styling
    classDef azure fill:#0072C6,stroke:#fff,stroke-width:1px,color:white
    classDef container fill:#621AB2,stroke:#fff,stroke-width:1px,color:white
    classDef storage fill:#3BA1C0,stroke:#fff,stroke-width:1px,color:white
    classDef identity fill:#FFB619,stroke:#fff,stroke-width:1px,color:black
    classDef monitoring fill:#0072C6,stroke:#fff,stroke-width:1px,color:white
    classDef resource fill:#666,stroke:#fff,stroke-width:1px,color:white
    classDef web fill:#4CAF50,stroke:#fff,stroke-width:1px,color:white
    
    class RG resource
    class MI identity
    class ContApp,CAE container
    class AzFile,AzBlob,SA storage
    class LAW monitoring
    class Web web
```

## Components
- **Azure Container App**: Serves web application and visitor count process
- **Azure File Storage**: Persists visitor count
- **Azure Blob Storage**: Houses image assets for web application
- **Container App Environment**: Provides runtime context for container app
- **Log Analytics Workspace**: Retains log for my application
- **Managed Identity**: Allows container app to pull container images

## Learnings
My Cloud Resume has evolved significantly over the years. I initially deployed it in a 'ClickOps' manner on AWS back in 2020, utilizing services such as S3, Route53 and CloudFront. I later migrated to Azure using the equivalent services like a Azure Storage Account, Function App, Cosmos DB and Front Door. More recently, I've transformed it into a containerized application and host it on Azure Container Apps.

The entire infrastructure is now defined and deployed using Terraform, embracing infrastructure as code principles for consistent, repeatable deployments. It was also previously version controlled and deployed through Azure DevOps, using Azure Repos and Azure Pipelines, having now migrated the project to GitHub and GitHub Actions. This transition provided valuable experience in understanding the GitHub Actions syntax and its 'gotchas'.
