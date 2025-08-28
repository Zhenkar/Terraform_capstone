#!/bin/bash
yum update -y && yum install -y python3 python3-pip git nginx

# Setup app
mkdir -p /opt/todo-app && cd /opt/todo-app
useradd -r -s /bin/false todoapp && chown todoapp:todoapp /opt/todo-app

# Create minimal Flask app
cat > app.py << 'EOF'
from flask import Flask, render_template, request, redirect, url_for, flash
import uuid
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your-production-secret-key-change-this'
todos = []

class Todo:
    def __init__(self, title, description=""):
        self.id = str(uuid.uuid4())
        self.title = title
        self.description = description
        self.completed = False
        self.created_at = datetime.now()

@app.route('/')
def index():
    return render_template('index.html', todos=todos)

@app.route('/add', methods=['POST'])
def add_todo():
    title = request.form.get('title', '').strip()
    if not title:
        flash('Title required!', 'error')
        return redirect(url_for('index'))
    todos.append(Todo(title, request.form.get('description', '').strip()))
    flash('Added!', 'success')
    return redirect(url_for('index'))

@app.route('/complete/<todo_id>')
def toggle_complete(todo_id):
    for todo in todos:
        if todo.id == todo_id:
            todo.completed = not todo.completed
            break
    return redirect(url_for('index'))

@app.route('/delete/<todo_id>')
def delete_todo(todo_id):
    global todos
    todos = [t for t in todos if t.id != todo_id]
    return redirect(url_for('index'))

@app.route('/health')
def health():
    return {'status': 'ok'}

if __name__ == '__main__':
    todos.extend([Todo("Welcome!", "Sample todo"), Todo("Learn Terraform")])
    app.run(debug=False, host='0.0.0.0', port=${app_port})
EOF

# Create minimal template
mkdir -p templates
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Todo App</title>
<style>
body{font-family:Arial;max-width:800px;margin:50px auto;padding:20px}
.form{background:#f5f5f5;padding:20px;margin-bottom:20px;border-radius:5px}
.todo{border:1px solid #ddd;margin:10px 0;padding:15px;border-radius:5px}
.completed{opacity:0.6;text-decoration:line-through}
input,textarea,button{width:100%;padding:10px;margin:5px 0;border:1px solid #ccc;border-radius:3px}
button{background:#007cba;color:white;cursor:pointer}
.btn{display:inline-block;padding:5px 10px;margin:2px;text-decoration:none;border-radius:3px;font-size:12px}
.btn-success{background:#28a745;color:white}
.btn-danger{background:#dc3545;color:white}
.alert{padding:10px;margin:10px 0;border-radius:5px}
.alert.success{background:#d4edda;color:#155724}
.alert.error{background:#f8d7da;color:#721c24}
</style>
</head>
<body>
<h1>📝 AWS Todo App</h1>

{% with messages = get_flashed_messages(with_categories=true) %}
{% if messages %}
{% for category, message in messages %}
<div class="alert {{category}}">{{message}}</div>
{% endfor %}
{% endif %}
{% endwith %}

<div class="form">
<form action="{{url_for('add_todo')}}" method="POST">
<input name="title" placeholder="Todo title" required>
<textarea name="description" placeholder="Description (optional)"></textarea>
<button type="submit">Add Todo</button>
</form>
</div>

{% for todo in todos %}
<div class="todo {% if todo.completed %}completed{% endif %}">
<h3>{{todo.title}}</h3>
{% if todo.description %}<p>{{todo.description}}</p>{% endif %}
<small>{{todo.created_at.strftime('%Y-%m-%d %H:%M')}}</small><br>
<a href="{{url_for('toggle_complete',todo_id=todo.id)}}" class="btn btn-success">
{% if todo.completed %}Undo{% else %}Done{% endif %}</a>
<a href="{{url_for('delete_todo',todo_id=todo.id)}}" class="btn btn-danger" onclick="return confirm('Delete?')">Delete</a>
</div>
{% endfor %}
</body>
</html>
EOF

# Setup services
echo "Flask==2.3.3" > requirements.txt
pip3 install -r requirements.txt

cat > /etc/systemd/system/todo-app.service << 'EOF'
[Unit]
Description=Todo App
After=network.target
[Service]
Type=simple
User=todoapp
WorkingDirectory=/opt/todo-app
ExecStart=/usr/bin/python3 app.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/nginx/conf.d/todo-app.conf << 'EOF'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:${app_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

chown -R todoapp:todoapp /opt/todo-app
systemctl daemon-reload
systemctl enable --now todo-app nginx