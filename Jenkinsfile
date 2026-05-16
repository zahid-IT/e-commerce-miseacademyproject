pipeline {

    agent {
        kubernetes {

            yaml '''
apiVersion: v1
kind: Pod

spec:

  volumes:
    - name: docker-graph-storage
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
        - name: docker-graph-storage
          mountPath: /var/lib/docker

    - name: docker-cli
      image: docker:26-cli
      tty: true

      command:
        - cat

      env:
        - name: DOCKER_HOST
          value: tcp://localhost:2375

      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker

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

                    echo "Commit SHA: ${GIT_SHA}"
                }
            }
        }

        stage('Wait For Docker') {

            steps {

                container('docker-cli') {

                    sh '''
                    until docker info; do
                      echo "Waiting for Docker daemon..."
                      sleep 3
                    done
                    '''
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
                    docker build \
                      -t ${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA} \
                      -t ${REGISTRY}/${BACKEND_IMAGE}:latest \
                      backend

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
                    docker build \
                      -t ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA} \
                      -t ${REGISTRY}/${FRONTEND_IMAGE}:latest \
                      frontend

                    docker push ${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA}

                    docker push ${REGISTRY}/${FRONTEND_IMAGE}:latest
                    """
                }
            }
        }
    }

    post {

        success {

            echo "✅ Build completed successfully"
        }

        failure {

            echo "❌ Build failed"
        }
    }
}
