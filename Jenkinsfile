pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build and Push') {
            steps {
                script {
                    def GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            docker build -t docker.io/zahidbilal/ecommerce-backend:\${GIT_SHA} ./backend
                            docker tag docker.io/zahidbilal/ecommerce-backend:\${GIT_SHA} docker.io/zahidbilal/ecommerce-backend:latest
                            docker push docker.io/zahidbilal/ecommerce-backend:\${GIT_SHA}
                            docker push docker.io/zahidbilal/ecommerce-backend:latest
                            
                            docker build -t docker.io/zahidbilal/ecommerce-frontend:\${GIT_SHA} ./frontend
                            docker tag docker.io/zahidbilal/ecommerce-frontend:\${GIT_SHA} docker.io/zahidbilal/ecommerce-frontend:latest
                            docker push docker.io/zahidbilal/ecommerce-frontend:\${GIT_SHA}
                            docker push docker.io/zahidbilal/ecommerce-frontend:latest
                            
                            echo "✅ Built and pushed: \${GIT_SHA}"
                        """
                    }
                }
            }
        }
    }
}
