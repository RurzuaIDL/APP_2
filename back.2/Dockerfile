FROM maven:3.8.4-openjdk-17 AS build
WORKDIR app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests
FROM openjdk:17-jdk-alpine
COPY --from=build /app/target/backend-0.0.1-SNAPSHOT.jar /app.jar
ENV TZ=America/Chile/Santiago
COPY --from=postgres:latest /usr/bin/psql /usr/bin/psql
RUN apk add --no-cache postgresql-client
ENTRYPOINT ["java", "-jar", "/app.jar"]