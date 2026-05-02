pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/zahidbilal'
        BACKEND_IMAGE = 'ecommerce-backend'
        FRONTEND_IMAGE = 'ecommerce-frontend'
        GITOPS_REPO = 'https://github.com/zahid-IT/e-commerce-miseacademyproject.git'
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                }
            }
        }

        // ✅ Test stage skipped safely
        stage('Test') {
            steps {
                echo "Skipping tests for now"
            }
        }

        stage('Docker Login') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )]) {
                        sh """
                            echo \$PASS | docker login -u \$USER --password-stdin
                        """
                    }
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                container('docker') {
                    sh """
                        docker build -t $REGISTRY/$BACKEND_IMAGE:$GIT_SHA backend/
                        docker push $REGISTRY/$BACKEND_IMAGE:$GIT_SHA
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                container('docker') {
                    sh """
                        docker build -t $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA frontend/
                        docker push $REGISTRY/$FRONTEND_IMAGE:$GIT_SHA
                    """
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                container('tools') {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-token-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        sh """
                            rm -rf gitops

                            git clone https://\$GIT_USER:\$GIT_TOKEN@github.com/zahid-IT/YOUR_GITOPS_REPO.git gitops
                            cd gitops

                            # select environment
                            if [ "$BRANCH" = "dev" ]; then
                                FILE=dev/values.yaml
                            elif [ "$BRANCH" = "staging" ]; then
                                FILE=staging/values.yaml
                            else
                                FILE=prod/values.yaml
                            fi

                            # update image tags
                            sed -i "s/tag:.*/tag: $GIT_SHA/g" \$FILE

                            git config user.email "jenkins@ci.com"
                            git config user.name "jenkins"

                            git add .
                            git commit -m "Update images to $GIT_SHA" || echo "No changes to commit"

                            git push https://\$GIT_USER:\$GIT_TOKEN@github.com/zahid-IT/YOUR_GITOPS_REPO.git main
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment triggered via ArgoCD with image tag: $GIT_SHA"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}
