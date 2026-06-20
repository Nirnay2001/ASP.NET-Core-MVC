pipeline {
    agent any

    environment {
        GIT_REPO     = 'https://github.com/Nirnay2001/ASP.NET-Core-MVC.git'
        EC2_IP       = '34.228.60.131'
        REPO_NAME    = 'ASP.NET-Core-MVC'
        IMAGE_NAME   = 'MVC'
        DOCKERHUB_IMAGE_NAME = 'nirnay2001/mvc_project'
    }

    stages {

        stage('Pull Repository') {
            steps {
                sh """
                    if [ -d "${REPO_NAME}" ]; then
                        cd ${REPO_NAME}
                        git pull origin main
                    else
                        git clone ${GIT_REPO}
                    fi
                """
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    cd ${REPO_NAME}
                    docker build -t ${DOCKERHUB_IMAGE_NAME} .
                    
                """
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USERNAME',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    sh """
                        echo \$DOCKERHUB_PASSWORD | docker login -u \$DOCKERHUB_USERNAME --password-stdin
                        docker push ${DOCKERHUB_IMAGE_NAME}
                    """
                }
            }
        }

        stage('Copy Compose File To EC2') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} 'mkdir -p ~/${REPO_NAME}'
                        scp -o StrictHostKeyChecking=no \
                            ${REPO_NAME}/docker-compose.yml \
                            ubuntu@${EC2_IP}:~/${REPO_NAME}/
                    """
                }
            }
        }

        stage('Docker Compose Down') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                            cd ~/${REPO_NAME}
                            sudo docker compose down || true
                        '
                    """
                }
            }
        }

        stage('Deploy To EC2') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                            cd ~/${REPO_NAME}
                            sudo docker compose pull
                            sudo docker compose up -d
                        '
                    """
                }
            }
        }

        stage('Verify Docker Container') {
            steps {
                sshagent(['ec2-ssh']) {
                    script {
                        sleep(time: 20, unit: 'SECONDS')

                        def containers = sh(
                            script: """
                                ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} \
                                'sudo docker ps --format "{{.Names}}"'
                            """,
                            returnStdout: true
                        ).trim()

                        assert containers.contains(IMAGE_NAME), "Container ${IMAGE_NAME} is not running. Current containers: ${containers}"
                    }
                }
            }
        }

        stage('Frontend Verification') {
            steps {
                script {
                    def response = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://${EC2_IP}",
                        returnStdout: true
                    ).trim()

                    if (response == '200') {
                        echo "Frontend is accessible."
                    } else {
                        error("Frontend returned HTTP ${response}")
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh "docker logout || true"
        }
        success {
            echo 'Deployment Successful!'
        }
        failure {
            echo 'Deployment Failed!'
        }
    }
}