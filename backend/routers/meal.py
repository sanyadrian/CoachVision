from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from models import Meal, MealCreate, MealResponse
from database import get_session
from typing import List, Optional
from datetime import date
from pydantic import BaseModel
import base64
import json
import os
import openai

router = APIRouter()

# Initialize OpenAI client
openai.api_key = os.getenv("OPENAI_API_KEY")

class FoodAnalysisRequest(BaseModel):
    image: str  # Base64 encoded image

class FoodAnalysisResponse(BaseModel):
    name: str
    calories: int
    protein: float
    carbs: float
    fats: float

@router.post("/analyze-food", response_model=FoodAnalysisResponse)
def analyze_food_image(request: FoodAnalysisRequest, session: Session = Depends(get_session)):
    """
    Analyze a food image using OpenAI Vision and return nutrition information
    """
    try:
        # Create the prompt for OpenAI
        prompt = """
        Analyze this food image and provide the following information in JSON format:
        - name: the specific food name (e.g., "Grilled Chicken Breast", "Spaghetti with Tomato Sauce")
        - calories: estimated calories per typical serving
        - protein: estimated protein in grams
        - carbs: estimated carbohydrates in grams  
        - fats: estimated fat in grams
        
        Return ONLY valid JSON in this exact format:
        {"name": "food name", "calories": number, "protein": number, "carbs": number, "fats": number}
        """
        
        # Call OpenAI Vision API
        response = openai.ChatCompletion.create(
            model="gpt-4-vision-preview",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{request.image}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=300,
            temperature=0.1
        )
        
        # Extract the response text
        response_text = response.choices[0].message.content.strip()
        print(f"OpenAI response: {response_text}")
        
        # Parse JSON from the response
        try:
            # Clean up the response to extract JSON
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                json_text = response_text[json_start:json_end].strip()
            elif "```" in response_text:
                json_start = response_text.find("```") + 3
                json_end = response_text.find("```", json_start)
                json_text = response_text[json_start:json_end].strip()
            else:
                json_text = response_text
            
            # Parse the JSON
            food_data = json.loads(json_text)
            
            return FoodAnalysisResponse(
                name=food_data["name"],
                calories=int(food_data["calories"]),
                protein=float(food_data["protein"]),
                carbs=float(food_data["carbs"]),
                fats=float(food_data["fats"])
            )
            
        except (json.JSONDecodeError, ValueError, KeyError) as e:
            print(f"Error parsing OpenAI response: {e}")
            # Fallback response
            return FoodAnalysisResponse(
                name="Unknown Food",
                calories=200,
                protein=10.0,
                carbs=20.0,
                fats=5.0
            )
            
    except Exception as e:
        print(f"Error in food analysis: {e}")
        raise HTTPException(status_code=500, detail=f"Food analysis failed: {str(e)}")

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