from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List
from database import get_session
from models import (
    UserProfile, UserProfileCreate, UserProfileResponse,
    TrainingPlan, TrainingPlanResponse
)
from routers.auth import verify_token

router = APIRouter()

# User creation is handled by /auth/register endpoint

@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user_profile(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Get user profile by ID (authenticated users can only access their own profile)"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this profile")
    
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# Getting all users is removed for security - users can only access their own profile

@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(
    current_user: UserProfile = Depends(verify_token)
):
    """Get current user's own profile"""
    return current_user

@router.put("/me", response_model=UserProfileResponse)
async def update_my_profile(
    user_data: UserProfileCreate,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Update current user's own profile"""
    for field, value in user_data.dict().items():
        setattr(current_user, field, value)
    
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    return current_user

@router.put("/{user_id}", response_model=UserProfileResponse)
async def update_user_profile(
    user_id: int,
    user_data: UserProfileCreate,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Update user profile (authenticated users can only update their own profile)"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this profile")
    
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
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Delete user profile (authenticated users can only delete their own profile)"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this profile")
    
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    session.delete(user)
    session.commit()
    return {"message": "User deleted successfully"} 