import json

def generate_ansible_projects():
    titles = [
        "Nginx Web Server Setup", "Apache Web Server Setup", "MySQL Database Deployment", "PostgreSQL Database Setup", "MongoDB Cluster Setup",
        "Redis Cache Setup", "Memcached Installation", "Jenkins CI Server", "GitLab Runner Setup", "Docker Engine Installation",
        "Kubernetes Cluster Bootstrap", "Prometheus Monitoring Stack", "Grafana Dashboard Setup", "ELK Stack Deployment", "Node.js Environment Setup",
        "Python Development Env", "Java OpenJDK Setup", "GoLang Environment", "Rust Development Env", "PHP-FPM Configuration",
        "HAProxy Load Balancer", "Keepalived High Availability", "NFS Server Configuration", "Samba File Server", "VSFTPD FTP Server",
        "Bind9 DNS Server", "ISC-DHCP Server", "Chrony NTP Server", "SSH Hardening Config", "UFW Firewall Setup",
        "Fail2Ban Intrusion Prevention", "SELinux Policy Management", "AppArmor Profile Config", "User Account Management", "Group Management",
        "Sudoers Configuration", "Cron Job Automation", "Log Rotation Policy", "System Package Updates", "Kernel Parameter Tuning",
        "Hostname Configuration", "Timezone Setting", "Locale Configuration", "Network Interface Config", "Static Route Setup",
        "OpenVPN Server Setup", "WireGuard VPN Setup", "Squid Proxy Server", "Varnish Cache Setup", "Tomcat App Server",
        "Wildfly App Server", "RabbitMQ Cluster", "Kafka Event Streaming", "Zookeeper Cluster", "Consul Service Discovery",
        "Vault Secret Management", "Terraform Installation", "Packer Tool Setup", "Minikube Local Cluster", "Kind Cluster Setup",
        "MicroK8s Installation", "K3s Lightweight K8s", "Helm Package Manager", "ArgoCD GitOps Setup", "Istio Service Mesh",
        "Linkerd Service Mesh", "Traefik Ingress Controller", "Cert-Manager Setup", "Lets Encrypt SSL Certs", "Self-Signed SSL Certs",
        "OpenLDAP Directory Server", "FreeIPA Client Setup", "SSSD Authentication", "Kerberos Client Config", "Postfix Mail Server",
        "Dovecot IMAP Server", "SpamAssassin Setup", "ClamAV Antivirus", "Rkhunter Rootkit Check", "Lynis Security Audit",
        "OpenSCAP Compliance Scan", "Auditd System Auditing", "Syslog-NG Log Server", "Rsyslog Configuration", "Logwatch Report Setup",
        "Monit Service Monitoring", "Nagios Core Monitoring", "Zabbix Agent Install", "Datadog Agent Install", "New Relic Agent Install",
        "Splunk Forwarder Setup", "Filebeat Log Shipper", "Metricbeat Metric Shipper", "Heartbeat Uptime Monitor", "Packetbeat Network Monitor",
        "Auditbeat Audit Shipper", "Journalbeat Shipper", "Functionbeat Serverless", "Ansible Tower Installation", "Rundeck Job Scheduler"
    ]
    
    projects = []
    categories = ["Web", "Database", "DevOps", "Security", "Network", "Monitoring", "System", "Cloud"]
    difficulties = ["beginner", "intermediate", "advanced"]

    for i, title in enumerate(titles):
        project_id = f"ansible_{i+1:03d}"
        path = f"ansible/project_{i+1:03d}"
        category = categories[i % len(categories)]
        difficulty = difficulties[i % len(difficulties)]
        
        projects.append({
            "id": project_id,
            "tool": "ansible",
            "path": path,
            "title": title,
            "description": f"A real-world Ansible project to implement {title}. Focuses on {category} best practices.",
            "category": [category],
            "difficulty": difficulty,
            "tags": ["ansible", category.lower(), difficulty],
            "dependencies": ["ansible>=2.9"],
            "related_projects": [],
            "version": "1.0"
        })
    return projects

