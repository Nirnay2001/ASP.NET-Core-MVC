pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/Nirnay2001/ASP.NET-Core-MVC.git'
        ec2_ip = '100.27.190.169'
        repo_name = 'ASP.NET-Core-MVC'
        container_name = 'app02'
    }

    stages {

        stage('Pull repository') {
            steps {
                sshagent(['ec2-ssh']) {
                    script {
                        def repoExists = sh(
                            script: "ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} 'ls ~/${repo_name}'",
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

        stage('Docker Build') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} 'cd ~/${repo_name} && sudo docker build -t ${container_name} .'"
                }
            }

            post {
                success {
                    echo "Docker image ${container_name}:latest built successfully on EC2."
                }
                failure {
                    echo "Failed to build Docker image ${container_name}:latest."
                }
            }
        }

        stage('Docker Run') {
            steps {
                sshagent(['ec2-ssh']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} '
                    sudo docker stop ${container_name} || true
                    sudo docker rm ${container_name} || true
                    cd ~/${repo_name}
                    sudo docker run -d --name ${container_name} -p 80:9090 ${container_name}
                    '
                    """
                }
            }

            post {
                success {
                    echo "Docker container ${container_name} started successfully."
                }
                failure {
                    echo "Failed to start Docker container."
                }
            }
        }

        stage('Verify Docker Container') {
            steps {
                sshagent(['ec2-ssh']) {
                    script {
                        def containers = sh(
                            script: """
                            ssh -o StrictHostKeyChecking=no ubuntu@${ec2_ip} 'sudo docker ps --format "{{.Names}}"'
                            """,
                            returnStdout: true
                        ).trim()

                        assert containers.contains("${container_name}") : "Container ${container_name} is not running."
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
                        error "Frontend returned HTTP ${response}"
                    }
                }
            }
        }
    }
}