pipeline { 

    agent any 

 tools { 

    maven "maven3" 

    terraform "terraform" 

  } 

  environment { 

    MAVEN_HOME = tool('maven3') 

   key_path= "${env.WORKSPACE}/infra/pem_file.pem" 

   ANSIBLE_HOSTS="ansible/hosts" 

   war_file_path="${env.WORKSPACE}/target/newapp.war" 

  } 

    stages { 

          stage('clean workspace'){

            steps{

             cleanWs()   

            }

        }

        stage('check out from github') { 

            steps { 

           checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/Arjunpuneeth/my-app.git']])

            } 

        } 


            stage('build') { 

      steps { 

        sh "${MAVEN_HOME}/bin/mvn package" 

        sh 'mv target/myweb*.war target/newapp.war' 

      } 

    } 

 stage('Build Docker Image') { 

      steps { 

        sh 'docker build -t arjunpuneeth/myweb:0.0.6 .' 

      } 

    } 

    stage('Docker Image Push') { 



      steps { 

        script

        {

        withDockerRegistry(credentialsId: 'docker_id') 

        {



        sh 'docker push arjunpuneeth/myweb:0.0.6'

        }

      } 

      }

    } 


  stage('Remove Previous Container') { 
      steps { 

        script { 

          try { 

            sh 'docker rm -f tomcattest' 

          } catch (error) { 

            //  do nothing if there is an exception 

          } 

        }
      }  
    } 

    stage('Docker deployment') { 

      steps { 

        sh 'docker run -d -p 8083:8080 --name tomcattest2 arjunpuneeth/myweb:0.0.6' 

      } 

    } 

   stage('Checkout infracode') { 
            steps { 

                script { 
                    dir('infra') { 

                        checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/Arjunpuneeth/Terraform-ansiable.git']])

                    } 

                } 

            } 

          } 
        
   stage('Terraform Apply') {
            steps {
                dir('infra') {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws_id', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh 'terraform init'
                        // This command now passes the value to the declared variable
                        sh "terraform apply -auto-approve -var='build_suffix=${env.BUILD_NUMBER}'"
                        sh 'chmod 400 pem_file.pem'
                    }
                }
            }
        }

stage('Generate Ansible Inventory') { 



    steps { 

        script { 

             dir('infra') { 

            def instance_ip = sh(script: "terraform output -raw instance_public_ip", returnStdout: true).trim() 

             def key_path = sh(script: "terraform output -raw ssh_private_key_path", returnStdout: true).trim() 

            echo "${instance_ip}" 

            writeFile file: 'ansible/hosts', text: """ 

            [ubuntu_servers] 

            ${instance_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${key_path} ansible_ssh_common_args='-o StrictHostKeyChecking=no' 

            """
        } 
        } 
    } 
} 

 stage('Configure Server with Ansible') { 

           steps { 

                 dir('infra') { 
                  script { 
                    sh 'ansible-playbook -i ${ANSIBLE_HOSTS} ansible/tomcat.yaml' 

                } 

             } 
         } 
    } 


  stage('Deploy Application') { 

            steps { 

                script { 

                    dir('infra') { 

                        def instance_ip = sh(script: "terraform output -raw instance_public_ip", returnStdout: true).trim() 
  
                      //   ssh -i ${key_path} ubuntu@${instance_ip} 'sudo chmod -R 777 /opt/tomcat/webapps/' 

                      sh """ 

                      ssh -i ${key_path} ubuntu@${instance_ip} 'sudo chmod -R 777 /opt/tomcat/webapps/' &&  

                        scp -i ${key_path} -o StrictHostKeyChecking=no ${war_file_path} ubuntu@${instance_ip}:/opt/tomcat/webapps/ 

                         """ 

                } 

                } 

            } 

        } 

    } 

}
