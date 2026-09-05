FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

COPY HelloWorld.java .
RUN javac HelloWorld.java

EXPOSE 8000

CMD ["java", "HelloWorld"]
