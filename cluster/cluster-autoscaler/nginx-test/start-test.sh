
kubectl create namespace test
kubectl apply -f nginx.yaml
kubectl scale deployment autoscaler-demo --replicas=20 -n test