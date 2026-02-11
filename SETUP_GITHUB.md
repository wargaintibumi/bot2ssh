# GitHub Repository Setup

## ✅ Git is already configured!

- **Branch**: main
- **Username**: wargaintibumi
- **Email**: adialfian49@gmail.com
- **Initial commit**: Done ✓

## 🚀 Create GitHub Repository (Choose One Method)

### Method 1: Using GitHub Website (Easiest)

1. **Go to GitHub**: https://github.com/new
2. **Repository name**: `bot2ssh` (or any name you prefer)
3. **Description**: "Ngrok SSH Monitor with Telegram notifications"
4. **Visibility**: Choose Public or Private
5. **DO NOT** initialize with README, .gitignore, or license (we already have them)
6. **Click**: "Create repository"

7. **Copy the repository URL** (should look like):
   ```
   https://github.com/wargaintibumi/bot2ssh.git
   ```

8. **Run these commands** (replace with your actual repo URL):
   ```bash
   cd /home/kali/bot2ssh
   git remote add origin https://github.com/wargaintibumi/bot2ssh.git
   git push -u origin main
   ```

9. **Enter your GitHub credentials** when prompted

### Method 2: Using GitHub CLI (If you have it)

```bash
# Install gh CLI first
sudo apt update && sudo apt install gh

# Authenticate
gh auth login

# Create repo and push
gh repo create bot2ssh --public --source=. --remote=origin --push
```

### Method 3: Using Personal Access Token

1. **Create a token**: https://github.com/settings/tokens/new
   - Name: "bot2ssh"
   - Expiration: Your choice
   - Scopes: Select `repo` (full control of private repositories)
   - Click "Generate token"
   - **COPY THE TOKEN** (you won't see it again!)

2. **Push to GitHub**:
   ```bash
   cd /home/kali/bot2ssh
   git remote add origin https://github.com/wargaintibumi/bot2ssh.git

   # Use token as password when prompted
   git push -u origin main
   ```

   When asked for password, paste your token (not your GitHub password)

## 🔐 SSH Key Method (Most Secure)

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "adialfian49@gmail.com"
   cat ~/.ssh/id_ed25519.pub
   ```

2. **Add to GitHub**:
   - Copy the public key
   - Go to: https://github.com/settings/ssh/new
   - Paste and save

3. **Use SSH URL**:
   ```bash
   git remote add origin git@github.com:wargaintibumi/bot2ssh.git
   git push -u origin main
   ```

## ✅ Verify It Worked

After pushing, visit:
```
https://github.com/wargaintibumi/bot2ssh
```

You should see all your files!

## 📝 Future Pushes

After the first push, you can simply:
```bash
git add .
git commit -m "Your commit message"
git push
```

## 🛠️ Troubleshooting

**"remote origin already exists"**
```bash
git remote remove origin
# Then add it again
```

**"Authentication failed"**
- Make sure you're using your GitHub username
- Use a personal access token, not your password
- Or set up SSH keys

**"fatal: refusing to merge unrelated histories"**
```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```
