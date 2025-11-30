import json
import os

def create_project_structure(project):
    path = project['path']
    os.makedirs(os.path.join(path, "src"), exist_ok=True)
    os.makedirs(os.path.join(path, "assets"), exist_ok=True)
    
    # Create README.md
    readme_content = f"""# {project['title']}

## 📌 Project Overview
{project['description']}

**Category:** {', '.join(project['category'])}  
**Difficulty:** {project['difficulty'].title()}  
**Tags:** {', '.join(f'`{t}`' for t in project['tags'])}

---

## 🎯 Business Use Case
In a real-world scenario, this project helps organizations to:
- Automate repetitive tasks related to {project['title']}.
- Ensure consistency across environments.
- Reduce manual errors and operational overhead.

---

## 🛠️ Prerequisites
- {project['tool'].title()} installed
- Basic understanding of {project['category'][0]}
- A target environment (VM, Container, or Cloud Instance)

---

## 🚀 Implementation Steps

### 1. Setup
Clone the repository and navigate to the project directory:
```bash
cd {path}
```

### 2. Dependencies
Install required dependencies:
```bash
# Check requirements.txt
cat requirements.txt
```

### 3. Execution
Run the solution:
```bash
# Command to run the project
# (Refer to src/ directory for code)
```

---

## 📂 Project Structure
```
{os.path.basename(path)}/
├── README.md
├── requirements.txt
├── src/
│   └── (Source code goes here)
└── assets/
```

---

## 🧩 Extensions & Challenges
1. Add error handling.
2. Scale this to multiple targets.
3. Integrate with a CI/CD pipeline.

"""
    with open(os.path.join(path, "README.md"), "w") as f:
        f.write(readme_content)

    # Create requirements.txt
    with open(os.path.join(path, "requirements.txt"), "w") as f:
        f.write("# Add dependencies here\n")

def main():
    with open('metadata/project_index.json', 'r') as f:
        data = json.load(f)
    
    for project in data['projects']:
        print(f"Processing {project['id']}...")
        create_project_structure(project)

if __name__ == "__main__":
    main()
