# System Resource Monitor

## 📌 Project Overview
This project is a Python-based command-line tool that monitors system resources (CPU, Memory, Disk) in real-time. It demonstrates how to use the `psutil` library for DevOps monitoring tasks.

**Category:** Automation  
**Difficulty:** Beginner  
**Tags:** `python`, `devops`, `automation`, `monitoring`

---

## 🎯 Business Use Case
In a real-world scenario, this project helps organizations to:
- Quickly diagnose performance bottlenecks on servers.
- Automate health checks before deploying applications.
- Collect metrics for long-term trend analysis.

---

## 🛠️ Prerequisites
- Python 3.8+
- `psutil` library

---

## 🚀 Implementation Steps

### 1. Setup
Clone the repository and navigate to the project directory:
```bash
cd python-devops/project_001
```

### 2. Dependencies
Install required dependencies:
```bash
pip install -r requirements.txt
```

### 3. Execution
Run the monitor:
```bash
python3 src/system_monitor.py
```

Options:
- `--interval`: Set update interval in seconds (default: 1)
- `--duration`: Set total duration to run (default: infinite)

---

## 📂 Project Structure
```
project_001/
├── README.md
├── requirements.txt
├── src/
│   └── system_monitor.py     # Main script
└── assets/
```

---

## 🧩 Extensions & Challenges
1. Log the data to a CSV file.
2. Send an alert (Email/Slack) if CPU usage exceeds 90%.
3. Create a simple web dashboard using Flask.
