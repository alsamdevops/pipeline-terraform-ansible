provider "aws" {
  region = var.aws_region
}

# Frontend VM (Amazon Linux)
resource "aws_instance" "frontend" {
  ami           = "ami-0a232144cf20a27a5"
  instance_type = "t2.micro"
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              # Create ansible user
              useradd -m -s /bin/bash ansible
              
              # Add ansible to sudo group
              echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

              # Copy authorized_keys from ec2-user
              mkdir -p /home/ansible/.ssh
              cp /home/ec2-user/.ssh/authorized_keys /home/ansible/.ssh/
              chown -R ansible:ansible /home/ansible/.ssh
              chmod 700 /home/ansible/.ssh
              chmod 600 /home/ansible/.ssh/authorized_keys
              EOF

  tags = { Name = "c8.local" }
}

# Backend VM (Ubuntu 21.04)
resource "aws_instance" "backend" {
  ami           = "ami-0bbdd8c17ed981ef9"
  instance_type = "t2.micro"
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              # Create ansible user
              useradd -m -s /bin/bash ansible
              
              # Add ansible to sudo group
              usermod -aG sudo ansible
              echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

              # Copy authorized_keys from ubuntu
              mkdir -p /home/ansible/.ssh
              cp /home/ubuntu/.ssh/authorized_keys /home/ansible/.ssh/
              chown -R ansible:ansible /home/ansible/.ssh
              chmod 700 /home/ansible/.ssh
              chmod 600 /home/ansible/.ssh/authorized_keys
              EOF

  tags = { Name = "u21.local" }
}

# Dynamic Ansible inventory
resource "null_resource" "ansible_inventory" {
  depends_on = [aws_instance.frontend, aws_instance.backend]

  provisioner "local-exec" {
    command = <<EOT
mkdir -p /var/lib/jenkins/testing/ci-pipeline-infra/ansible
cat > /var/lib/jenkins/testing/ci-pipeline-infra/ansible/host.yaml <<EOF
all:
  children:
    frontend:
      hosts:
        c8.local:
          ansible_host: ${aws_instance.frontend.public_ip}
          ansible_user: ansible
          ansible_ssh_private_key_file: ${var.private_key_path}
    backend:
      hosts:
        u21.local:
          ansible_host: ${aws_instance.backend.public_ip}
          ansible_user: ansible
          ansible_ssh_private_key_file: ${var.private_key_path}
EOF
EOT
  }
}

# Optional outputs
output "frontend_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_ip" {
  value = aws_instance.backend.public_ip
}

output "host_yaml_path" {
  value = "/var/lib/jenkins/testing/ci-pipeline-infra/ansible/host.yaml"
}

