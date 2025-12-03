FROM openjdk:17-jre-slim
COPY target/*.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]