pipeline {

    agent {
        kubernetes {

            yaml '''
apiVersion: v1
kind: Pod

spec:
  restartPolicy: Never

  containers:

    - name: docker
      image: docker:24.0.5-cli
      command:
        - cat
      tty: true

      volumeMounts:
        - name: docker-sock
          mountPath: /var/run/docker.sock

    - name: jnlp
      image: jenkins/inbound-agent:latest
      tty: true

  volumes:
    - name: docker-sock
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
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Docker Login') {

            steps {

                container('docker') {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {

                        sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }
                }
            }
        }

        stage('Build Backend') {

            steps {

                container('docker') {

                    sh """
                    docker build -t ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA} ./backend

                    docker push ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA}
                    """
                }
            }
        }

        stage('Build Frontend') {

            steps {

                container('docker') {

                    sh """
                    docker build -t ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA} ./frontend

                    docker push ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA}
                    """
                }
            }
        }
    }
}
