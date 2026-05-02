pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
        GITOPS_REPO = 'https://github.com/zahid-IT/e-commerce-miseacademyproject.git'
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                }
            }
        }

        stage('Test') {
            steps {
                echo "Skipping tests for now"
            }
        }

        stage('Docker Login') {
            steps {
                // Use Docker from host instead of a container
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        """
                    }
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                script {
                    sh """
                        docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                        docker tag $REGISTRY/$BACKEND_IMAGE:$GIT_SHA $REGISTRY/$BACKEND_IMAGE:latest
                        docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                        docker push $REGISTRY/$BACKEND_IMAGE:latest
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                script {
                    sh """
                        docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA ./frontend
                        docker tag $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA $REGISTRY/$FRONTEND_IMAGE:latest
                        docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                        docker push $REGISTRY/$FRONTEND_IMAGE:latest
                    """
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                script {
                    // Create GitOps repo structure if it doesn't exist
                    withCredentials([usernamePassword(
                        credentialsId: 'github-token-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh """
                            rm -rf gitops
                            
                            # Clone or create GitOps repo
                            if git ls-remote https://\$GIT_USER:\$GIT_TOKEN@github.com/zahid-IT/ecommerce-gitops.git; then
                                git clone https://\$GIT_USER:\$GIT_TOKEN@github.com/zahid-IT/ecommerce-gitops.git gitops
                            else
                                mkdir gitops && cd gitops && git init
                                git remote add origin https://\$GIT_USER:\$GIT_TOKEN@github.com/zahid-IT/ecommerce-gitops.git
                                cd ..
                            fi
                            
                            cd gitops
                            
                            # Create directory structure if not exists
                            mkdir -p backend/overlays/dev
                            mkdir -p backend/overlays/staging
                            mkdir -p backend/overlays/prod
                            mkdir -p frontend/overlays/dev
                            mkdir -p frontend/overlays/staging
                            mkdir -p frontend/overlays/prod
                            
                            # Determine environment based on branch
                            if [ "$BRANCH" = "dev" ] || [ "$BRANCH" = "main" ]; then
                                ENV="dev"
                            elif [ "$BRANCH" = "staging" ]; then
                                ENV="staging"
                            else
                                ENV="prod"
                            fi
                            
                            # Update backend values
                            cat > backend/overlays/\$ENV/values.yaml << YAML
                            image:
                              repository: $REGISTRY/$BACKEND_IMAGE
                              tag: $GIT_SHA
                            replicas: 1
                            YAML
                            
                            # Update frontend values
                            cat > frontend/overlays/\$ENV/values.yaml << YAML
                            image:
                              repository: $REGISTRY/$FRONTEND_IMAGE
                              tag: $GIT_SHA
                            replicas: 1
                            YAML
                            
                            # Create kustomization.yaml
                            cat > backend/overlays/\$ENV/kustomization.yaml << KUSTOMIZE
                            apiVersion: kustomize.config.k8s.io/v1beta1
                            kind: Kustomization
                            resources:
                              - ../../base
                            images:
                              - name: $REGISTRY/$BACKEND_IMAGE
                                newTag: $GIT_SHA
                            KUSTOMIZE
                            
                            git config user.email "jenkins@ci.com"
                            git config user.name "Jenkins CI"
                            git add .
                            git commit -m "Update images to $GIT_SHA" || echo "No changes to commit"
                            git push origin main
                        """
                    }
                }
            }
        }
        
        // Add ArgoCD sync stage
        stage('Sync ArgoCD') {
            steps {
                script {
                    withCredentials([string(
                        credentialsId: 'argocd-token',
                        variable: 'ARGOCD_TOKEN'
                    )]) {
                        sh """
                            # Sync ArgoCD application
                            argocd app sync ecommerce-backend --grpc-web
                            argocd app sync ecommerce-frontend --grpc-web
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! Image tag: $GIT_SHA"
            echo "📦 Images pushed to Docker Hub"
            echo "🚀 ArgoCD will sync automatically"
        }
        failure {
            echo "❌ Pipeline failed! Check the logs above."
        }
    }
}
