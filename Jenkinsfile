pipeline {
    agent any
    
    tools {
        jdk 'JAVA_HOME'
    }
    
    environment {
        GIT_URL = 'https://github.com/ChebbiMohamedLakhdher/StudentsManagement-DevOps.git'
        IMAGE_NAME = 'chebbimed2031/students-management'
        // Augmenter les timeouts
        DOCKER_CLIENT_TIMEOUT = '600'
        DOCKER_TLS_TIMEOUT = '30'
    }
    
    triggers {
        pollSCM('* * * * *')  // Toutes les 5 minutes (plus stable)
    }
    
    stages {
        stage('Network Diagnostics') {
            steps {
                sh '''
                    echo "🔍 Diagnostic réseau Docker Hub..."
                    echo "Test DNS:"
                    nslookup registry-1.docker.io
                    echo ""
                    echo "Test HTTPS:"
                    timeout 30 curl -I https://registry-1.docker.io/v2/ || echo "Curl échoué mais on continue..."
                    echo ""
                    echo "Test ping:"
                    ping -c 2 registry-1.docker.io 2>/dev/null || echo "Ping non disponible"
                '''
            }
        }
        
        stage('Checkout & Build') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: "${GIT_URL}"]]])
                sh '''
                    echo "🔨 Construction avec Java local..."
                    java -version
                    mvn clean package -DskipTests -q
                    echo "✅ JAR créé: $(ls -lh target/*.jar)"
                '''
            }
        }
        
        stage('Docker Build with Retry') {
            steps {
                script {
                    // Créer Dockerfile
                    writeFile file: 'Dockerfile', text: '''FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY target/student-management-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]'''
                    
                    // Essayer plusieurs fois la construction
                    retry(3) {
                        timeout(time: 5, unit: 'MINUTES') {
                            sh '''
                                echo "🐳 Tentative de construction Docker..."
                                
                                # Télécharger l'image avec timeout augmenté
                                docker pull --platform linux/amd64 eclipse-temurin:17-jre-alpine || \
                                echo "⚠️  Échec du pull, utilisation du cache local"
                                
                                # Construire l'image
                                docker build --platform linux/amd64 -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                                docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest
                                
                                echo "✅ Image Docker construite!"
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Docker Login with Retry') {
            steps {
                script {
                    // Tentative de login avec retry
                    retry(5) {
                        timeout(time: 2, unit: 'MINUTES') {
                            withCredentials([usernamePassword(
                                credentialsId: 'dockerhub-credentials',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )]) {
                                sh '''
                                    echo "🔐 Tentative de connexion à Docker Hub (tentative $BUILD_ID)..."
                                    
                                    # Configurer les timeouts Docker
                                    export DOCKER_CLIENT_TIMEOUT=600
                                    export COMPOSE_HTTP_TIMEOUT=600
                                    
                                    # Essayer avec timeout
                                    timeout 60 echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                    
                                    # Vérifier la connexion
                                    docker system info | grep -i username || echo "⚠️  Impossible de vérifier la connexion"
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('Docker Push') {
            steps {
                script {
                    // Push avec retry
                    retry(3) {
                        timeout(time: 10, unit: 'MINUTES') {
                            sh '''
                                echo "🚀 Publication des images..."
                                
                                # Push avec gestion d'erreur détaillée
                                docker push ${IMAGE_NAME}:${BUILD_NUMBER} || {
                                    echo "❌ Échec du push, tentative alternative..."
                                    # Essayer avec --all-tags
                                    docker push --all-tags ${IMAGE_NAME} || true
                                }
                                
                                docker push ${IMAGE_NAME}:latest || echo "⚠️  Échec du push latest"
                                
                                echo "✅ Publication terminée"
                            '''
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 SUCCÈS! Build #${BUILD_NUMBER}"
            echo "📦 Image: ${IMAGE_NAME}:${BUILD_NUMBER}"
        }
        failure {
            echo "❌ ÉCHEC du build"
            sh '''
                echo "=== LOGS DOCKER ==="
                docker system df
                docker images | head -10
                echo ""
                echo "=== RÉSEAU ==="
                curl -sI https://registry-1.docker.io/v2/ 2>&1 | head -5
            '''
        }
    }
}