pipeline {
    agent {
        kubernetes {
            label 'kaniko-agent'
            yaml '''
apiVersion: v1
kind: Pod
spec:
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
        GITOPS_REPO = 'https://github.com/zahid-IT/e-commerce-miseacademyproject.git'
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
                      --context=dir://backend \
                      --dockerfile=backend/Dockerfile \
                      --destination=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA \
                      --cleanup
                    """
                }
            }
        }

        stage('Build Frontend') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                      --context=dir://frontend \
                      --dockerfile=frontend/Dockerfile \
                      --destination=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA \
                      --cleanup
                    """
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                container('git') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-token-creds',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {

                        sh """
                        rm -rf gitops

                        git clone https://$GIT_USER:$GIT_TOKEN@github.com/zahid-IT/e-commerce-miseacademyproject.git gitops

                        cd gitops

                        if [ "$BRANCH" = "dev" ]; then
                            FILE=dev/values.yaml
                        elif [ "$BRANCH" = "staging" ]; then
                            FILE=staging/values.yaml
                        else
                            FILE=prod/values.yaml
                        fi

                        sed -i "s/tag:.*/tag: $GIT_SHA/g" \$FILE

                        git config user.email "jenkins@ci.com"
                        git config user.name "jenkins"

                        git add .

                        git commit -m "Update image tag to $GIT_SHA" || echo "No changes"

                        git push origin main
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build + GitOps update successful: $GIT_SHA"
        }

        failure {
            echo "❌ Pipeline failed"
        }
    }
}
