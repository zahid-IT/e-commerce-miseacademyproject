pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
        GITOPS_REPO = 'https://github.com/zahid-IT/YOUR_GITOPS_REPO.git'
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

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                    docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA ./backend
                    docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                    docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA ./frontend
                    docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                '''
            }
        }

        stage('Update GitOps Repo') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh '''
                        rm -rf gitops
                        git clone https://$GIT_USER:$GIT_TOKEN@github.com/zahid-IT/YOUR_GITOPS_REPO.git gitops
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
                        git commit -m "Update images to $GIT_SHA" || echo "No changes"

                        git push https://$GIT_USER:$GIT_TOKEN@github.com/zahid-IT/YOUR_GITOPS_REPO.git main
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Build + GitOps update successful: $GIT_SHA"
        }
        failure {
            echo "Pipeline failed"
        }
    }
}
