pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
        // Update with your actual GitOps repo
        GITOPS_REPO = 'https://github.com/zahid-IT/ecommerce-gitops.git'
        // K3s server IP - CHANGE THIS
        K3S_SERVER = '34.235.131.161'  // Your K3s EC2 instance IP
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

        stage('Setup kubectl for K3s') {
            steps {
                sh '''
                    # Install kubectl if not present
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/
                    fi
                    
                    # Copy kubeconfig from K3s server
                    scp -o StrictHostKeyChecking=no $K3S_USER@$K3S_SERVER:/etc/rancher/k3s/k3s.yaml ~/.kube/config
                    
                    # Update server IP in kubeconfig
                    sed -i "s/127.0.0.1/$K3S_SERVER/g" ~/.kube/config
                    
                    # Verify connection
                    kubectl get nodes
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
                    # Update backend deployment in dev namespace
                    kubectl set image deployment/ecommerce-backend -n dev \
                        backend=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA || true
                    
                    # Update frontend deployment in dev namespace
                    kubectl set image deployment/ecommerce-frontend -n dev \
                        frontend=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA || true
                    
                    # Wait for rollout
                    kubectl rollout status deployment/ecommerce-backend -n dev --timeout=5m || true
                    kubectl rollout status deployment/ecommerce-frontend -n dev --timeout=5m || true
                    
                    # Verify deployment
                    kubectl get pods -n dev
                '''
            }
        }

        stage('Update GitOps Repo') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                        rm -rf gitops
                        git clone https://$GIT_USER:$GIT_TOKEN@github.com/zahid-IT/ecommerce-gitops.git gitops || echo "Repo may not exist yet"
                        
                        if [ -d "gitops" ]; then
                            cd gitops
                            
                            # Create directories for environment
                            mkdir -p backend/overlays/dev
                            mkdir -p frontend/overlays/dev
                            
                            # Determine environment
                            if [ "$BRANCH" = "dev" ] || [ "$BRANCH" = "main" ]; then
                                ENV="dev"
                            elif [ "$BRANCH" = "staging" ]; then
                                ENV="staging"
                            else
                                ENV="prod"
                            fi
                            
                            # Update backend values
                            cat > backend/overlays/$ENV/values.yaml << YAML
                            image:
                              tag: $GIT_SHA
                            YAML
                            
                            # Update frontend values
                            cat > frontend/overlays/$ENV/values.yaml << YAML
                            image:
                              tag: $GIT_SHA
                            YAML
                            
                            git config user.email "jenkins@ci.com"
                            git config user.name "Jenkins CI"
                            git add .
                            git commit -m "Update images to $GIT_SHA" || echo "No changes"
                            git push origin main
                        fi
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline successful! Deployed $GIT_SHA to K3s cluster"
            echo "🌐 Access at: http://${K3S_SERVER}:31047"
        }
        failure {
            echo "❌ Pipeline failed! Check logs above."
        }
    }
}
