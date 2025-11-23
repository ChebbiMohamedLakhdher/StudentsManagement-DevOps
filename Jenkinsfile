pipeline {
    agent any
    tools {
        jdk 'jdk17'  // Correction : apostrophe droite et nom correct
        maven 'maven3' // Correction : apostrophe droite et nom correct
    }
    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/ChebbiMohamedLakhdher/StudentsManagement-DevOps.git'  // URL corrigée
            }
        }
        stage('Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }
    }
}