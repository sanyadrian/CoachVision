from fastapi import FastAPI, Depends, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select
from typing import List
import os
import uuid
import json
from datetime import datetime

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("Warning: OpenAI package not available. Training plans will use mock data.")

from database import engine, create_db_and_tables, get_session
from models import UserProfile, UserProfileCreate, UserProfileResponse, TrainingPlan, TrainingPlanRequest, TrainingPlanResponse, VideoAnalysis, VideoAnalysisRequest, VideoAnalysisResponse

# Import video analyzer
try:
    from video_analysis import VideoAnalyzer
    VIDEO_ANALYSIS_AVAILABLE = True
    video_analyzer = VideoAnalyzer()
except ImportError:
    VIDEO_ANALYSIS_AVAILABLE = False
    print("Warning: Video analysis dependencies not available. Using mock analysis.")

app = FastAPI(
    title="CoachVision API",
    description="AI Sports Coaching App Backend",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Create database tables on startup
@app.on_event("startup")
async def startup_event():
    create_db_and_tables()

@app.get("/")
async def root():
    return {"message": "Welcome to CoachVision API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/test")
async def test_endpoint():
    return {"message": "API is working!"}

# User endpoints
@app.post("/users/", response_model=UserProfileResponse)
async def create_user(user_data: UserProfileCreate, session: Session = Depends(get_session)):
    """Create a new user profile"""
    user = UserProfile(**user_data.dict())
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@app.get("/users/{user_id}", response_model=UserProfileResponse)
async def get_user(user_id: int, session: Session = Depends(get_session)):
    """Get user profile by ID"""
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/users/", response_model=List[UserProfileResponse])
async def get_all_users(session: Session = Depends(get_session)):
    """Get all user profiles"""
    statement = select(UserProfile)
    users = session.execute(statement).scalars().all()
    return users

# Training Plan endpoints
@app.post("/plans/generate", response_model=TrainingPlanResponse)
async def generate_training_plan(request: TrainingPlanRequest, session: Session = Depends(get_session)):
    """Generate a personalized training plan using OpenAI"""
    
    # Get user profile
    user = session.get(UserProfile, request.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if OpenAI is available
    if not OPENAI_AVAILABLE:
        # Return a mock plan if OpenAI is not available
        mock_plan = f"""
        Mock Training Plan for {user.name}
        
        Weekly Schedule:
        - Monday: Cardio (30 min)
        - Tuesday: Strength Training
        - Wednesday: Rest
        - Thursday: Cardio (30 min)
        - Friday: Strength Training
        - Saturday: Flexibility
        - Sunday: Rest
        
        Note: Install openai>=1.0.0 for AI-generated plans
        """
        
        training_plan = TrainingPlan(
            user_id=user.id,
            plan_type=request.plan_type,
            content=mock_plan
        )
        
        session.add(training_plan)
        session.commit()
        session.refresh(training_plan)
        return training_plan
    
    # Check if OpenAI API key is available
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        # Return a mock plan if no API key
        mock_plan = f"""
        Mock Training Plan for {user.name}
        
        Weekly Schedule:
        - Monday: Cardio (30 min)
        - Tuesday: Strength Training
        - Wednesday: Rest
        - Thursday: Cardio (30 min)
        - Friday: Strength Training
        - Saturday: Flexibility
        - Sunday: Rest
        
        Note: Add OPENAI_API_KEY to .env for AI-generated plans
        """
        
        training_plan = TrainingPlan(
            user_id=user.id,
            plan_type=request.plan_type,
            content=mock_plan
        )
        
        session.add(training_plan)
        session.commit()
        session.refresh(training_plan)
        return training_plan
    
    try:
        # Initialize OpenAI client
        client = OpenAI(api_key=api_key)
        
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
        """
        
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
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating plan: {str(e)}")

@app.get("/plans/user/{user_id}", response_model=List[TrainingPlanResponse])
async def get_user_training_plans(user_id: int, session: Session = Depends(get_session)):
    """Get all training plans for a user"""
    statement = select(TrainingPlan).where(TrainingPlan.user_id == user_id)
    plans = session.execute(statement).scalars().all()
    return plans

# Video Analysis endpoints
def analyze_video_basic(exercise_type: str) -> dict:
    """Basic mock video analysis (fallback)"""
    analysis_result = {
        "exercise_type": exercise_type,
        "analysis_timestamp": datetime.utcnow().isoformat(),
        "confidence_score": 0.85,
        "form_rating": "Good",
        "recommendations": [
            "Keep your back straight",
            "Lower your body more",
            "Maintain proper breathing"
        ],
        "areas_for_improvement": [
            "Depth of movement",
            "Core engagement"
        ]
    }
    
    feedback = f"""
    Analysis for {exercise_type}:
    
    Overall Form Rating: {analysis_result['form_rating']}
    Confidence Score: {analysis_result['confidence_score']}
    
    Recommendations:
    {chr(10).join(f"- {rec}" for rec in analysis_result['recommendations'])}
    
    Areas for Improvement:
    {chr(10).join(f"- {area}" for area in analysis_result['areas_for_improvement'])}
    """
    
    return {
        "analysis_result": analysis_result,
        "feedback": feedback
    }

@app.post("/videos/analyze", response_model=VideoAnalysisResponse)
async def analyze_video(
    user_id: int,
    exercise_type: str,
    video_file: UploadFile = File(...),
    session: Session = Depends(get_session)
):
    """Upload and analyze a video"""
    
    # Check if user exists
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Validate file type
    if not video_file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="File must be a video")
    
    # Generate unique filename
    file_extension = os.path.splitext(video_file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    try:
        # Save video file
        with open(file_path, "wb") as f:
            content = await video_file.read()
            f.write(content)
        
        # Analyze video using real analysis if available
        if VIDEO_ANALYSIS_AVAILABLE:
            try:
                analysis_data = video_analyzer.analyze_video(file_path, exercise_type)
            except Exception as e:
                print(f"Video analysis failed: {e}")
                analysis_data = analyze_video_basic(exercise_type)
        else:
            analysis_data = analyze_video_basic(exercise_type)
        
        # Create video analysis record
        video_analysis = VideoAnalysis(
            user_id=user_id,
            video_filename=unique_filename,
            exercise_type=exercise_type,
            analysis_result=json.dumps(analysis_data["analysis_result"]),
            feedback=analysis_data["feedback"]
        )
        
        session.add(video_analysis)
        session.commit()
        session.refresh(video_analysis)
        
        return video_analysis
        
    except Exception as e:
        # Clean up file if analysis fails
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"Error analyzing video: {str(e)}")

@app.get("/videos/user/{user_id}", response_model=List[VideoAnalysisResponse])
async def get_user_video_analyses(user_id: int, session: Session = Depends(get_session)):
    """Get all video analyses for a user"""
    statement = select(VideoAnalysis).where(VideoAnalysis.user_id == user_id)
    analyses = session.execute(statement).scalars().all()
    return analyses

@app.get("/videos/{analysis_id}", response_model=VideoAnalysisResponse)
async def get_video_analysis(analysis_id: int, session: Session = Depends(get_session)):
    """Get a specific video analysis"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    return analysis 