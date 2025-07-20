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

router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

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
    - The video is not too short or too long
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
    
    # Generate unique filename
    file_extension = os.path.splitext(video_file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    try:
        # Save video file
        async with aiofiles.open(file_path, 'wb') as f:
            content = await video_file.read()
            await f.write(content)
        
        # Analyze video using MediaPipe Pose
        analysis_data = analyze_video_with_mediapipe(file_path, exercise_type)
        
        # Create video analysis record
        video_analysis = VideoAnalysis(
            user_id=user_id,
            video_filename=unique_filename,
            exercise_type=exercise_type,
            analysis_result=json.dumps(analysis_data["analysis_result"]),
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
    """Delete a video analysis and its associated file (authenticated users can only delete their own analyses)"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    
    if analysis.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this video analysis")
    
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
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Download the video file for a specific analysis (authenticated users can only download their own videos)"""
    analysis = session.get(VideoAnalysis, analysis_id)
    if not analysis:
        raise HTTPException(status_code=404, detail="Video analysis not found")
    
    if analysis.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to download this video")
    
    file_path = os.path.join(UPLOAD_DIR, analysis.video_filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Video file not found")
    
    # Read the video file and return it as a response
    try:
        with open(file_path, 'rb') as f:
            video_data = f.read()
        
        # Determine content type based on file extension
        content_type = "video/mp4"  # Default
        if file_path.endswith('.mov'):
            content_type = "video/quicktime"
        elif file_path.endswith('.avi'):
            content_type = "video/x-msvideo"
        elif file_path.endswith('.mkv'):
            content_type = "video/x-matroska"
        
        return Response(
            content=video_data,
            media_type=content_type,
            headers={
                "Content-Disposition": f"attachment; filename={analysis.video_filename}"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading video file: {str(e)}") 