def generate_python_projects():
    titles = [
        "System Resource Monitor", "Disk Usage Analyzer", "Log File Parser", "Backup Rotation Script", "File Deduplicator",
        "Directory Cleaner", "Old File Archiver", "Process Monitor", "Memory Leak Detector", "CPU Stress Tester",
        "Network Port Scanner", "IP Address Tracker", "Subnet Calculator", "DNS Propagation Checker", "SSL Cert Expiry Checker",
        "Website Uptime Monitor", "HTTP Header Inspector", "API Response Tester", "JSON Schema Validator", "XML Syntax Validator",
        "YAML Syntax Validator", "CSV to JSON Converter", "JSON to CSV Converter", "Excel to CSV Converter", "PDF Text Extractor",
        "PDF Merger Tool", "Image Resizer Tool", "Image Format Converter", "Watermark Adder", "QR Code Generator",
        "Barcode Generator", "Password Generator", "SSH Key Rotator", "File Encryption Tool", "File Hash Calculator",
        "S3 Bucket Lister", "S3 File Uploader", "EC2 Instance Manager", "RDS Snapshot Manager", "Lambda Function Deployer",
        "CloudWatch Log Tailer", "IAM User Auditor", "Security Group Auditor", "Route53 Record Manager", "Kubernetes Pod Lister",
        "Kubernetes Log Streamer", "Docker Container Manager", "Docker Image Cleaner", "Git Repo Cloner", "Git Branch Cleaner",
        "Commit Message Linter", "Code Complexity Checker", "Todo List CLI", "Note Taking CLI", "Journal Entry CLI",
        "Timer and Stopwatch", "Unit Converter CLI", "Currency Converter", "Stock Price Checker", "Crypto Price Tracker",
        "Weather Forecast App", "News Headlines Fetcher", "Email Sender SMTP", "SMS Sender Twilio", "Slack Notification Bot",
        "Discord Webhook Bot", "Telegram Chat Bot", "Web Scraper BeautifulSoup", "Selenium Automator", "Headless Browser Script",
        "Screen Capture Tool", "YouTube Video Downloader", "File Organizer Script", "Bulk File Renamer", "Regex Testing Tool",
        "Markdown to HTML", "HTML to Markdown", "Static Site Generator", "Broken Link Checker", "Broken Image Checker",
        "Sitemap Generator", "Robots.txt Generator", "Whois Domain Lookup", "GeoIP Location Lookup", "Mac Address Vendor",
        "User Agent Parser", "Crontab Generator", "System Info Dumper", "Env Variable Dumper", "Path Variable Fixer",
        "Duplicate Line Remover", "Text Case Converter", "Word Count Tool", "Character Count Tool", "Line Count Tool",
        "File Permission Fixer", "Empty Directory Remover", "Temp File Cleaner", "Browser Cache Cleaner", "Shell History Cleaner"
    ]

    projects = []
    categories = ["Automation", "Data", "Network", "Security", "Cloud", "DevOps", "Web", "Utility"]
    difficulties = ["beginner", "intermediate", "advanced"]

    for i, title in enumerate(titles):
        project_id = f"python_{i+1:03d}"
        path = f"python-devops/project_{i+1:03d}"
        category = categories[i % len(categories)]
        difficulty = difficulties[i % len(difficulties)]
        
        projects.append({
            "id": project_id,
            "tool": "python",
            "path": path,
            "title": title,
            "description": f"A Python DevOps script to implement {title}. Useful for {category}.",
            "category": [category],
            "difficulty": difficulty,
            "tags": ["python", "devops", category.lower(), difficulty],
            "dependencies": ["python>=3.8"],
            "related_projects": [],
            "version": "1.0"
        })
    return projects

def main():
    data = {
        "tools": ["ansible", "python"],
        "projects": generate_ansible_projects() + generate_python_projects()
    }
    
    with open('metadata/project_index.json', 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"Generated {len(data['projects'])} projects in metadata/project_index.json")

if __name__ == "__main__":
    main()
