from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class FitnessGoal(str, Enum):
    WEIGHT_LOSS = "weight_loss"
    MUSCLE_GAIN = "muscle_gain"
    ENDURANCE = "endurance"
    FLEXIBILITY = "flexibility"
    GENERAL_FITNESS = "general_fitness"

class ExperienceLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"

class UserProfile(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(max_length=255, unique=True, index=True)
    name: str = Field(max_length=100)
    age: Optional[int] = Field(default=None, ge=1, le=120)
    weight: Optional[float] = Field(default=None, ge=20, le=300)  # in kg
    height: Optional[float] = Field(default=None, ge=100, le=250)  # in cm
    fitness_goal: Optional[FitnessGoal] = Field(default=None)
    experience_level: Optional[ExperienceLevel] = Field(default=None)
    hashed_password: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class TrainingPlan(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="userprofile.id")
    plan_type: str = Field(max_length=50)  # "weekly", "daily", etc.
    content: str  # JSON string or text content
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True)
    completed_days: Optional[str] = Field(default="[]")  # JSON array of completed days

class VideoAnalysis(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="userprofile.id")
    video_filename: str = Field(max_length=255)
    exercise_type: str = Field(max_length=100)
    analysis_result: str  # JSON string with analysis data
    feedback: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

# Pydantic models for API requests/responses
class UserProfileCreate(SQLModel):
    email: str
    name: str
    age: int
    weight: float
    height: float
    fitness_goal: FitnessGoal
    experience_level: ExperienceLevel

class UserProfileResponse(SQLModel):
    id: int
    email: str
    name: str
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    fitness_goal: Optional[FitnessGoal] = None
    experience_level: Optional[ExperienceLevel] = None
    created_at: datetime

class TrainingPlanRequest(SQLModel):
    user_id: int
    plan_type: str = "weekly"

class TrainingPlanUpdateRequest(SQLModel):
    completed_days: list[str]

class TrainingPlanResponse(SQLModel):
    id: int
    user_id: int
    plan_type: str
    content: str
    created_at: datetime
    is_active: bool
    completed_days: str

class VideoAnalysisRequest(SQLModel):
    user_id: int
    exercise_type: str

class VideoAnalysisResponse(SQLModel):
    id: int
    user_id: int
    video_filename: str
    exercise_type: str
    analysis_result: str
    feedback: str
    created_at: datetime 