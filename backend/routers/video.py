from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Response
from sqlmodel import Session, select
from typing import List
import os
import uuid
import aiofiles
import json
from datetime import datetime
from database import get_session
from models import (
    UserProfile, VideoAnalysis, VideoAnalysisRequest, VideoAnalysisResponse
)
from routers.auth import verify_token
from mediapipe_analysis import MediaPipePoseAnalyzer
import cv2

router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Video analysis settings
MAX_VIDEO_DURATION = 10  # seconds
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

def get_video_duration(video_path: str) -> float:
    """Get video duration in seconds"""
    try:
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return 0
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = frame_count / fps if fps > 0 else 0
        
        cap.release()
        return duration
    except Exception as e:
        print(f"Error getting video duration: {e}")
        return 0

def analyze_video_with_mediapipe(video_path: str, exercise_type: str) -> dict:
    """
    Real video analysis using MediaPipe Pose estimation
    """
    try:
        analyzer = MediaPipePoseAnalyzer()
        analysis_result = analyzer.analyze_video(video_path, exercise_type)
        
        # Generate feedback text
        feedback = f"""
        Analysis for {analysis_result['exercise_type']}:
        
        Overall Form Rating: {analysis_result['form_rating']}
        Form Score: {analysis_result['form_score']}/100
        Confidence Score: {analysis_result['confidence_score']:.2f}
        Frames Analyzed: {analysis_result['total_frames_analyzed']}
        
        Recommendations:
        {chr(10).join(f"- {rec}" for rec in analysis_result['recommendations'])}
        
        Areas for Improvement:
        {chr(10).join(f"- {area}" for area in analysis_result['areas_for_improvement'])}
        
        Issues Detected:
        {chr(10).join(f"- {issue}" for issue in analysis_result['issues_detected']) if analysis_result['issues_detected'] else "- No major issues detected"}
        """
        
        return {
            "analysis_result": analysis_result,
            "feedback": feedback
        }
        
    except Exception as e:
        print(f"Error in MediaPipe analysis: {str(e)}")
        # Fallback to basic analysis if MediaPipe fails
        return analyze_video_basic_fallback(video_path, exercise_type, str(e))

def analyze_video_basic_fallback(video_path: str, exercise_type: str, error_message: str) -> dict:
    """
    Fallback analysis when MediaPipe fails
    """
    analysis_result = {
        "exercise_type": exercise_type,
        "analysis_timestamp": datetime.utcnow().isoformat(),
        "confidence_score": 0.0,
        "form_rating": "Error",
        "form_score": 0,
        "total_frames_analyzed": 0,
        "issues_detected": [f"Analysis failed: {error_message}"],
        "recommendations": ["Please try again with a clearer video"],
        "areas_for_improvement": ["Video quality or pose detection issues"]
    }
    
    feedback = f"""
    Analysis for {exercise_type}:
    
    Error: {error_message}
    
    Please ensure:
    - The video shows a clear view of the exercise
    - Good lighting conditions
    - The person is fully visible in the frame
    - The video is not too short or too long (max 10 seconds)
    """
    
    return {
        "analysis_result": analysis_result,
        "feedback": feedback
    }

@router.post("/analyze", response_model=VideoAnalysisResponse)
async def analyze_video(
    user_id: int = Form(...),
    exercise_type: str = Form(...),
    video_file: UploadFile = File(...),
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Upload and analyze a video (authenticated users can only analyze videos for themselves)"""
    
    # Verify user can only analyze videos for themselves
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to analyze videos for other users")
    
    # Check if user exists
    user = session.get(UserProfile, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Validate file type
    if not video_file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="File must be a video")
    
    # Check file size
    content = await video_file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400, 
            detail=f"Video file too large. Maximum size is {MAX_FILE_SIZE // (1024*1024)}MB"
        )
    
    # Generate unique filename
    file_extension = os.path.splitext(video_file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    try:
        # Save video file temporarily
        async with aiofiles.open(file_path, 'wb') as f:
            await f.write(content)
        
        # Check video duration
        duration = get_video_duration(file_path)
        if duration > MAX_VIDEO_DURATION:
            # Clean up file
            os.remove(file_path)
            raise HTTPException(
                status_code=400, 
                detail=f"Video too long. Maximum duration is {MAX_VIDEO_DURATION} seconds. Your video is {duration:.1f} seconds."
            )
        
        if duration < 1:
            # Clean up file
            os.remove(file_path)
            raise HTTPException(
                status_code=400,
                detail="Video too short. Please upload a video between 1-10 seconds."
            )
        
        # Analyze video using MediaPipe Pose
        analysis_data = analyze_video_with_mediapipe(file_path, exercise_type)
        
        # Create video analysis record (without storing the video file)
        video_analysis = VideoAnalysis(
            user_id=user_id,
            video_filename="",  # No file stored for privacy
            exercise_type=exercise_type,
            analysis_result=json.dumps(analysis_data["analysis_result"]),
            feedback=analysis_data["feedback"]
        )
        
        session.add(video_analysis)
        session.commit()
        session.refresh(video_analysis)
        
        # Clean up video file after analysis (privacy-first approach)
        if os.path.exists(file_path):
            os.remove(file_path)
        
        return video_analysis
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        # Clean up file if analysis fails
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"Error analyzing video: {str(e)}")

@router.get("/user/{user_id}", response_model=List[VideoAnalysisResponse])
async def get_user_video_analyses(
    user_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Get all video analyses for a user (authenticated users can only access their own analyses)"""
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to access other users' video analyses")
    
    analyses = session.execute(
        select(VideoAnalysis).where(VideoAnalysis.user_id == user_id)
    ).scalars().all()
    return analyses

@router.get("/{analysis_id}", response_model=VideoAnalysisResponse)
async def get_video_analysis(
    analysis_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Get a specific video analysis (authenticated users can only access their own analyses)"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    
    if analysis.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this video analysis")
    
    return analysis

@router.delete("/{analysis_id}")
async def delete_video_analysis(
    analysis_id: int,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Delete a video analysis (authenticated users can only delete their own analyses)"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    
    if analysis.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this video analysis")
    
    # Delete the database record (no video file to delete since we don't store them)
    session.delete(analysis)
    session.commit()
    return {"message": "Video analysis deleted successfully"} 