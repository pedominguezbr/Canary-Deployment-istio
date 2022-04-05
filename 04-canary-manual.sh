##################
# Create Cluster #
##################

# Docker for Desktop with Istio: https://gist.github.com/d9b92a8e03c2403624fcef25f3fcd4e5
# minikube with Istio: https://gist.github.com/01f562077f31750d24c8b7ef5b3ae4d0
# GKE with Istio: https://gist.github.com/80c379849b96f4ae5a2ccd30d843f205
# EKS with Istio: https://gist.github.com/957971fe8664de180ecc466a8da6017d
# AKS with Istio: https://gist.github.com/ff3da0c0fc6e76ba7c3bf9acc99b88d8

################
# Fist Release #
################

cd go-demo-7

git pull

kubectl create namespace go-demo-7

kubectl label namespace go-demo-7 \
    istio-injection=enabled

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/gateway/ \
    --recursive

kubectl --namespace go-demo-7 \
    rollout status \
    deployment go-demo-7-primary

chmod +x k8s/istio/get-ingress-host.sh

PROVIDER=[...] # minikube, docker, eks, gke, aks, doks

INGRESS_HOST=$(\
    ./k8s/istio/get-ingress-host.sh \
    $PROVIDER)

echo $INGRESS_HOST

for i in {1..10}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

###############
# New Release #
###############

cat k8s/istio/split/exercise/app-0-0-2-canary.yaml

diff k8s/istio/gateway/app/deployment.yaml \
    k8s/istio/split/exercise/app-0-0-2-canary.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/app-0-0-2-canary.yaml

kubectl --namespace go-demo-7 \
    rollout status \
    deployment go-demo-7-canary

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

kubectl --namespace go-demo-7 \
    get deployments

kubectl --namespace go-demo-7 \
    describe service go-demo-7

kubectl --namespace go-demo-7 \
    describe virtualservice go-demo-7

kubectl --namespace go-demo-7 \
    describe gateway go-demo-7

#####################
# Splitting Traffic #
#####################

cat k8s/istio/split/exercise/host20.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/host20.yaml

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

kubectl --namespace go-demo-7 delete \
    --filename k8s/istio/split/exercise/host20.yaml

cat k8s/istio/split/exercise/split20.yaml

# NOTE: The sum of all `weight` entries must be 100

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/split20.yaml

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

###################
# Rolling Forward #
###################

cat k8s/istio/split/exercise/split40.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/split40.yaml

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

cat k8s/istio/split/exercise/split60.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/split60.yaml

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

############################
# Finishing The Deployment #
############################

cat k8s/istio/split/exercise/app-0-0-2.yaml

diff k8s/istio/gateway/app/deployment.yaml \
    k8s/istio/split/exercise/app-0-0-2.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/app-0-0-2.yaml

kubectl --namespace go-demo-7 \
    rollout status \
    deployment go-demo-7-primary

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

cat k8s/istio/split/exercise/split100.yaml

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/exercise/split100.yaml

for i in {1..100}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
done

kubectl --namespace go-demo-7 \
    get deployments

##############
# References #
##############

# https://istio.io/docs/reference/config/networking/virtual-service/
# https://istio.io/docs/reference/config/networking/destination-rule/

###############
# Cleaning Up #
###############

cd ..

kubectl delete namespace go-demo-7

# Destroy the cluster (optional)



when using power shell this command is replacement of getting ip and for loop
$INGRESS_PORT=(kubectl --namespace istio-system get service istio-ingressgateway --output jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

$INGRESS_HOST=(minikube ip)

Have to change c:\windows\system32\etc\driver\hosts file to add the domain entry as following
go-demo-7.acme.com $INGRESS_HOST

$INGRESS_HOST=(minikube ip)+':'+$INGRESS_PORT
for ($i=0;$i -le 100;$i++){(Invoke-WebRequest "http://$INGRESS_HOST/demo/hello").content}
