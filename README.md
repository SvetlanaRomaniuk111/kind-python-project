# 🐳 Flask App on Kubernetes with Kind and Ingress

This project demonstrates how to run a simple Flask app inside a Kubernetes cluster created with [Kind](https://kind.sigs.k8s.io/), using an NGINX Ingress controller for browser access via `http://localhost`.

## 📁 Project Structure

kind-python-project/
├── .devcontainer/
│   └── devcontainer.json
│   └── setup.sh
├── .vscode/
│   └── settings.json
├── src/
│   └── kind_python_project/
│       └── app.py
├── deployment.yaml
├── Dockerfile
├── ingress.yaml
├── Makefile
├── requirements.txt
├── service.yaml
├── start-port-forward.bat
└── README.md

---

## 🚀 Getting Started

1. Clone the repository
```bash
git clone https://github.com/your-username/kind-python-project.git
cd kind-python-project
```

2. Create a Kind cluster
```bash
kind create cluster
```
(If already created — skip this step.)

3. 🛠 Build and Load Docker Image
```bash
docker build -t my-python-app:latest .
kind load docker-image my-python-app:latest
```

4. 📦 Deploy to Kubernetes
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Wait for the pod to be in Running state:
```bash
kubectl get pods
```

5. 🌐 Set Up Ingress Controller
Install the official NGINX Ingress controller for Kind:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/kind/deploy.yaml
```
Label the Kind node:
```bash
kubectl label node kind-control-plane ingress-ready=true
```
Wait until the ingress-nginx-controller pod becomes Running:
```bash
kubectl get pods -n ingress-nginx
```
Then apply your Ingress configuration:
```bash
kubectl apply -f ingress.yaml
```

6. 🔁 Start Port Forwarding
You can use the provided script to start port-forwarding and open the browser automatically:
✅ Recommended:
```bash
.\start-port-forward.bat # для Windows (локально)
.\start-port-forward.sh  # для Codespaces (Linux)
```
🧪 Or manually (for debugging)
```bash
kubectl port-forward --namespace ingress-nginx service/ingress-nginx-controller 80:80
```
Then visit: http://localhost

7. 🧼 Teardown (Optional)
```bash
kind delete cluster
```

📎 Notes
This is a development setup. Don't use the built-in Flask server in production.

Make sure port 80 is not occupied by other services like IIS or Apache on your system.

📄 License
MIT License.

---

📌 Next Steps:

Replace https://github.com/your-username/kind-python-project.git with your actual GitHub repository URL.

Create a new repository on GitHub and push your project files:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/your-username/kind-python-project.git
git push -u origin main