# Use an official Python image as the base
FROM python:3.10

# Set the working directory inside the container
WORKDIR /app

# Copy the Python script and requirements file into the container
COPY plant_plots.py .
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Define the entrypoint to allow passing arguments at runtime
ENTRYPOINT ["python", "plant_plots.py"]
