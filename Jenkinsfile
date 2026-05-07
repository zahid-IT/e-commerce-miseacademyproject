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
    image: gcr.io/kaniko-project/executor:v1.23.2
    command: ["sleep", "999999"]
    tty: true

  - name: git
    image: alpine/git:latest
    command: ["cat"]
    tty: true
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
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                }
            }
        }

        stage('Build Backend (Kaniko)') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                        --context=dir://backend \
                        --dockerfile=Dockerfile \
                        --destination=$REGISTRY/$BACKEND_IMAGE:$GIT_SHA \
                        --cleanup
                    """
                }
            }
        }

        stage('Build Frontend (Kaniko)') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                        --context=dir://frontend \
                        --dockerfile=Dockerfile \
                        --destination=$REGISTRY/$FRONTEND_IMAGE:$GIT_SHA \
                        --cleanup
                    """
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                container('git') {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-token-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
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

                        sed -i "s/tag:.*/tag: $GIT_SHA/g" $FILE

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
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build and Push') {
            steps {
                script {
                    def GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            docker build -t docker.io/zahidbilal/ecommerce-backend:\${GIT_SHA} ./backend
                            docker tag docker.io/zahidbilal/ecommerce-backend:\${GIT_SHA} docker.io/zahidbilal/ecommerce-backend:latest
                            docker push docker.io/zahidbilal/ecommerce-backend:\${GIT_SHA}
                            docker push docker.io/zahidbilal/ecommerce-backend:latest
                            
                            docker build -t docker.io/zahidbilal/ecommerce-frontend:\${GIT_SHA} ./frontend
                            docker tag docker.io/zahidbilal/ecommerce-frontend:\${GIT_SHA} docker.io/zahidbilal/ecommerce-frontend:latest
                            docker push docker.io/zahidbilal/ecommerce-frontend:\${GIT_SHA}
                            docker push docker.io/zahidbilal/ecommerce-frontend:latest
                            
                            echo "✅ Built and pushed: \${GIT_SHA}"
                        """
                    }
                }
            }
        }
    }
}
