pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                }
            }
        }

        stage('Docker Build & Push Backend') {
            steps {
                sh '''
                    docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                    docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                '''
            }
        }

        stage('Docker Build & Push Frontend') {
            steps {
                sh '''
                    docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA ./frontend
                    docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                '''
            }
        }
    }
}
