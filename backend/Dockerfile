# Use a lightweight Python version
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your app code
COPY . .

# Ensure Python output is sent straight to terminal (logs)
ENV PYTHONUNBUFFERED=1

# Start the app listening on the requested PORT
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT}