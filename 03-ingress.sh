# Source: https://gist.github.com/801c99d6acc5a1e68bcee2591fac90eb

####################
# Creating Cluster #
####################

# Docker for Desktop: https://gist.github.com/33fd661da626a167687ecb4267700588
# minikube: https://gist.github.com/e7ad0cc633831147d2dbcd4fe2a97a74
# GKE: https://gist.github.com/a260c0812459a57b46b9ea807a26173e
# EKS: https://gist.github.com/073edd549bc0c4d9bda6b4b7bd6bed99
# AKS: https://gist.github.com/c288e9a8dd45ce855d477d1780d2d2e1

# NOTE: We removed Istio in the previous section, so we need to install it even if you did not destroy the cluster
istioctl manifest install \
    --set profile=demo

#################
# Using Gateway #
#################

# Open https://github.com/vfarcic/go-demo-7

# Fork it

GH_USER=[...]

git clone \
    https://github.com/$GH_USER/go-demo-7.git

cd go-demo-7

git pull

ls -1 k8s/istio/gateway/

ls -1 k8s/istio/gateway/app

cat k8s/istio/gateway/app/istio.yaml

kubectl create namespace go-demo-7

kubectl label namespace go-demo-7 \
    istio-injection=enabled

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/gateway \
    --recursive

kubectl --namespace go-demo-7 \
    rollout status \
    deployment go-demo-7-primary

kubectl --namespace go-demo-7 \
    get pods

kubectl --namespace go-demo-7 \
    get virtualservices

kubectl --namespace go-demo-7 \
    describe virtualservice go-demo-7

kubectl run curl \
    --image alpine \
    -it --rm \
    -- sh -c "apk add -U curl && curl go-demo-7.go-demo-7/demo/hello"

kubectl --namespace go-demo-7 \
    get ingress

kubectl --namespace go-demo-7 \
    get gateways

kubectl --namespace go-demo-7 \
    describe gateway go-demo-7

# If minikube
export INGRESS_PORT=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

# If minikube
export INGRESS_HOST=$(minikube ip):$INGRESS_PORT

# If Docker Desktop
export INGRESS_HOST=127.0.0.1

# If EKS
export INGRESS_HOST=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

# If GKE or AKS (NOT minikube and NOT Docker Desktop and NOT EKS)
export INGRESS_HOST=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $INGRESS_HOST

curl -v -H "Host: go-demo-7.acme.com" \
    "http://$INGRESS_HOST/demo/hello"

curl -v -H "Host: something-else.acme.com" \
    "http://$INGRESS_HOST/demo/hello"

kubectl --namespace go-demo-7 delete \
    --filename k8s/istio/gateway \
    --recursive
 
#################
# Using Ingress #
#################

istioctl profile dump demo

istioctl manifest install \
    --set values.global.k8sIngress.enabled=true

ls -1 k8s/istio/ingress/app

cat k8s/istio/ingress/app/ingress.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/ingress/ \
    --recursive

# If `no matches for kind "Ingress" in version "networking.k8s.io/v1beta1"`, upgrade Kubernetes to 1.14+

kubectl --namespace go-demo-7 \
    rollout status \
    deployment go-demo-7-primary

curl -H "Host: go-demo-7.acme.com" \
    "http://$INGRESS_HOST/demo/hello"

kubectl --namespace go-demo-7 delete \
    --filename k8s/istio/ingress \
    --recursive

##############
# References #
##############

# https://istio.io/docs/reference/config/networking/gateway/

###############
# Cleaning Up #
###############

cd ..

kubectl delete namespace go-demo-7

# Destroy the cluster (optional)