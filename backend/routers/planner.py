from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
import json
import os
import openai
from datetime import datetime, timedelta
from calendar import Calendar
from database import get_session
from models import (
    UserProfile, TrainingPlan, TrainingPlanRequest, TrainingPlanResponse, TrainingPlanUpdateRequest
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
    
    # Get current date for weekly plan - always start from Monday
    current_date = datetime.now()
    calendar = Calendar()
    weekday = current_date.weekday()  # Monday = 0, Tuesday = 1, ..., Sunday = 6
    days_to_monday = weekday  # Days to go back to reach Monday
    
    # Calculate the Monday of the current week
    monday_date = current_date - timedelta(days=days_to_monday)
    
    plan_duration = "7 days starting from Monday of the current week"
    plan_structure = "starting from Monday and continuing through Sunday (7 days total)"
    
    # Create personalized prompt based on user's goals and experience
    goal_instructions = ""
    if user.fitness_goal == "weight_loss":
        goal_instructions = "Focus on calorie deficit, high-intensity cardio, and strength training to build lean muscle while burning fat. Include more cardio sessions and circuit training."
    elif user.fitness_goal == "muscle_gain":
        goal_instructions = "Focus on progressive overload, compound movements, and higher calorie intake. Include more rest days and prioritize strength training with moderate rep ranges (6-12 reps)."
    elif user.fitness_goal == "strength":
        goal_instructions = "Focus on compound lifts, lower rep ranges (1-6 reps), and longer rest periods. Prioritize deadlifts, squats, bench press, and overhead press."
    elif user.fitness_goal == "endurance":
        goal_instructions = "Focus on cardiovascular training, longer duration exercises, and building stamina. Include running, cycling, swimming, and high-rep resistance training."
    
    experience_instructions = ""
    if user.experience_level == "beginner":
        experience_instructions = "Start with basic exercises, focus on proper form, lower intensity, and gradual progression. Include more rest days and simpler workout structures."
    elif user.experience_level == "intermediate":
        experience_instructions = "Include moderate complexity exercises, balanced intensity, and structured progression. Mix compound and isolation movements."
    elif user.experience_level == "advanced":
        experience_instructions = "Include advanced techniques, higher intensity, complex movements, and minimal rest periods. Focus on periodization and advanced training methods."
    
    # Create prompt for OpenAI
    prompt = f"""
    Create a personalized {request.plan_type} training and diet plan for the following user:
    
    Name: {user.name}
    Age: {user.age}
    Weight: {user.weight} kg
    Height: {user.height} cm
    Fitness Goal: {user.fitness_goal}
    Experience Level: {user.experience_level}
    
    PERSONALIZATION REQUIREMENTS:
    - Fitness Goal ({user.fitness_goal}): {goal_instructions}
    - Experience Level ({user.experience_level}): {experience_instructions}
    
    The plan should cover {plan_duration}. {plan_structure}.
    
    IMPORTANT: The plan should always start from Monday and end on Sunday, regardless of what day the plan is created.
    
    IMPORTANT: You MUST return the response in this EXACT JSON format structure:
    
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
    
    REQUIREMENTS:
    1. Use "workouts" key with day names (monday, tuesday, etc.)
    2. Each day MUST have "workout_type" and "exercises" keys
    3. "exercises" MUST be an array of strings with exercise name and sets/reps
    4. "nutrition" MUST have "calorie_target", "foods_to_eat", and "foods_to_avoid" keys
    5. "recommendations" MUST have "rest_days", "recovery_tips", and "progress_tracking" keys
    6. Follow the EXACT structure above - do not change key names or data types
    7. Start from Monday and continue for 7 days in order (Monday through Sunday)
    8. Tailor calorie targets based on fitness goal:
       - Weight Loss: 1800-2200 calories (deficit)
       - Muscle Gain: 2800-3500 calories (surplus)
       - Strength: 2500-3000 calories (maintenance/slight surplus)
       - Endurance: 2500-3200 calories (adequate fuel)
    9. Adjust exercise intensity and complexity based on experience level
    10. Ensure workouts align with the specific fitness goal requirements above
    
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
        
        # Clean up the response - remove markdown code blocks if present
        if plan_content.startswith("```json"):
            plan_content = plan_content.replace("```json", "").replace("```", "").strip()
        elif plan_content.startswith("```"):
            plan_content = plan_content.replace("```", "").strip()
        
        # Validate that the content is valid JSON
        try:
            json.loads(plan_content)
        except json.JSONDecodeError as e:
            print(f"Invalid JSON from OpenAI: {e}")
            print(f"Raw content: {plan_content}")
            raise HTTPException(status_code=500, detail="Failed to generate valid training plan")
        
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

@router.put("/{plan_id}/completed-days")
async def update_completed_days(
    plan_id: int,
    request: TrainingPlanUpdateRequest,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Update completed days for a training plan"""
    plan = session.get(TrainingPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    if plan.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this plan")
    
    # Convert list to JSON string
    plan.completed_days = json.dumps(request.completed_days)
    session.commit()
    session.refresh(plan)
    
    return {"message": "Completed days updated successfully", "completed_days": request.completed_days} 

@router.put("/{plan_id}/edit-day")
async def edit_plan_day(
    plan_id: int,
    request: dict,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Edit a specific day in a training plan"""
    plan = session.get(TrainingPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Training plan not found")
    
    if plan.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this plan")
    
    try:
        # Parse the current plan content
        plan_data = json.loads(plan.content)
        
        # Update the specific day
        day_name = request.get("day_name")
        new_workout = request.get("workout")
        
        if not day_name or not new_workout:
            raise HTTPException(status_code=400, detail="Missing day_name or workout data")
        
        # Update the workout for the specific day
        if "workouts" in plan_data and day_name in plan_data["workouts"]:
            plan_data["workouts"][day_name] = new_workout
            
            # Update the plan content
            plan.content = json.dumps(plan_data)
            session.commit()
            session.refresh(plan)
            
            return {"message": f"Day {day_name} updated successfully", "plan": plan}
        else:
            raise HTTPException(status_code=400, detail=f"Day {day_name} not found in plan")
            
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid plan content format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating plan: {str(e)}") 