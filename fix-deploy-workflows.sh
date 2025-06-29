#!/bin/bash

# Script to fix deploy-development.yml files for all central-configuration services

SERVICES=(
    "ci-cd-templates"
    "config-server"
    "database-migrations"
    "deployment-scripts"
    "disaster-recovery"
    "environment-config"
    "infrastructure-as-code"
    "kubernetes-manifests"
    "regional-deployment"
    "secrets-management"
)

for service in "${SERVICES[@]}"; do
    echo "Fixing deploy-development.yml for ${service}..."
    
    cat > "/mnt/c/Users/frich/Desktop/Exalt-Application-Limited/Exalt-Application-Limited/social-ecommerce-ecosystem/central-configuration/${service}/.github/workflows/deploy-development.yml" << 'EOF'
name: Deploy to Development - SERVICE_NAME

on:
  push:
    branches: [ develop ]
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy (leave empty for latest)'
        required: false
        default: 'latest'

env:
  JAVA_VERSION: '17'
  SERVICE_NAME: SERVICE_NAME
  DOCKER_REGISTRY: ghcr.io
  DOCKER_IMAGE: ghcr.io/${{ github.repository_owner }}/SERVICE_NAME
  KUBE_NAMESPACE: central-config-dev
  DEPLOYMENT_NAME: SERVICE_NAME-deployment

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: development
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_DEFAULT_REGION }}
        
    - name: Configure kubectl
      uses: aws-actions/amazon-eks-update-kubeconfig@v1
      with:
        cluster-name: ${{ secrets.EKS_CLUSTER_NAME }}
        
    - name: Determine deployment version
      id: version
      run: |
        if [ "${{ github.event.inputs.version }}" == "latest" ] || [ -z "${{ github.event.inputs.version }}" ]; then
          echo "version=${{ github.sha }}" >> $GITHUB_OUTPUT
        else
          echo "version=${{ github.event.inputs.version }}" >> $GITHUB_OUTPUT
        fi
        
    - name: Update Kubernetes deployment
      run: |
        kubectl set image deployment/${{ env.DEPLOYMENT_NAME }} \
          SERVICE_NAME=${{ env.DOCKER_IMAGE }}:${{ steps.version.outputs.version }} \
          -n ${{ env.KUBE_NAMESPACE }}
          
    - name: Wait for rollout to complete
      run: |
        kubectl rollout status deployment/${{ env.DEPLOYMENT_NAME }} \
          -n ${{ env.KUBE_NAMESPACE }} \
          --timeout=600s
          
    - name: Verify deployment
      run: |
        kubectl get pods -l app=SERVICE_NAME -n ${{ env.KUBE_NAMESPACE }}
        kubectl get services -l app=SERVICE_NAME -n ${{ env.KUBE_NAMESPACE }}
        
    - name: Run smoke tests
      run: |
        SERVICE_URL=$(kubectl get service SERVICE_NAME-service -n ${{ env.KUBE_NAMESPACE }} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        echo "Service URL: $SERVICE_URL"
        
        # Basic health check
        curl -f -s -o /dev/null -w "%{http_code}" http://$SERVICE_URL/actuator/health || exit 1
        
    - name: Update deployment tracking
      uses: actions/github-script@v6
      with:
        script: |
          const deployment = await github.rest.repos.createDeployment({
            owner: context.repo.owner,
            repo: context.repo.repo,
            ref: context.sha,
            task: 'deploy',
            auto_merge: false,
            required_contexts: [],
            environment: 'development',
            description: 'Deployment to development environment'
          });
          
          await github.rest.repos.createDeploymentStatus({
            owner: context.repo.owner,
            repo: context.repo.repo,
            deployment_id: deployment.data.id,
            state: 'success',
            target_url: `https://${process.env.SERVICE_URL}`,
            description: 'Deployment completed successfully'
          });
          
    - name: Send notification
      if: always()
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: |
          Deployment ${{ job.status }} for SERVICE_NAME
          Version: ${{ steps.version.outputs.version }}
          Environment: Development
          Actor: ${{ github.actor }}
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
EOF

    # Replace SERVICE_NAME with actual service name
    sed -i "s/SERVICE_NAME/${service}/g" "/mnt/c/Users/frich/Desktop/Exalt-Application-Limited/Exalt-Application-Limited/social-ecommerce-ecosystem/central-configuration/${service}/.github/workflows/deploy-development.yml"
done

echo "Deploy workflow files fixed!"