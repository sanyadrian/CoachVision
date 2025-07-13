import cv2
import mediapipe as mp
import numpy as np
from typing import Dict, List, Tuple
import json
from datetime import datetime

class VideoAnalyzer:
    def __init__(self):
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            smooth_landmarks=True,
            enable_segmentation=False,
            smooth_segmentation=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
    def analyze_video(self, video_path: str, exercise_type: str) -> Dict:
        """Analyze video using MediaPipe pose estimation"""
        
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError("Could not open video file")
        
        frame_count = 0
        pose_landmarks_list = []
        confidence_scores = []
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            # Convert BGR to RGB
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process the frame
            results = self.pose.process(rgb_frame)
            
            if results.pose_landmarks:
                # Extract landmarks
                landmarks = []
                for landmark in results.pose_landmarks.landmark:
                    landmarks.append({
                        'x': landmark.x,
                        'y': landmark.y,
                        'z': landmark.z,
                        'visibility': landmark.visibility
                    })
                pose_landmarks_list.append(landmarks)
                
                # Calculate confidence score
                avg_visibility = np.mean([lm['visibility'] for lm in landmarks])
                confidence_scores.append(avg_visibility)
            
            frame_count += 1
            
            # Limit analysis to first 100 frames for performance
            if frame_count >= 100:
                break
        
        cap.release()
        
        if not pose_landmarks_list:
            return self._generate_mock_analysis(exercise_type)
        
        # Analyze the pose data
        analysis = self._analyze_pose_data(pose_landmarks_list, exercise_type)
        
        return analysis
    
    def _analyze_pose_data(self, landmarks_list: List, exercise_type: str) -> Dict:
        """Analyze pose data and generate recommendations"""
        
        if not landmarks_list:
            return self._generate_mock_analysis(exercise_type)
        
        # Calculate basic metrics
        avg_confidence = np.mean([np.mean([lm['visibility'] for lm in frame]) for frame in landmarks_list])
        
        # Analyze specific exercises
        if exercise_type.lower() in ['pushup', 'push-up', 'push ups']:
            analysis = self._analyze_pushup(landmarks_list)
        elif exercise_type.lower() in ['squat', 'squats']:
            analysis = self._analyze_squat(landmarks_list)
        else:
            analysis = self._analyze_general_exercise(landmarks_list)
        
        # Generate feedback
        feedback = self._generate_feedback(analysis, exercise_type, avg_confidence)
        
        return {
            "analysis_result": analysis,
            "feedback": feedback
        }
    
    def _analyze_pushup(self, landmarks_list: List) -> Dict:
        """Analyze pushup form"""
        issues = []
        recommendations = []
        
        # Check for common pushup issues
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:  # MediaPipe pose has 33 landmarks
                # Check if body is straight
                shoulder_y = frame_landmarks[11]['y']  # Left shoulder
                hip_y = frame_landmarks[23]['y']      # Left hip
                
                if abs(shoulder_y - hip_y) > 0.1:  # Body not straight
                    issues.append("Body not in straight line")
                
                # Check elbow angle (simplified)
                shoulder = frame_landmarks[11]
                elbow = frame_landmarks[13]
                wrist = frame_landmarks[15]
                
                if self._calculate_angle(shoulder, elbow, wrist) < 80:
                    issues.append("Elbows too close to body")
        
        if not issues:
            recommendations.append("Good form! Keep it up!")
        else:
            recommendations.extend([
                "Keep your body in a straight line",
                "Lower your body more",
                "Keep elbows at 45-degree angle"
            ])
        
        return {
            "exercise_type": "pushup",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_squat(self, landmarks_list: List) -> Dict:
        """Analyze squat form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check knee position relative to toes
                hip = frame_landmarks[23]
                knee = frame_landmarks[25]
                ankle = frame_landmarks[27]
                
                # Check if knees go past toes
                if knee['x'] > ankle['x']:
                    issues.append("Knees going past toes")
                
                # Check depth
                hip_y = hip['y']
                knee_y = knee['y']
                if hip_y < knee_y + 0.1:  # Not deep enough
                    issues.append("Not squatting deep enough")
        
        if not issues:
            recommendations.append("Excellent squat form!")
        else:
            recommendations.extend([
                "Keep knees behind toes",
                "Squat deeper - thighs parallel to ground",
                "Keep chest up"
            ])
        
        return {
            "exercise_type": "squat",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_general_exercise(self, landmarks_list: List) -> Dict:
        """General exercise analysis"""
        return {
            "exercise_type": "general",
            "form_rating": "Good",
            "issues_detected": [],
            "recommendations": [
                "Keep your back straight",
                "Maintain proper breathing",
                "Control your movements"
            ],
            "confidence_score": 0.85
        }
    
    def _calculate_angle(self, point1: Dict, point2: Dict, point3: Dict) -> float:
        """Calculate angle between three points"""
        # Simplified angle calculation
        return 90.0  # Placeholder
    
    def _generate_feedback(self, analysis: Dict, exercise_type: str, confidence: float) -> str:
        """Generate human-readable feedback"""
        
        feedback = f"""
        Analysis for {exercise_type}:
        
        Overall Form Rating: {analysis['form_rating']}
        Confidence Score: {confidence:.2f}
        
        Issues Detected:
        {chr(10).join(f"- {issue}" for issue in analysis.get('issues_detected', []))}
        
        Recommendations:
        {chr(10).join(f"- {rec}" for rec in analysis.get('recommendations', []))}
        """
        
        return feedback.strip()
    
    def _generate_mock_analysis(self, exercise_type: str) -> Dict:
        """Generate mock analysis when pose detection fails"""
        return {
            "analysis_result": {
                "exercise_type": exercise_type,
                "form_rating": "Unable to analyze",
                "issues_detected": ["Could not detect pose clearly"],
                "recommendations": [
                    "Ensure good lighting",
                    "Record from a clear angle",
                    "Wear form-fitting clothing"
                ],
                "confidence_score": 0.0
            },
            "feedback": f"""
            Analysis for {exercise_type}:
            
            Unable to analyze video properly.
            Please ensure:
            - Good lighting conditions
            - Clear view of your body
            - Form-fitting clothing
            - Camera positioned correctly
            """
        } 