#!/bin/bash

echo "================================================"
echo "  GitHub Repository Setup Helper"
echo "================================================"
echo ""

# Check if remote already exists
if git remote get-url origin >/dev/null 2>&1; then
    CURRENT_REMOTE=$(git remote get-url origin)
    echo "✓ Remote 'origin' already configured:"
    echo "  $CURRENT_REMOTE"
    echo ""
    read -p "Do you want to change it? (y/N): " CHANGE
    if [[ "$CHANGE" =~ ^[Yy]$ ]]; then
        git remote remove origin
    else
        echo ""
        echo "Pushing to existing remote..."
        git push -u origin main
        exit $?
    fi
fi

# Ask for repository URL
echo "First, create a repository on GitHub:"
echo "  https://github.com/new"
echo ""
echo "Repository name: bot2ssh (or your choice)"
echo "DO NOT initialize with README"
echo ""
read -p "Enter your GitHub repository URL: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "Error: No URL provided"
    exit 1
fi

# Add remote
echo ""
echo "Adding remote origin..."
git remote add origin "$REPO_URL"

if [ $? -eq 0 ]; then
    echo "✓ Remote added successfully"
else
    echo "✗ Failed to add remote"
    exit 1
fi

# Show current status
echo ""
echo "Repository info:"
echo "  Branch: $(git branch --show-current)"
echo "  Remote: $REPO_URL"
echo "  Files: $(git ls-files | wc -l) files committed"
echo ""

# Attempt to push
echo "Pushing to GitHub..."
echo "(You may need to enter your GitHub username and password/token)"
echo ""

git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "  ✓ Successfully pushed to GitHub!"
    echo "================================================"
    echo ""
    echo "View your repository at:"
    echo "  ${REPO_URL%.git}"
    echo ""
else
    echo ""
    echo "================================================"
    echo "  ✗ Push failed"
    echo "================================================"
    echo ""
    echo "Common issues:"
    echo "  1. Wrong credentials - use a Personal Access Token instead of password"
    echo "  2. Repository doesn't exist - create it at https://github.com/new"
    echo "  3. No push access - make sure you own the repository"
    echo ""
    echo "See SETUP_GITHUB.md for detailed instructions"
fi
