# workout-terraform

This document guides you through setting up a lab infrastructure for a workout application using Terraform, Docker, and Apache.

## Setting Up Infrastructure with Terraform

1. **Create Terraform Configuration:**

   - This terrafrom configuration includes these resources:
     - 3 Servers (Artifactory, Backend, Frontend)
     - DynamoDB
     - Internet Gateway
     - Public Subnet with a Route Table and route to Internet Gateway
     - Security Groups for HTTP and SSH access
     - IAM Role for DynamoDB to interact with EC2
       
   - Execute the following Terraform commands:

     ```bash
     terraform init
     terraform plan
     terraform apply
     terraform destroy (for cleanup)
     ```

2. **SSH into Artifactory and Install Apache2:**

   - Connect to the Artifactory server using SSH (e.g., Putty).
   - Install Apache2 server:

     ```bash
     sudo apt-get install apache2
     ```

   - Verify the installation status:

     ```bash
     service apache2 status
     ```

   - Access the default Apache page by opening the server's public IP in your browser.
   - To deploy your application JAR file:
     - Transfer the JAR to the `/var/www/html` directory on Artifactory using a tool like WinSCP.
     - Access the JAR in your browser using the format `http://<public_ip>/<jar_name>.jar`.

   **Permissions:**

     - **Granting Everyone Access (Not Recommended):**

       ```bash
       sudo chmod -R 777 /var/www/html  # This is a security risk, avoid using it!
       ```

     - **Recommended Approach:**

       - Change ownership of the directory to the Apache user (`ubuntu` in your example):

         ```bash
         sudo chown -R ubuntu:ubuntu /var/www/html
         ```

## Setting Up the Backend Server

3. **Update and Install Docker:**

   - Connect to the backend server using SSH.
   - Update the server's package list:

     ```bash
     sudo apt-get update
     ```

   - Install Docker:

     ```bash
     sudo apt-get install docker.io
     ```

4. **Create a Dockerfile:**

   - Use `nano` to create a Dockerfile named `dockerfile` (or any name you prefer):

     ```bash
     sudo nano dockerfile
     ```

   - Paste the following content into the file, replacing `<ip_address_artifactory>` with the actual IP of your Artifactory server:

     ```dockerfile
     FROM openjdk:17
     RUN curl -o workoutapp.jar <ip_address_artifactory>/workoutapp.jar
     CMD ["java", "-jar", "workoutapp.jar"]
     ```

   - Save the file (Ctrl+O) and exit Nano (Ctrl+X).

5. **Build and Run the Docker Image:**

   - Build the Docker image from the Dockerfile:

     ```bash
     sudo docker build -t workout-app .
     ```

   - List available Docker images:

     ```bash
     sudo docker images
     ```

   - Run the image in interactive mode and map port 8080 of the container to port 8080 of the host:

     ```bash
     sudo docker run -it -p 8080:8080 workout-app
     ```

     - Access the application at `http://localhost:8080/workouts` (if running locally) or replace `localhost` with the server's public IP for remote access.

   - To run the container in the background:

     ```bash
     sudo docker run -d -p 80:8080 workout-app
     ```

     - Use `http://<public_ip>/<endpoints>` to access the application endpoints.

   - View running Docker containers:

     ```bash
     sudo docker ps
     ```

## Setting Up the Frontend Server

6. **Install Apache and Node.js:**

   - Update the package list:

     ```bash
     sudo apt update
     ```

   - Install Apache and Node.js:

     ```bash
     sudo apt install apache2 nodejs npm
     ```

7. **Transfer and Deploy Frontend Build:**
   - transfer build folder that is created when you run npm run build to the /var/www/html folder
   - gave ownership of the directly like i did on artifactory.
		- also gave access to these files
      - sudo chown -R www-data:www-data /var/www/html/Build
      - sudo chmod -R 755 /var/www/html/Build
	  - Create a virtual host configuration file (e.g., 000-default.conf) to tell Apache2 where to find your React app's files:
     - <VirtualHost *:80> ServerAdmin your_email@example.com DocumentRoot /var/www/html/your_app_name (or /var/www/myapp) <Directory /var/www/html/your_app_name (or /var/www/myapp)> Options Indexes FollowSymLinks AllowOverride All Require all granted </Directory> ErrorLog ${APACHE_LOG_DIR}/error.log CustomLog ${APACHE_LOG_DIR}/custom.log combined </VirtualHost>
		- Enable the Virtual Host Configuration:
		- a.sudo a2ensite 000-default.conf
			-  restart apache
				- sudo systemctl restart apache2
			-  open app in browser using the public ip address
		-  **error logs** sudo tail /var/log/apache2/error.log

