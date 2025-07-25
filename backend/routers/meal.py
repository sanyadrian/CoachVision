from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from models import Meal, MealCreate, MealResponse
from database import get_session
from typing import List, Optional
from datetime import date

router = APIRouter()

@router.post("", response_model=MealResponse)
def create_meal(meal: MealCreate, session: Session = Depends(get_session)):
    db_meal = Meal(**meal.dict())
    session.add(db_meal)
    session.commit()
    session.refresh(db_meal)
    return db_meal

@router.get("/user/{user_id}", response_model=List[MealResponse])
def get_meals_for_user(user_id: int, date: Optional[date] = Query(None), session: Session = Depends(get_session)):
    query = select(Meal).where(Meal.user_id == user_id)
    if date:
        query = query.where(Meal.date == date)
    result = session.execute(query)
    meals = result.scalars().all()
    return meals 