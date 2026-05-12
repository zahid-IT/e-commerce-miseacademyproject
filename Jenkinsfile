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
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.BRANCH = sh(
                        script: 'git branch --show-current || echo main',
                        returnStdout: true
                    ).trim()

                    env.BUILD_VERSION = "${BRANCH}-${GIT_SHA}"

                    echo "Branch: ${BRANCH}"
                    echo "Commit: ${GIT_SHA}"
                    echo "Build Version: ${BUILD_VERSION}"
                }
            }
        }

        stage('Build Backend Image') {
            steps {

                container('kaniko') {

                    sh """
                    /kaniko/executor \
                      --context=/home/jenkins/agent/workspace/mise-project_main/backend \
                      --dockerfile=/home/jenkins/agent/workspace/mise-project_main/backend/Dockerfile \
                      --destination=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA \
                      --destination=$REGISTRY/$BACKEND_IMAGE:latest \
                      --cache=false \
                      --snapshot-mode=redo \
                      --use-new-run
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {

                container('kaniko') {

                    sh """
                    /kaniko/executor \
                      --context=/home/jenkins/agent/workspace/mise-project_main/frontend \
                      --dockerfile=/home/jenkins/agent/workspace/mise-project_main/frontend/Dockerfile \
                      --destination=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA \
                      --destination=$REGISTRY/$FRONTEND_IMAGE:latest \
                      --cache=false \
                      --snapshot-mode=redo \
                      --use-new-run
                    """
                }
            }
        }
    }

    post {

        success {

            echo "====================================="
            echo "Images pushed successfully"
            echo "====================================="

            echo "Backend:"
            echo "$REGISTRY/$BACKEND_IMAGE:$GIT_SHA"

            echo "Frontend:"
            echo "$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA"
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
