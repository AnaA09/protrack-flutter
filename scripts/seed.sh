#!/bin/bash

# Set environment variables
export INSTRUMENTS_TABLE=instruments
export PROJECTS_TABLE=projects
export TASKS_TABLE=tasks
export ACTIVITIES_TABLE=activities

# Install requirements
pip install -r requirements.txt

# Run the seeding script
python seed_data.py 