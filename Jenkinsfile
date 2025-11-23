pipeline {

 agent any

 tools {jdk 'JAVA_HOME’, maven 'M2_HOME'}

 stages {

 stage('GIT') {

           steps {

               git branch: 'main',

               url: ' https://https://github.com/ChebbiMohamedLakhdher/StudentsManagement-DevOps.git '

          }

     }

 stage ('Compile Stage') {

 steps {

 sh 'mvn clean compile'

 }

 }

 