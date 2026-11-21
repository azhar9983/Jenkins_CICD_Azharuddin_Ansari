# Jenkins CI/CD Pipeline: Flask + Express on AWS EC2

A Flask backend (port 5000) and an Express frontend (port 3000) deployed on a single
EC2 instance, with Jenkins automating build, test and deployment on every GitHub push.

## GitHub Repositories
- Flask backend: https://github.com/azhar9983/flask-backend.git
- Express frontend: https://github.com/azhar9983/express-frontend.git

## Architecture

```
 Developer --git push--> GitHub --webhook--> Jenkins (:8080)
                                                |
                          +---------------------+----------------------+
                          v                                            v
                 Flask pipeline                               Express pipeline
        (pull, pip install, pytest,                  (pull, npm install, npm test,
         rsync to /opt/apps, pm2 restart)             rsync to /opt/apps, pm2 restart)
                          |                                            |
   +----------------- EC2 instance (Ubuntu) ----------------------------+
   |   Express frontend :3000  --/api/message-->  Flask backend :5000   |
   |        (pm2: express-frontend)                (pm2: flask-backend, gunicorn) |
   +--------------------------------------------------------------------+
```

## Project Structure
```
Jenkins_CICD_Azharuddin_Ansari/
├── flask-backend/       # Flask app, tests, Jenkinsfile, pm2 config
├── express-frontend/    # Express app, tests, Jenkinsfile, pm2 config
├── scripts/             # setup-ec2.sh, manual-deploy.sh
├── screenshots/         # EC2, apps, Jenkins builds, webhook
└── README.md
```
Each app folder is its own GitHub repository (its `Jenkinsfile` sits at the repo root).

## Part 1: Manual Deployment on EC2
1. Launch an Ubuntu t2.micro (free tier). Security group inbound rules: 22 (SSH), 3000, 5000, 8080.
2. SSH in: `ssh -i key.pem ubuntu@<EC2-PUBLIC-IP>`
3. Run `scripts/setup-ec2.sh` (installs Python, Node.js, Git, pm2, Java, Jenkins, swap).
4. Run `scripts/manual-deploy.sh` (clones both repos, installs dependencies, starts with pm2).
5. Verify: `http://<EC2-IP>:5000/health` and `http://<EC2-IP>:3000`.
6. Before Part 2, free the ports: `pm2 delete all` (Jenkins will run its own pm2 as user `jenkins`).

## Part 2: Jenkins CI/CD
1. Open `http://<EC2-IP>:8080`, unlock with `/var/lib/jenkins/secrets/initialAdminPassword`,
   install suggested plugins, create the admin user.
2. Plugins: Git, GitHub, Pipeline, NodeJS (Manage Jenkins > Plugins).
3. Create two Pipeline jobs, `flask-pipeline` and `express-pipeline`:
   - Pipeline script from SCM, Git, repo URL, branch `*/main`, script path `Jenkinsfile`.
   - Build Triggers: tick "GitHub hook trigger for GITScm polling".
4. GitHub webhook (each repo): Settings > Webhooks > Payload URL
   `http://<EC2-IP>:8080/github-webhook/`, content type `application/json`, event "push".
5. Push a change; both pipelines run automatically.

### Pipeline stages
| Stage | Flask | Express |
|-------|-------|---------|
| Pull Latest Code | `checkout scm` | `checkout scm` |
| Install Dependencies | venv + `pip install -r requirements.txt` | `npm install` |
| Test | `pytest` | `npm test` |
| Deploy | rsync to `/opt/apps/flask-backend`, `pm2 startOrRestart` | rsync to `/opt/apps/express-frontend`, `pm2 startOrRestart` |
| Verify | `curl :5000/health` | `curl :3000/health` |

### Secrets / environment variables
Add secrets under Manage Jenkins > Credentials (Secret text) and reference them in the
Jenkinsfile with `credentials('id')` (see the commented lines).

## Screenshots
See the `screenshots/` folder: EC2 instance, running apps, pm2 status, Jenkins jobs,
successful build logs, GitHub webhook delivery.


database or shared volume/folder can be attached to retain data
run scripts cmd to configure ec2 instance 


and ec2 t3-micro doesn't run well on jenkins +2 apps load so either choose bigger instance or use swap
for swap cmd is given below run it on ec2 
```bash
echo "==> Adding 1GB swap (helps t2/t3.micro run Jenkins + 2 apps)"
if ! swapon --show | grep -q swapfile; then
  sudo fallocate -l 1G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi
```
