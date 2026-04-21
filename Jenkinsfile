#pipeline {
#    agent any
#    
#    environment {
#        DOCKER_REGISTRY = docker push zahidbilal/e-commerce-miseacademyproject
#        GITOPS_REPO = https://github.com/zahid-IT/e-commerce-miseacademyproject.git
        
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = zahidbilal/e-commerce-miseacademyproject
        GITOPS_REPO = https://github.com/zahid-IT/e-commerce-miseacademyproject.git
        
        DEV_BRANCH = 'main'
        STAGING_BRANCH = 'staging'
        PROD_BRANCH = 'production'
        
        // MongoDB specific
        MONGODB_VERSION = '5.0'
    }
    
    stages {
        stage('Determine Environment') {
            steps {
                script {
                    switch(env.BRANCH_NAME) {
                        case env.DEV_BRANCH:
                            env.DEPLOY_ENV = 'dev'
                            env.IMAGE_TAG = "${env.BUILD_NUMBER}-dev"
                            env.MONGODB_ARCHITECTURE = 'standalone'
                            break
                        case env.STAGING_BRANCH:
                            env.DEPLOY_ENV = 'staging'
                            env.IMAGE_TAG = "${env.BUILD_NUMBER}-staging"
                            env.MONGODB_ARCHITECTURE = 'replicaset'
                            break
                        case env.PROD_BRANCH:
                            env.DEPLOY_ENV = 'production'
                            env.IMAGE_TAG = "${env.BUILD_NUMBER}-prod"
                            env.MONGODB_ARCHITECTURE = 'external'
                            break
                        default:
                            error "Unsupported branch: ${env.BRANCH_NAME}"
                    }
                }
            }
        }
        
        stage('Build Backend Image') {
            steps {
                dir('backend') {
                    sh """
                        docker build \
                            --build-arg NODE_ENV=${env.DEPLOY_ENV} \
                            -t ${DOCKER_REGISTRY}/backend:${env.IMAGE_TAG} \
                            -t ${DOCKER_REGISTRY}/backend:${env.DEPLOY_ENV}-latest \
                            .
                        docker push ${DOCKER_REGISTRY}/backend:${env.IMAGE_TAG}
                        docker push ${DOCKER_REGISTRY}/backend:${env.DEPLOY_ENV}-latest
                    """
                }
            }
        }
        
        stage('Initialize MongoDB Database') {
            when { 
                expression { env.DEPLOY_ENV != 'production' } 
            }
            steps {
                script {
                    dir('backend') {
                        sh """
                            # Wait for MongoDB to be ready
                            kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mongodb \
                                -n ecommerce-${env.DEPLOY_ENV} --timeout=300s
                            
                            # Run initialization script
                            kubectl exec -n ecommerce-${env.DEPLOY_ENV} \
                                deployment/backend -- \
                                node scripts/init-mongodb.js
                        """
                    }
                }
            }
        }
        
        stage('Update GitOps Repository') {
            steps {
                script {
                    sh """
                        git clone ${GITOPS_REPO} gitops-temp
                        cd gitops-temp
                        
                        # Update values with MongoDB configuration
                        yq eval '.mongodb.architecture = "${env.MONGODB_ARCHITECTURE}"' -i environments/${env.DEPLOY_ENV}/values.yaml
                        yq eval '.backend.image.tag = "${env.IMAGE_TAG}"' -i environments/${env.DEPLOY_ENV}/values.yaml
                        
                        git config user.email "jenkins@example.com"
                        git config user.name "Jenkins CI"
                        git add .
                        git commit -m "Deploy ecommerce ${env.IMAGE_TAG} to ${env.DEPLOY_ENV} with MongoDB"
                        git push
                    """
                }
            }
        }
    }
}
