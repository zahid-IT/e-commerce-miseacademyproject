pipeline {

    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      command: ["sleep", "infinity"]
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

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
        REGISTRY = "docker.io/zahidbilal"
        BACKEND = "ecommerce-backend"
        FRONTEND = "ecommerce-frontend"
        TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                    --context=${WORKSPACE}/backend \
                    --dockerfile=${WORKSPACE}/backend/Dockerfile \
                    --destination=${REGISTRY}/${BACKEND}:${TAG} \
                    --destination=${REGISTRY}/${BACKEND}:latest \
                    --cache=true
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
                    --destination=${REGISTRY}/${FRONTEND}:${TAG} \
                    --destination=${REGISTRY}/${FRONTEND}:latest \
                    --cache=true
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Images built successfully with Kaniko"
        }

        failure {
            echo "❌ Build failed"
        }
    }
}
