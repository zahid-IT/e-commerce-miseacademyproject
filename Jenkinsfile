pipeline {
    agent {
        kubernetes {
            label 'kaniko-agent'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: kaniko-agent
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
                }
            }
        }

        stage('Build Backend') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=/workspace/backend \
                            --dockerfile=/workspace/backend/Dockerfile \
                            --destination=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA \
                            --destination=$REGISTRY/$BACKEND_IMAGE:latest \
                            --cache=true \
                            --cleanup=false
                    """
                }
            }
        }

        stage('Build Frontend') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=/workspace/frontend \
                            --dockerfile=/workspace/frontend/Dockerfile \
                            --destination=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA \
                            --destination=$REGISTRY/$FRONTEND_IMAGE:latest \
                            --cache=true \
                            --cleanup=false
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline successful! Images pushed with tag: $GIT_SHA"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
