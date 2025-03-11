FROM openjdk:17

WORKDIR /app

COPY WatermarkAdder.java ./

RUN javac WatermarkAdder.java

ENTRYPOINT ["java", "WatermarkAdder"]
