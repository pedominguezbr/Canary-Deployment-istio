# Source: https://gist.github.com/5b3cd6f336e2d9e6682c1a1792c860d0

####################
# Creating Cluster #
####################

# Docker for Desktop with Istio: https://gist.github.com/d9b92a8e03c2403624fcef25f3fcd4e5
# minikube with Istio: https://gist.github.com/01f562077f31750d24c8b7ef5b3ae4d0
# GKE with Istio: https://gist.github.com/80c379849b96f4ae5a2ccd30d843f205
# EKS with Istio: https://gist.github.com/957971fe8664de180ecc466a8da6017d
# AKS with Istio: https://gist.github.com/ff3da0c0fc6e76ba7c3bf9acc99b88d8

#####################
# Deploying The App #
#####################

cd go-demo-7

git pull

kubectl create namespace go-demo-7

kubectl label namespace go-demo-7 \
    istio-injection=enabled

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/db \
    --recursive

kubectl --namespace go-demo-7 apply \
    --filename k8s/istio/split/app \
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

curl -H "Host: go-demo-7.acme.com" \
    "http://$INGRESS_HOST/version"

####################
# Querying Metrics #
####################

kubectl --namespace istio-system \
    get service prometheus

kubectl --namespace istio-system \
    port-forward $(kubectl \
    --namespace istio-system \
    get pod \
    --selector app=prometheus \
    --output jsonpath='{.items[0].metadata.name}') \
    9090:9090 &

# NOTE: Might need to press the enter key

open "http://localhost:9090"

for i in {1..300}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/version"
    sleep 0.1
done

# Execute the following prometheus queries:
# istio_requests_total
# istio_requests_total{destination_workload="go-demo-7-primary", reporter="destination"}
# istio_request_duration_milliseconds_sum{destination_workload="go-demo-7-primary", reporter="destination"}
# istio_request_duration_milliseconds_bucket{destination_workload="go-demo-7-primary", reporter="destination"}

##############
# Error Rate #
##############

for i in {1..300}; do 
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/demo/random-error"
    sleep 0.1
done

# Execute the following prometheus queries:
# sum(rate(istio_requests_total{destination_workload="go-demo-7-primary", reporter="destination"}[1m]))
# sum(rate(istio_requests_total{destination_workload="go-demo-7-primary", reporter="destination",response_code!~"5.*"}[1m]))
# sum(rate(istio_requests_total{destination_workload="go-demo-7-primary", reporter="destination",response_code!~"5.*"}[1m])) / sum(rate(istio_requests_total{destination_workload="go-demo-7-primary", reporter="destination"}[1m]))

############################
# Average Request Duration #
############################

for i in {1..100}; do 
    DELAY=$[ $RANDOM % 1000 ]
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/demo/hello?delay=$DELAY"
done

# Execute the following prometheus queries:
# sum(rate(istio_request_duration_milliseconds_sum{destination_workload="go-demo-7-primary", reporter="destination"}[1m]))
# sum(rate(istio_request_duration_milliseconds_sum{destination_workload="go-demo-7-primary", reporter="destination"}[1m])) / sum(rate(istio_request_duration_milliseconds_count{destination_workload="go-demo-7-primary", reporter="destination"}[1m]))

########################
# Max Request Duration #
########################

for i in {1..100}; do 
    DELAY=$[ $RANDOM % 2000 ]
    curl -H "Host: go-demo-7.acme.com" \
        "http://$INGRESS_HOST/demo/hello?delay=$DELAY"
done

# histogram_quantile(0.95, sum(irate(istio_request_duration_milliseconds_bucket{destination_workload="go-demo-7-primary"}[1m])) by (le))

#######################
# Visualizing Metrics #
#######################

istioctl manifest install \
    --set values.grafana.enabled=true

kubectl --namespace istio-system \
    get service grafana

kubectl --namespace istio-system \
    port-forward $(kubectl \
    --namespace istio-system \
    get pod \
    --selector app=grafana \
    --output jsonpath='{.items[0].metadata.name}') \
    3000:3000 &

open "http://localhost:3000"

##############
# References #
##############

# https://prometheus.io/
# https://grafana.com/

###############
# Cleaning Up #
###############

cd ..

killall kubectl

kubectl delete namespace go-demo-7

# Destroy the cluster (optional)