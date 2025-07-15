from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
import json
import os
from openai import OpenAI
from database import get_session
from models import (
    UserProfile, TrainingPlan, TrainingPlanRequest, TrainingPlanResponse
)
from routers.auth import verify_token

router = APIRouter()

def get_openai_client():
    """Get OpenAI client with API key"""
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=500, 
            detail="OpenAI API key not configured. Please set OPENAI_API_KEY environment variable."
        )
    return OpenAI(api_key=api_key)

@router.post("/generate", response_model=TrainingPlanResponse)
async def generate_training_plan(
    request: TrainingPlanRequest,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Generate a personalized training plan using OpenAI"""
    
    # Verify user can only generate plans for themselves
    if current_user.id != request.user_id:
        raise HTTPException(status_code=403, detail="Not authorized to generate plans for other users")
    
    # Get user profile
    user = session.get(UserProfile, request.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Create prompt for OpenAI
    prompt = f"""
    Create a personalized {request.plan_type} training and diet plan for the following user:
    
    Name: {user.name}
    Age: {user.age}
    Weight: {user.weight} kg
    Height: {user.height} cm
    Fitness Goal: {user.fitness_goal}
    Experience Level: {user.experience_level}
    
    Please provide a comprehensive plan including:
    1. Weekly workout schedule with specific exercises
    2. Daily meal plan with calorie targets
    3. Rest days and recovery recommendations
    4. Progress tracking tips
    
    Format the response as a structured JSON with sections for workouts, nutrition, and recommendations.
    """
    
    try:
        # Get OpenAI client
        client = get_openai_client()
        
        # Call OpenAI API
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a professional fitness coach and nutritionist. Provide detailed, actionable advice."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=2000,
            temperature=0.7
        )
        
        plan_content = response.choices[0].message.content
        
        # Create training plan record
        training_plan = TrainingPlan(
            user_id=user.id,
            plan_type=request.plan_type,
            content=plan_content
        )
        
        session.add(training_plan)
        session.commit()
        session.refresh(training_plan)
        
        return training_plan
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating plan: {str(e)}")

@router.get("/user/{user_id}", response_model=List[TrainingPlanResponse])
async def get_user_training_plans(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Get all training plans for a user (authenticated users can only access their own plans)"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to access other users' plans")
    
    plans = session.execute(
        select(TrainingPlan).where(TrainingPlan.user_id == user_id)
    ).scalars().all()
    return plans

@router.get("/{plan_id}", response_model=TrainingPlanResponse)
async def get_training_plan(
    plan_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Get a specific training plan (authenticated users can only access their own plans)"""
    plan = session.get(TrainingPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    if plan.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this plan")
    
    return plan

@router.delete("/{plan_id}")
async def delete_training_plan(
    plan_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Delete a training plan (authenticated users can only delete their own plans)"""
    plan = session.get(TrainingPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    if plan.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this plan")
    
    session.delete(plan)
    session.commit()
    return {"message": "Training plan deleted successfully"} 