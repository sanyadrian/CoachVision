from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlmodel import Session, select
from datetime import datetime, timedelta
from typing import Optional
import jwt
import os
from passlib.context import CryptContext
from database import get_session
from models import UserProfile, UserProfileCreate, UserProfileResponse, FitnessGoal, ExperienceLevel
from pydantic import BaseModel

router = APIRouter()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT settings
from config import settings

SECRET_KEY = settings.SECRET_KEY
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Password utilities
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# JWT utilities
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
    
    user = session.get(UserProfile, user_id)
    if user is None:
        raise credentials_exception
    return user

# Authentication models
class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class UserRegister(BaseModel):
    email: str
    name: str
    password: str

class UserProfileComplete(BaseModel):
    age: int
    weight: float
    height: float
    fitness_goal: FitnessGoal
    experience_level: ExperienceLevel

@router.post("/register", response_model=UserProfileResponse)
async def register_user(
    user_data: UserRegister,
    session: Session = Depends(get_session)
):
    """Register a new user with basic info (email, name, password)"""
    
    # Check if user already exists
    existing_user = session.execute(
        select(UserProfile).where(UserProfile.email == user_data.email)
    ).scalars().first()
    
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists"
        )
    
    # Create user with hashed password and default values
    user_dict = user_data.dict()
    password = user_dict.pop("password")
    hashed_password = get_password_hash(password)
    
    # Create user with minimal required fields
    user = UserProfile(
        email=user_dict["email"],
        name=user_dict["name"],
        hashed_password=hashed_password
        # Other fields will be None until profile is completed
    )
    
    session.add(user)
    session.commit()
    session.refresh(user)
    
    return user

@router.post("/login", response_model=Token)
async def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: Session = Depends(get_session)
):
    """Login user and return access token"""
    
    # Find user by email
    user = session.execute(
        select(UserProfile).where(UserProfile.email == form_data.username)
    ).scalars().first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserProfileResponse)
async def get_current_user(current_user: UserProfile = Depends(verify_token)):
    """Get current authenticated user"""
    return current_user

@router.post("/refresh", response_model=Token)
async def refresh_token(current_user: UserProfile = Depends(verify_token)):
    """Refresh access token"""
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(current_user.id)}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/complete-profile", response_model=UserProfileResponse)
async def complete_user_profile(
    profile_data: UserProfileComplete,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Complete user profile with fitness information"""
    
    # Update user profile with the provided data
    current_user.age = profile_data.age
    current_user.weight = profile_data.weight
    current_user.height = profile_data.height
    current_user.fitness_goal = profile_data.fitness_goal
    current_user.experience_level = profile_data.experience_level
    
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    
    return current_user 