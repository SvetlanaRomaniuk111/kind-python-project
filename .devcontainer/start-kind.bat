@echo off
set CLUSTER_NAME=kind
set PORT_LOCAL=8080
set PORT_REMOTE=80
set NAMESPACE=ingress-nginx
set SERVICE=ingress-nginx-controller

echo Checking if kind cluster "%CLUSTER_NAME%" exists...
kind get clusters | findstr "%CLUSTER_NAME%" >nul
if %errorlevel% neq 0 (
    echo Creating kind cluster "%CLUSTER_NAME%"...
    kind create cluster --name %CLUSTER_NAME% --wait 60s
) else (
    echo Cluster "%CLUSTER_NAME%" already exists.
)

echo Setting kubectl context...
kubectl config use-context kind-%CLUSTER_NAME%

echo Starting port-forward...
start cmd /c kubectl port-forward -n %NAMESPACE% service/%SERVICE% %PORT_LOCAL%:%PORT_REMOTE%

timeout /t 2 >nul

echo Opening browser...
start http://localhost:%PORT_LOCAL%

echo Done!
