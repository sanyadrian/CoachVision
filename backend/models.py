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
    name: str = Field(max_length=100)
    age: int = Field(ge=1, le=120)
    weight: float = Field(ge=20, le=300)
    height: float = Field(ge=100, le=250)
    fitness_goal: FitnessGoal
    experience_level: ExperienceLevel
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# Pydantic models for API requests/responses
class UserProfileCreate(SQLModel):
    name: str
    age: int
    weight: float
    height: float
    fitness_goal: FitnessGoal
    experience_level: ExperienceLevel

class UserProfileResponse(SQLModel):
    id: int
    name: str
    age: int
    weight: float
    height: float
    fitness_goal: FitnessGoal
    experience_level: ExperienceLevel
    created_at: datetime 