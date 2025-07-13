from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
from database import get_session
from models import (
    UserProfile, UserProfileCreate, UserProfileResponse,
    TrainingPlan, TrainingPlanResponse
)

router = APIRouter()

@router.post("/", response_model=UserProfileResponse)
async def create_user_profile(
    user_data: UserProfileCreate,
    session: Session = Depends(get_session)
):
    """Create a new user profile"""
    user = UserProfile(**user_data.dict())
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user_profile(
    user_id: int,
    session: Session = Depends(get_session)
):
    """Get user profile by ID"""
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/", response_model=List[UserProfileResponse])
async def get_all_users(session: Session = Depends(get_session)):
    """Get all user profiles"""
    users = session.exec(select(UserProfile)).all()
    return users

@router.put("/{user_id}", response_model=UserProfileResponse)
async def update_user_profile(
    user_id: int,
    user_data: UserProfileCreate,
    session: Session = Depends(get_session)
):
    """Update user profile"""
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    for field, value in user_data.dict().items():
        setattr(user, field, value)
    
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@router.delete("/{user_id}")
async def delete_user_profile(
    user_id: int,
    session: Session = Depends(get_session)
):
    """Delete user profile"""
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    session.delete(user)
    session.commit()
    return {"message": "User deleted successfully"} 