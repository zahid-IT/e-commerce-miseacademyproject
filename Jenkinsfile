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

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Build Backend') {
            steps {
                sh """
                    docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                    docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                """
            }
        }

        stage('Build Frontend') {
            steps {
                sh """
                    docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA ./frontend
                    docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                """
            }
        }
    }
}
