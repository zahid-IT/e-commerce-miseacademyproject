pipeline {

    agent {
        kubernetes {

            defaultContainer 'jnlp'

            yaml '''
apiVersion: v1
kind: Pod

spec:
  restartPolicy: Never

  volumes:
    - name: docker-config
      secret:
        secretName: dockerhub-secret
        items:
          - key: .dockerconfigjson
            path: config.json

    - name: workspace-volume
      emptyDir: {}

  containers:

    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      tty: true

      command:
        - /busybox/sh

      args:
        - -c
        - cat

      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: jnlp
      image: jenkins/inbound-agent:latest
      tty: true

      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
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

                    echo "Commit: ${env.GIT_SHA}"
                }
            }
        }

        stage('Build Backend') {

            steps {

                container('kaniko') {

                    sh """
                    /kaniko/executor \
                      --context=${WORKSPACE}/backend \
                      --dockerfile=${WORKSPACE}/backend/Dockerfile \
                      --destination=${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA} \
                      --destination=${REGISTRY}/${BACKEND_IMAGE}:latest \
                      --cache=false \
                      --skip-unused-stages
                    """
                }
            }
        }

        stage('Build Frontend') {

            steps {

                container('kaniko') {

                    sh """
                    /kaniko/executor \
                      --context=${WORKSPACE}/frontend \
                      --dockerfile=${WORKSPACE}/frontend/Dockerfile \
                      --destination=${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA} \
                      --destination=${REGISTRY}/${FRONTEND_IMAGE}:latest \
                      --cache=false \
                      --skip-unused-stages
                    """
                }
            }
        }
    }

    post {

        success {
            echo "✅ Pipeline completed successfully"
        }

        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
