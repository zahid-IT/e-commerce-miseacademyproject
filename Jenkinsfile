pipeline {
    agent {
        kubernetes {
            label 'docker-pod'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ["$(JENKINS_SECRET)", "$(JENKINS_AGENT_NAME)"]
  - name: docker
    image: docker:20.10-dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
  - name: git
    image: alpine/git:latest
    command: ['cat']
    tty: true
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
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
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        """
                    }
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                container('docker') {
                    sh """
                        docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                        docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                    """
                }
            }
        }

        stage('Build Frontend Image') {
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
