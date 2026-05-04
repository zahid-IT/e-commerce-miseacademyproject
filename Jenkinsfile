pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
        K3S_SERVER = '34.235.131.161'
        K3S_USER = 'ubuntu'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "Building branch: ${env.BRANCH}, commit: ${env.GIT_SHA}"
                }
            }
        }

        stage('Setup kubectl') {
            steps {
                sh '''
                    # Download kubectl to workspace (no sudo needed)
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        # Add to PATH for this session
                        export PATH=$PATH:$PWD
                    fi
                    
                    # Copy kubeconfig from K3s server
                    mkdir -p ~/.kube
                    scp -o StrictHostKeyChecking=no $K3S_USER@$K3S_SERVER:/etc/rancher/k3s/k3s.yaml ~/.kube/config
                    
                    # Update server IP in kubeconfig
                    sed -i "s/127.0.0.1/$K3S_SERVER/g" ~/.kube/config
                    
                    # Test connection
                    ./kubectl get nodes || kubectl get nodes
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                    docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                    docker tag $REGISTRY/$BACKEND_IMAGE:$GIT_SHA $REGISTRY/$BACKEND_IMAGE:latest
                    docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                    docker push $REGISTRY/$BACKEND_IMAGE:latest
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                    docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA ./frontend
                    docker tag $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA $REGISTRY/$FRONTEND_IMAGE:latest
                    docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                    docker push $REGISTRY/$FRONTEND_IMAGE:latest
                '''
            }
        }

        stage('Deploy to K3s') {
            steps {
                sh '''
                    # Use kubectl from workspace
                    export PATH=$PATH:$PWD
                    
                    # Update deployments
                    kubectl set image deployment/ecommerce-backend -n dev \
                        backend=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA || true
                    
                    kubectl set image deployment/ecommerce-frontend -n dev \
                        frontend=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA || true
                    
                    # Wait for rollouts
                    kubectl rollout status deployment/ecommerce-backend -n dev --timeout=5m || true
                    kubectl rollout status deployment/ecommerce-frontend -n dev --timeout=5m || true
                    
                    # Show deployment status
                    kubectl get pods -n dev
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline successful! Deployed $GIT_SHA to K3s cluster"
            echo "🌐 Frontend: http://${K3S_SERVER}:31047"
            echo "🌐 Backend API: http://${K3S_SERVER}:31047/api/health"
        }
        failure {
            echo "❌ Pipeline failed! Check logs above."
        }
    }
}
