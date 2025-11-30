# Nginx Web Server Setup

## 📌 Project Overview
This project demonstrates how to automate the deployment and configuration of an Nginx web server using Ansible. It covers package installation, service management, and custom configuration deployment.

**Category:** Web  
**Difficulty:** Beginner  
**Tags:** `ansible`, `web`, `beginner`, `nginx`

---

## 🎯 Business Use Case
In a real-world scenario, this project helps organizations to:
- Rapidly provision web servers for new applications.
- Ensure standard security configurations (SSL, headers) across all servers.
- Reduce downtime during configuration updates by automating reloads.

---

## 🛠️ Prerequisites
- Ansible installed (`pip install ansible`)
- A target server (VM, container, or localhost)
- SSH access to the target

---

## 🚀 Implementation Steps

### 1. Setup
Clone the repository and navigate to the project directory:
```bash
cd ansible/project_001
```

### 2. Dependencies
Install required dependencies:
```bash
pip install -r requirements.txt
```

### 3. Execution
Run the playbook:
```bash
# Run on localhost (requires sudo)
ansible-playbook -i src/inventory src/playbook.yml --connection=local --ask-become-pass

# Run on remote server
# Update src/inventory with your server IP first
ansible-playbook -i src/inventory src/playbook.yml
```

### 4. Verification
Check if Nginx is running:
```bash
curl http://localhost
```

---

## 📂 Project Structure
```
project_001/
├── README.md
├── requirements.txt
├── src/
│   ├── inventory        # Host inventory
│   ├── playbook.yml     # Main playbook
│   └── nginx.conf.j2    # (Optional) Configuration template
└── assets/
```

---

## 🧩 Extensions & Challenges
1. Add a custom `index.html` template.
2. Configure SSL using Let's Encrypt.
3. Add a firewall rule to allow port 80/443.
