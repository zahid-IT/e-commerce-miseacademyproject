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

                    echo "Using image tag: ${GIT_SHA}"
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
                    --destination=${REGISTRY}/${BACKEND}:${GIT_SHA} \
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
                    --destination=${REGISTRY}/${FRONTEND}:${GIT_SHA} \
                    --cache=true
                    """
                }
            }
        }

        stage('Update GitOps Repo (ArgoCD Trigger)') {
            steps {
                sh """
                git clone https://github.com/zahid-IT/
                cd YOUR-GITOPS-REPO/helm/frontend

                sed -i 's/tag:.*/tag: ${GIT_SHA}/' values.yaml

                git config user.email "jenkins@local"
                git config user.name "jenkins"

                git add .
                git commit -m "Deploy frontend backend image: ${GIT_SHA}"
                git push
                """
            }
        }
    }

    post {
        success {
            echo "✅ Build + Push + GitOps Update completed (ArgoCD will deploy)"
        }

        failure {
            echo "❌ Pipeline failed"
        }
    }
}
