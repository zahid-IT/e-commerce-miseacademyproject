pipeline {

    agent {
        kubernetes {

            yaml '''
apiVersion: v1
kind: Pod

spec:

  volumes:
    - name: docker-sock
      emptyDir: {}

  containers:

    - name: docker
      image: docker:26-dind
      securityContext:
        privileged: true
      tty: true

      command:
        - dockerd-entrypoint.sh

      args:
        - --host=tcp://0.0.0.0:2375
        - --tls=false

      volumeMounts:
        - name: docker-sock
          mountPath: /var/run

    - name: docker-cli
      image: docker:26-cli
      tty: true

      command:
        - cat

      env:
        - name: DOCKER_HOST
          value: tcp://localhost:2375

      volumeMounts:
        - name: docker-sock
          mountPath: /var/run

    - name: jnlp
      image: jenkins/inbound-agent:latest
'''
        }
    }

    environment {

        REGISTRY = "docker.io/zahidbilal"

        BACKEND_IMAGE = "ecommerce-backend"

        FRONTEND_IMAGE = "ecommerce-frontend"
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

                container('docker-cli') {

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

                container('docker-cli') {

                    sh """
                    docker build -t ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA} backend

                    docker tag ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA} \
                               ${REGISTRY}/${BACKEND_IMAGE}:latest

                    docker push ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA}

                    docker push ${REGISTRY}/${BACKEND_IMAGE}:latest
                    """
                }
            }
        }

        stage('Build Frontend') {

            steps {

                container('docker-cli') {

                    sh """
                    docker build -t ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA} frontend

                    docker tag ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA} \
                               ${REGISTRY}/${FRONTEND_IMAGE}:latest

                    docker push ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA}

                    docker push ${REGISTRY}/${FRONTEND_IMAGE}:latest
                    """
                }
            }
        }
    }

    post {

        success {

            echo "✅ Build completed"
        }

        failure {

            echo "❌ Build failed"
        }
    }
}
