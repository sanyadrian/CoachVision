from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlmodel import Session, select
from typing import List
import os
import uuid
import aiofiles
from datetime import datetime
from database import get_session
from models import (
    UserProfile, VideoAnalysis, VideoAnalysisRequest, VideoAnalysisResponse
)

router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def analyze_video_basic(video_path: str, exercise_type: str) -> dict:
    """
    Basic video analysis (placeholder for future pose estimation)
    In the future, this will use Mediapipe or OpenPose for actual analysis
    """
    # Mock analysis for now
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

@router.post("/analyze", response_model=VideoAnalysisResponse)
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
        async with aiofiles.open(file_path, 'wb') as f:
            content = await video_file.read()
            await f.write(content)
        
        # Analyze video (basic analysis for now)
        analysis_data = analyze_video_basic(file_path, exercise_type)
        
        # Create video analysis record
        video_analysis = VideoAnalysis(
            user_id=user_id,
            video_filename=unique_filename,
            exercise_type=exercise_type,
            analysis_result=str(analysis_data["analysis_result"]),
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

@router.get("/user/{user_id}", response_model=List[VideoAnalysisResponse])
async def get_user_video_analyses(
    user_id: int,
    session: Session = Depends(get_session)
):
    """Get all video analyses for a user"""
    analyses = session.exec(
        select(VideoAnalysis).where(VideoAnalysis.user_id == user_id)
    ).all()
    return analyses

@router.get("/{analysis_id}", response_model=VideoAnalysisResponse)
async def get_video_analysis(
    analysis_id: int,
    session: Session = Depends(get_session)
):
    """Get a specific video analysis"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    return analysis

@router.delete("/{analysis_id}")
async def delete_video_analysis(
    analysis_id: int,
    session: Session = Depends(get_session)
):
    """Delete a video analysis and its associated file"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    
    # Delete the video file
    file_path = os.path.join(UPLOAD_DIR, analysis.video_filename)
    if os.path.exists(file_path):
        os.remove(file_path)
    
    # Delete the database record
    session.delete(analysis)
    session.commit()
    return {"message": "Video analysis deleted successfully"}

@router.get("/download/{analysis_id}")
async def download_video(
    analysis_id: int,
    session: Session = Depends(get_session)
):
    """Download the video file for a specific analysis"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    
    file_path = os.path.join(UPLOAD_DIR, analysis.video_filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Video file not found")
    
    return {"file_path": file_path, "filename": analysis.video_filename} 