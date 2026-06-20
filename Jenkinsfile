pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/Nirnay2001/ASP.NET-Core-MVC.git'
        ec2_ip = '54.196.204.240'
        repo_name = 'ASP.NET-Core-MVC'
        container_name = 'MVC'
    }

    stages {

        stage('Pull repository') {
            steps {
                sshagent(['ec2-ssh']) {
                    script {
                        def repoExists = sh(
                            script: "ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} 'test -d ~/${repo_name}'",
                            returnStatus: true
                        ) == 0

                        if (repoExists) {
                            sh "ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} 'cd ~/${repo_name} && git pull origin main'"
                        } else {
                            sh "ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} 'git clone ${GIT_REPO} ~/${repo_name}'"
                        }
                    }
                }
            }
        }

        stage('Docker compose down and remove old images') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} \
                        'cd ~/${repo_name} && sudo docker compose down || true'
                    """

                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} \
                        'sudo docker images -aq | xargs -r sudo docker rmi -f'
                    """
                }
            }
        }

        stage('Docker build') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} \
                        'cd ~/${repo_name} && sudo docker compose build'
                    """
                }
            }
        }
        stage('Docker run') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} \
                        'cd ~/${repo_name} && sudo docker compose up -d'
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
                                ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} \
                                'sudo docker ps --format "{{.Names}}"'
                            """,
                            returnStdout: true
                        ).trim()

                        if (!containers.contains(container_name)) {
                            error("Container ${container_name} is not running.")
                        }

                        echo "Container ${container_name} is running."
                    }
                }
            }
        }

        stage('Frontend Verification') {
            steps {
                script {
                    def response = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://${ec2_ip}",
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
        success {
            echo 'Deployment Successful!'
        }

        failure {
            echo 'Deployment Failed!'
        }
    }
}