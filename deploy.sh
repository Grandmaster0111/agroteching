#!/bin/bash
set -e
echo "--- Setting up Python virtual environment in 'functions' directory ---"
cd functions
python3 -m venv venv
source venv/bin/activate

echo "--- Installing dependencies from requirements.txt ---"
pip install -r requirements.txt

echo "--- Checking Python executable and version ---"
which python
python --version

echo "--- Returning to root and deploying functions with debug output ---"
cd ..
firebase deploy --only functions --debug

echo "--- Deployment script finished ---"
