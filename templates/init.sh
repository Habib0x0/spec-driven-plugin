#!/bin/bash
# init.sh - How to build, run, and test this project
#
# This file is read by spec execution scripts (spec-exec.sh, spec-loop.sh,
# spec-team.sh) to understand how to set up and run the project. Uncomment
# and customize the relevant lines for your tech stack.
#
# All actionable lines are commented out by default. Nothing executes until
# you explicitly enable a command.

# ==============================================================================
# DEPENDENCY INSTALLATION
# ==============================================================================
# Install project dependencies before building or running.
#
# Node.js / npm:
# npm install
# npm ci
#
# Python / pip:
# pip install -r requirements.txt
# pip install -e .
#
# Go:
# go mod download
# go mod tidy

# ==============================================================================
# ENVIRONMENT SETUP
# ==============================================================================
# Set environment variables and prepare config files.
#
# Node.js / npm:
# cp .env.example .env
# export NODE_ENV=development
#
# Python / pip:
# cp .env.example .env
# export FLASK_ENV=development
# export DJANGO_SETTINGS_MODULE=myproject.settings.dev
#
# Go:
# cp .env.example .env
# export GO_ENV=development

# ==============================================================================
# START DEVELOPMENT SERVER
# ==============================================================================
# Start the dev server in the background.
#
# Node.js / npm:
# npm run dev &
# npx next dev &
#
# Python / pip:
# python manage.py runserver &
# flask run &
# uvicorn main:app --reload &
#
# Go:
# go run ./cmd/server &
# air &

# ==============================================================================
# HEALTH CHECK
# ==============================================================================
# Verify the app is running and responding to requests.
#
# Node.js / npm:
# sleep 3 && curl -sf http://localhost:3000/health || echo "Server not responding"
#
# Python / pip:
# sleep 3 && curl -sf http://localhost:8000/health || echo "Server not responding"
#
# Go:
# sleep 3 && curl -sf http://localhost:8080/health || echo "Server not responding"

# ==============================================================================
# RUN TESTS
# ==============================================================================
# Run the project's test suite.
#
# Node.js / npm:
# npm test
# npx jest
# npx vitest run
#
# Python / pip:
# pytest
# python -m pytest -v
#
# Go:
# go test ./...
# go test -v -race ./...
