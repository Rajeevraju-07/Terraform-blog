#!/bin/bash -xe
    cd /tmp
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install fontconfig openjdk-11-jre -y
    sudo apt-get install jenkins -y
    cd /var/lib/jenkins
    sudo -u jenkins touch jenkins.install.UpgradeWizard.state
    sudo chmod 777 jenkins.install.UpgradeWizard.state
    sudo -u jenkins echo "2.0" >> jenkins.install.UpgradeWizard.state
    sudo -u jenkins mkdir init.groovy.d
    cd init.groovy.d
    sudo -u jenkins touch basic-security.groovy
    sudo chmod 777 basic-security.groovy
    cat << EOF >> basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

println "--> creating local user 'admin'"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin','admin')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()
EOF

sudo systemctl restart jenkins

cd /
sudo git clone #git credentials
cd Repo

sudo wget http://localhost:8080/jnlpJars/jenkins-cli.jar

sudo chmod 777 jenkins-cli.jar

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth 'admin:admin' -webSocket install-plugin workflow-job

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth 'admin:admin' -webSocket install-plugin workflow-aggregator

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth 'admin:admin' -webSocket install-plugin Git
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth 'admin:admin' -webSocket install-plugin github

sudo systemctl restart jenkins

java -jar jenkins-cli.jar -s http://localhost:8080/ -auth 'admin:admin' -webSocket create-job new-pipeline < job.xml
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth 'admin:admin' -webSocket build new-pipeline
 
   
      
      