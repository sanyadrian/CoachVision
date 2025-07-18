from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
import json
import os
import openai
from datetime import datetime, timedelta
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
    openai.api_key = api_key
    return openai

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
    
    # Get current date and determine plan structure
    current_date = datetime.now()
    
    if request.plan_type.lower() == "monthly":
        # For monthly plans, get the first day of current month
        first_day_of_month = current_date.replace(day=1)
        last_day_of_month = (first_day_of_month.replace(month=first_day_of_month.month + 1) - timedelta(days=1)) if first_day_of_month.month < 12 else first_day_of_month.replace(year=first_day_of_month.year + 1, month=1) - timedelta(days=1)
        
        # Create weeks for the month
        weeks = []
        current_week = []
        current_date_iter = first_day_of_month
        
        while current_date_iter <= last_day_of_month:
            current_week.append(current_date_iter)
            if current_date_iter.weekday() == 6:  # Sunday
                weeks.append(current_week)
                current_week = []
            current_date_iter += timedelta(days=1)
        
        if current_week:  # Add remaining days
            weeks.append(current_week)
        
        # Create week structure for prompt
        week_structure = ""
        for i, week in enumerate(weeks, 1):
            week_structure += f"\nWeek {i}: "
            week_dates = []
            for date in week:
                day_name = date.strftime('%A').lower()
                day_date = date.strftime('%B %d')  # e.g., "June 01"
                week_dates.append(f"{day_name} ({day_date})")
            week_structure += ", ".join(week_dates)
        
        plan_duration = f"the entire month of {current_date.strftime('%B %Y')} ({len([day for week in weeks for day in week])} days)"
        plan_structure = f"organized by weeks: {week_structure}"
    else:
        # For weekly plans, use current day
        today_name = current_date.strftime('%A').lower()
        plan_duration = f"7 days starting from {today_name} (today)"
        plan_structure = f"starting from {today_name} and continuing in order for 7 days"
    
    # Create prompt for OpenAI
    prompt = f"""
    Create a personalized {request.plan_type} training and diet plan for the following user:
    
    Name: {user.name}
    Age: {user.age}
    Weight: {user.weight} kg
    Height: {user.height} cm
    Fitness Goal: {user.fitness_goal}
    Experience Level: {user.experience_level}
    
    The plan should cover {plan_duration}. {plan_structure}.
    
    IMPORTANT: You MUST return the response in this EXACT JSON format structure:
    
    For WEEKLY plans:
    {{
      "workouts": {{
        "monday": {{
          "workout_type": "Upper Body Strength Training",
          "exercises": [
            "Bench Press: 4 sets x 8 reps",
            "Pull-Ups: 3 sets x 10 reps",
            "Shoulder Press: 3 sets x 12 reps"
          ]
        }},
        "tuesday": {{
          "workout_type": "Lower Body Strength Training",
          "exercises": [
            "Squats: 4 sets x 8 reps",
            "Deadlifts: 3 sets x 6 reps",
            "Lunges: 3 sets x 12 reps"
          ]
        }}
        // ... continue for all 7 days
      }},
      "nutrition": {{
        "calorie_target": "3000 calories per day",
        "foods_to_eat": ["Lean protein sources: chicken, turkey, fish, tofu", "Complex carbohydrates: brown rice, quinoa, sweet potatoes", "Healthy fats: avocado, nuts, olive oil", "Fruits and vegetables for vitamins and minerals", "Stay hydrated with plenty of water"],
        "foods_to_avoid": ["Processed foods high in sugar and unhealthy fats", "Sugary drinks and sodas", "Excessive alcohol consumption", "Fast food and fried foods"]
      }},
      "recommendations": {{
        "rest_days": ["Include at least 1 rest day per week for proper recovery and muscle growth"],
        "recovery_tips": ["Get 7-9 hours of quality sleep each night", "Incorporate foam rolling and stretching into your routine", "Stay hydrated throughout the day", "Listen to your body and adjust intensity as needed"],
        "progress_tracking": ["Track your workouts", "Take progress photos to visually see changes over time", "Keep a workout journal to monitor strength gains", "Consider working with a coach for optimal progress"]
      }}
    }}
    
    For MONTHLY plans:
    {{
      "weeks": {{
        "week_1": {{
          "monday_june_01": {{
            "workout_type": "Upper Body Strength Training",
            "exercises": [
              "Bench Press: 4 sets x 8 reps",
              "Pull-Ups: 3 sets x 10 reps",
              "Shoulder Press: 3 sets x 12 reps"
            ]
          }},
          "tuesday_june_02": {{
            "workout_type": "Lower Body Strength Training",
            "exercises": [
              "Squats: 4 sets x 8 reps",
              "Deadlifts: 3 sets x 6 reps",
              "Lunges: 3 sets x 12 reps"
            ]
          }}
          // ... continue for all days in week 1
        }},
        "week_2": {{
          // Similar structure for week 2
        }}
        // ... continue for all weeks in the month
      }},
      "nutrition": {{
        "calorie_target": "3000 calories per day",
        "foods_to_eat": ["Lean protein sources: chicken, turkey, fish, tofu", "Complex carbohydrates: brown rice, quinoa, sweet potatoes", "Healthy fats: avocado, nuts, olive oil", "Fruits and vegetables for vitamins and minerals", "Stay hydrated with plenty of water"],
        "foods_to_avoid": ["Processed foods high in sugar and unhealthy fats", "Sugary drinks and sodas", "Excessive alcohol consumption", "Fast food and fried foods"]
      }},
      "recommendations": {{
        "rest_days": ["Include at least 1 rest day per week for proper recovery and muscle growth"],
        "recovery_tips": ["Get 7-9 hours of quality sleep each night", "Incorporate foam rolling and stretching into your routine", "Stay hydrated throughout the day", "Listen to your body and adjust intensity as needed"],
        "progress_tracking": ["Track your workouts", "Take progress photos to visually see changes over time", "Keep a workout journal to monitor strength gains", "Consider working with a coach for optimal progress"]
      }}
    }}
    nutrition: {{
        "calorie_target": "3000alories per day",
        "foods_to_eat": ["Lean protein sources: chicken, turkey, fish, tofu", "Complex carbohydrates: brown rice, quinoa, sweet potatoes", "Healthy fats: avocado, nuts, olive oil", "Fruits and vegetables for vitamins and minerals", "Stay hydrated with plenty of water"],
        "foods_to_avoid": ["Processed foods high in sugar and unhealthy fats", "Sugary drinks and sodas", "Excessive alcohol consumption", "Fast food and fried foods"]
    }},
      recommendations: {{
    "rest_days": ["Include at least1rest days per week for proper recovery and muscle growth"],
      "recovery_tips": ["Get 7-9s of quality sleep each night", "Incorporate foam rolling and stretching into your routine", "Stay hydrated throughout the day", "Listen to your body and adjust intensity as needed"],
        "progress_tracking": ["Track your workouts", "Take progress photos to visually see changes over time", "Keep a workout journal to monitor strength gains", "Consider working with a coach for optimal progress"]
      }}
    }}
    
    REQUIREMENTS:
    1. For WEEKLY plans: Use "workouts" key with day names (monday, tuesday, etc.)
    2. For MONTHLY plans: Use "weeks" key with week_1, week_2, etc., and day names with dates (monday_june_01, tuesday_june_02, etc.)
    3. Each day MUST have "workout_type" and "exercises" keys
    4. "exercises" MUST be an array of strings with exercise name and sets/reps
    5. "nutrition" MUST have "calorie_target", "foods_to_eat", and "foods_to_avoid" keys
    6. "recommendations" MUST have "rest_days", "recovery_tips", and "progress_tracking" keys
    7. Follow the EXACT structure above - do not change key names or data types
    8. For weekly plans: Start from {today_name if request.plan_type.lower() != "monthly" else "the first day of the month"} and continue for 7 days in order
    9. For monthly plans: Cover the entire month organized by weeks
    
    Return ONLY the JSON object, no additional text or explanations.
    """
    
    try:
        # Get OpenAI client
        client = get_openai_client()
        
        # Call OpenAI API
        response = client.ChatCompletion.create(
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