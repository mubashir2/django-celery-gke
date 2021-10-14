# cloudgeeks.ca

# docker-django-redis-celery-nginx-supervisor

Docker Nginx Django Redis Celery Supervisor

## Getting Started
This project works on Python 3+ and Django 2+.
Simply, run the following command:
```
docker-compose up -d --build
```

enable cloudbuild api


# Deployemnt of Django Celery App  

## Major Components  

    1. GKE Cluster
    2. SQL database
    3. Secret Manager
    4. Cloud Build (Continous Deployment)

## Enable API's  
We will use the following apis:

Enable the apis:
```
gcloud services enable \
 container.googleapis.com \
 sqladmin.googleapis.com \
 cloudbuild.googleapis.com \
 secretmanager.googleapis.com \
 sourcerepo.googleapis.com
```
    1. container.googleapis.com
    2. sqladmin.googleapis.com

## Variables  

```  
PROJECT_ID=gke-fatafat-mub
REGION=us-central1
ZONE=us-central1-c

# Service Account Name to be created and used by gke cluster, make sure it is unqiue within project
SA_NAME=fatafatgke
# Service Account complete name
SERVICE_ACCOUNT=fatafatgke@$PROJECT_ID.iam.gserviceaccount.com

CLUSTER_NAME=cluster-2
# Number of Nodes in the Cluster
NUM_OF_NODES=2
# REGION in which nodes will be created
COMPUTE_REGION=us-central1
# Incase to use single zone, replace --region $COMPUTE_REGION with --zone $COMPUTE_ZONE
COMPUTE_ZONE=us-central1-c

# Network 
NETWORK=projects/$PROJECT_ID/global/networks/default
# SubNet
SUB_NET=projects/$PROJECT/regions/$REGION/subnetworks/default


# Namespace to be used for deployments (creating pods, services inside cluster)
NAMESPACE=testing

# Image name to be pushed to gcr.io
IMAGE_NAME=testing


# cloud build service account
PROJECTNUM=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
CLOUDBUILD=${PROJECTNUM}@cloudbuild.gserviceaccount.com
```  
## Create Custom Service Account for GKE and Add IAM Biniding/roles  

create service account
```
gcloud iam service-accounts create $SA_NAME --display-name=$SA_NAME
```
  
Add required roles for managing GKE cluster.  
```
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/logging.logWriter

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/monitoring.metricWriter

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/monitoring.viewer

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/stackdriver.resourceMetadata.writer

# for accessing gcr.io images
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/storage.objectViewer

# for accessing cloud databases
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/cloudsql.client

# for accessing secrets
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$SERVICE_ACCOUNT" \
  --role roles/secretmanager.secretAccessor
```

## Create GKE Cluster  

Execute the following command to create GKE cluster.  

```
gcloud beta container --project $PROJECT_ID clusters create $CLUSTER_NAME --region $COMPUTE_REGION --no-enable-basic-auth --cluster-version "1.20.10-gke.301" --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true --service-account $SERVICE_ACCOUNT --max-pods-per-node "110" --num-nodes $NUM_OF_NODES --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network $NETWORK --subnetwork $SUB_NET --no-enable-intra-node-visibility --default-max-pods-per-node "110" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes
```

### Configure kubectl command line access  
For __CLUSTER_NAME__, __COMPUTE_REGION__ and __PROJECT_ID__ refer to [__*Variables*__](#variables) section.
```
gcloud container clusters get-credentials $CLUSTER_NAME --region $COMPUTE_REGION --project $PROJECT_ID
```

## Configure Namespace   
For __NAMESPACE__ refer to [__*Variables*__](#variables) section.  
```
kubectl create namespace $NAMESPACE
```
## Create Redis Deployment and Start Redis Service
For __NAMESPACE__ refer to [__*Variables*__](#variables) section. 

Create redis deployment (for details refer to file /redis-deployment.yaml in this repo).
```
kubectl apply -f redis-deployment.yaml --namespace=$NAMESPACE
```
To make sure deployment is successfull ``` kubectl get pods --namespace=$NAMESPACE ```  

Create redis-service (for details refer to file /redis-deployment.yaml in this repo).
```
kubectl apply -f redis-service.yaml --namespace=$NAMESPACE
```
## Configure CI/CD for django-celery App  

### Build and push image to gcr.io  

Build Image and push to gcr.io
```
TAG=gcr.io/$PROJECT_ID/$IMAGE_NAME
docker build --tag $TAG .
docker push $TAG
```
### Deploy to GKE  
For __PROJECT_NAME, IMAGE_NAME, NAMESPACE__ refer to [__*Variables*__](#variables) section.  
Go to app_deployment.yaml, to spec.template.spec.containers.image and change the value to gcr.io/YOUR_PROJECT_NAME/YOUR_IMAGE_NAME  
To get YOUR_PROJECT_NAME use ```echo $PROJECT_NAME``` and for YOUR_IMAGE_NAME use ```echo $IMAGE_NAME```
```
kubectl apply -f app_deployment.yaml --namespace $NAMESPACE
```
### Allow Cloud Build iam role to deploy to GKE cluster  
For __CLOUDBUILD__ refer to [__*Variables*__](#variables) section.  
```
# for creating deployments/services on gke cluster
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:$CLOUDBUILD" \
  --role roles/container.developer
```
### Configure Continous Deployment  
Now go to :
https://console.cloud.google.com/kubernetes/workload/overview?project=PROJECT_ID  
replace PROJECT_ID with your project id (you can use echo $PROJECT_ID in terminal to get your project id).
For __NAMESPACE__  and __CLUSTER_NAME__ refer to [__*Variables*__](#variables).  
 Now select the deployment where Name=app and Type=Deployment and Namespace=NAMESPACE and Cluster=CLUSTER_NAME
 