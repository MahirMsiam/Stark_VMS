# Render (or any Docker host) builds the backend from this file. Root directory: vms-backend
# Build stage: compile with the Maven wrapper (tests run in CI/locally, not on every deploy).
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN sh mvnw -B -ntp dependency:go-offline
COPY src/ src/
RUN sh mvnw -B -ntp -DskipTests package

# Run stage: JRE only, no source code or build tools.
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/vms-backend-0.0.1-SNAPSHOT.jar app.jar
# Small instances (e.g. Render free, 512 MB): size the heap from the container limit.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
# Render sets PORT; application.properties reads it (default 9001).
EXPOSE 9001
USER 1000
ENTRYPOINT ["java", "-jar", "app.jar"]
