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
      image: gcr.io/kaniko-project/executor:latest
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
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "250m"
          memory: "256Mi"

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
        REGISTRY        = 'docker.io/zahidbilal'
        BACKEND_IMAGE   = 'ecommerce-backend'
        FRONTEND_IMAGE  = 'ecommerce-frontend'
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
}
    

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.GIT_SHA = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.BRANCH = sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()

                    env.BUILD_TAG = "${BRANCH}-${GIT_SHA}"

                    echo "Branch: ${BRANCH}"
                    echo "Commit: ${GIT_SHA}"
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
                      --cache=true \
                      --cache-copy-layers \
                      --compressed-caching=false \
                      --cleanup
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
                      --cache=true \
                      --cache-copy-layers \
                      --compressed-caching=false \
                      --cleanup
                    """
                }
            }
        }
    }

    post {

        success {
            echo "✅ Backend Image:"
            echo "$REGISTRY/$BACKEND_IMAGE:$GIT_SHA"

            echo "✅ Frontend Image:"
            echo "$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA"

            echo "🚀 Pipeline completed successfully"
        }

        failure {
            echo "❌ Pipeline failed"
        }

        always {
            cleanWs()
        }
    }
}
