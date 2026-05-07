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

    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      command:
        - /busybox/cat
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

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
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.BRANCH = sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build Backend') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                      --context=/home/jenkins/agent/workspace/mise-project_main/backend \
                      --dockerfile=/home/jenkins/agent/workspace/mise-project_main/backend/Dockerfile \
                      --destination=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA \
                      --snapshot-mode=redo \
                      --use-new-run
                    """
                }
            }
        }

        stage('Build Frontend') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                      --context=/home/jenkins/agent/workspace/mise-project_main/frontend \
                      --dockerfile=/home/jenkins/agent/workspace/mise-project_main/frontend/Dockerfile \
                      --destination=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA \
                      --snapshot-mode=redo \
                      --use-new-run
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Images pushed successfully: $GIT_SHA"
        }

        failure {
            echo "❌ Pipeline failed"
        }
    }
}
