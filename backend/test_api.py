#!/usr/bin/env python3
"""
Simple test script for CoachVision API
Run this after starting the server to test the endpoints
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    response = requests.get(f"{BASE_URL}/health")
    print(f"Health check: {response.status_code}")
    print(response.json())

def test_create_user():
    """Test user creation"""
    user_data = {
        "name": "John Doe",
        "age": 25,
        "weight": 70.0,
        "height": 175.0,
        "fitness_goal": "muscle_gain",
        "experience_level": "beginner"
    }
    
    response = requests.post(f"{BASE_URL}/user/", json=user_data)
    print(f"Create user: {response.status_code}")
    if response.status_code == 200:
        user = response.json()
        print(f"Created user with ID: {user['id']}")
        return user['id']
    else:
        print(response.text)
        return None

def test_get_user(user_id):
    """Test getting user by ID"""
    response = requests.get(f"{BASE_URL}/user/{user_id}")
    print(f"Get user {user_id}: {response.status_code}")
    if response.status_code == 200:
        print(response.json())
    else:
        print(response.text)

def test_generate_plan(user_id):
    """Test training plan generation"""
    plan_data = {
        "user_id": user_id,
        "plan_type": "weekly"
    }
    
    response = requests.post(f"{BASE_URL}/planner/generate", json=plan_data)
    print(f"Generate plan: {response.status_code}")
    if response.status_code == 200:
        plan = response.json()
        print(f"Generated plan with ID: {plan['id']}")
        return plan['id']
    else:
        print(response.text)
        return None

def test_get_user_plans(user_id):
    """Test getting user's training plans"""
    response = requests.get(f"{BASE_URL}/planner/user/{user_id}")
    print(f"Get user plans: {response.status_code}")
    if response.status_code == 200:
        plans = response.json()
        print(f"Found {len(plans)} plans")
    else:
        print(response.text)

if __name__ == "__main__":
    print("Testing CoachVision API...")
    print("=" * 50)
    
    # Test health endpoint
    test_health()
    print()
    
    # Test user creation
    user_id = test_create_user()
    print()
    
    if user_id:
        # Test getting user
        test_get_user(user_id)
        print()
        
        # Test plan generation (requires OpenAI API key)
        print("Note: Plan generation requires OpenAI API key")
        plan_id = test_generate_plan(user_id)
        print()
        
        if plan_id:
            # Test getting user plans
            test_get_user_plans(user_id)
    
    print("=" * 50)
    print("Test completed!") 