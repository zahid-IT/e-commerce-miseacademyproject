pipeline {
    agent {
        kubernetes {
            inheritFrom 'default'

            yaml '''
apiVersion: v1
kind: Pod

spec:
  restartPolicy: Never

  containers:

    - name: jnlp
      image: jenkins/inbound-agent:latest
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"

    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      command:
        - /busybox/cat
      tty: true

      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
        limits:
          cpu: "1"
          memory: "2Gi"

    - name: git
      image: alpine/git:latest
      command:
        - cat
      tty: true

  volumes:
    - name: docker-config
      secret:
        secretName: dockerhub-secret
        items:
          - key: .dockerconfigjson
            path: config.json
'''
        }
    }

    environment {
        REGISTRY       = 'docker.io/zahidbilal'
        BACKEND_IMAGE  = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm

                script {

                    env.GIT_SHA = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.BRANCH = env.BRANCH_NAME ?: "main"

                    env.BUILD_VERSION = "${env.BRANCH}-${env.GIT_SHA}"

                    echo "====================================="
                    echo "Branch: ${env.BRANCH}"
                    echo "Commit: ${env.GIT_SHA}"
                    echo "Build Version: ${env.BUILD_VERSION}"
                    echo "====================================="
                }
            }
        }

        stage('Build Backend Image') {
            steps {

                container('kaniko') {

                    sh """
                    /kaniko/executor \
                      --context=${WORKSPACE}/backend \
                      --dockerfile=${WORKSPACE}/backend/Dockerfile \
                      --destination=${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA} \
                      --destination=${REGISTRY}/${BACKEND_IMAGE}:latest \
                      --cache=false \
                      --snapshot-mode=redo
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {

                container('kaniko') {

                    sh """
                    /kaniko/executor \
                      --context=${WORKSPACE}/frontend \
                      --dockerfile=${WORKSPACE}/frontend/Dockerfile \
                      --destination=${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA} \
                      --destination=${REGISTRY}/${FRONTEND_IMAGE}:latest \
                      --cache=false \
                      --snapshot-mode=redo \
                      --skip-unused-stages
                    """
                }
            }
        }
    }

    post {

        success {

            echo "====================================="
            echo "Pipeline completed successfully"
            echo ""
            echo "Backend Image:"
            echo "${REGISTRY}/${BACKEND_IMAGE}:${GIT_SHA}"
            echo ""
            echo "Frontend Image:"
            echo "${REGISTRY}/${FRONTEND_IMAGE}:${GIT_SHA}"
            echo "====================================="
        }

        failure {

            echo "====================================="
            echo "Pipeline failed"
            echo "====================================="
        }

        always {

            echo "Cleaning workspace..."
            deleteDir()
        }
    }
}
