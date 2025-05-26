setup:
	docker build -t my-python-app:latest .
	kind create cluster --wait 60s
	kind load docker-image my-python-app:latest
	kubectl apply -f deployment.yaml
	kubectl apply -f service.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/kind/deploy.yaml
	kubectl label node kind-control-plane ingress-ready=true
	sleep 10
	kubectl apply -f ingress.yaml
