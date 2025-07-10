from fastapi import FastAPI, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
from database import engine, create_db_and_tables, get_session
from models import UserProfile, UserProfileCreate, UserProfileResponse

app = FastAPI(
    title="CoachVision API",
    description="AI Sports Coaching App Backend",
    version="1.0.0"
)

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