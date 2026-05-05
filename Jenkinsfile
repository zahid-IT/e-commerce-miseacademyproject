pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
        GIT_REPO = 'https://github.com/your-org/your-repo'  # Your Git repo URL
        GIT_BRANCH = 'main'  # Branch ArgoCD watches
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

        stage('Update Git Manifests (Trigger ArgoCD)') {
            steps {
                script {
                    // Check if we should auto-update Git or just wait for ArgoCD sync
                    sh '''
                        # Clone the Git repo containing Kubernetes manifests
                        git clone $GIT_REPO /tmp/manifests-repo || true
                        cd /tmp/manifests-repo
                        git checkout $GIT_BRANCH
                        
                        # Update image tags in the manifest files
                        sed -i "s|image: $REGISTRY/$BACKEND_IMAGE:.*|image: $REGISTRY/$BACKEND_IMAGE:$GIT_SHA|g" k8s/backend-deployment.yaml
                        sed -i "s|image: $REGISTRY/$FRONTEND_IMAGE:.*|image: $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA|g" k8s/frontend-deployment.yaml
                        
                        # Commit and push changes
                        git config user.email "jenkins@your-domain.com"
                        git config user.name "Jenkins CI"
                        git add .
                        git commit -m "Update images to $GIT_SHA [skip ci]" || echo "No changes to commit"
                        git push origin $GIT_BRANCH
                        
                        echo "✅ Git manifests updated. ArgoCD will auto-sync within 3 minutes."
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline successful!"
            echo "📦 Images pushed:"
            echo "   - ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA}"
            echo "   - ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA}"
            echo "📝 Git manifests updated. ArgoCD will deploy to K3s automatically."
            echo "🔗 Check ArgoCD UI at: https://<your-k3s-ip>:30443"
        }
        failure {
            echo "❌ Pipeline failed! Check logs above."
        }
    }
}
    }
}
