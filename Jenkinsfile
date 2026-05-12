pipeline {
    agent {
        kubernetes {
            label 'kaniko-pod'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.2-debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
    - name: workspace
      mountPath: /workspace
  - name: jnlp
    image: jenkins/inbound-agent:latest
    volumeMounts:
    - name: workspace
      mountPath: /home/jenkins/agent
  volumes:
  - name: docker-config
    secret:
      secretName: dockerhub-secret
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
                    echo "Branch: ${env.BRANCH}, Commit: ${env.GIT_SHA}"
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=/workspace/backend \
                            --dockerfile=/workspace/backend/Dockerfile \
                            --destination=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA \
                            --destination=$REGISTRY/$BACKEND_IMAGE:latest \
                            --cache=true \
                            --cache-repo=$REGISTRY/$BACKEND_IMAGE-cache \
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
                            --context=/workspace/frontend \
                            --dockerfile=/workspace/frontend/Dockerfile \
                            --destination=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA \
                            --destination=$REGISTRY/$FRONTEND_IMAGE:latest \
                            --cache=true \
                            --cache-repo=$REGISTRY/$FRONTEND_IMAGE-cache \
                            --cleanup
                    """
                }
            }
        }

        stage('Fix package-lock.json for Backend') {
            steps {
                container('kaniko') {
                    sh """
                        cd /workspace/backend
                        if [ ! -f package-lock.json ]; then
                            npm install --package-lock-only --legacy-peer-deps
                        fi
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "📦 Images pushed:"
            echo "  Backend: $REGISTRY/$BACKEND_IMAGE:$GIT_SHA"
            echo "  Frontend: $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
