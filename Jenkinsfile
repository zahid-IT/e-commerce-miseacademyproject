pipeline {
    agent {
        kubernetes {
            label 'docker-agent'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-storage
      mountPath: /var/lib/docker
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
  volumes:
  - name: docker-storage
    emptyDir: {}
  - name: workspace
    emptyDir: {}
'''
        }
    }

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
                    env.BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                }
            }
        }

        stage('Docker Login') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    }
                }
            }
        }

        stage('Build Backend') {
            steps {
                container('docker') {
                    sh """
                        docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                        docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                    """
                }
            }
        }

        stage('Build Frontend') {
            steps {
                container('docker') {
                    sh """
                        docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA ./frontend
                        docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                    """
                }
            }
        }
    }
}
