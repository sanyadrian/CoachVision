import cv2
import mediapipe as mp
import numpy as np
from typing import List, Dict, Tuple, Optional
import json
from datetime import datetime

class MediaPipePoseAnalyzer:
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
        self.mp_drawing = mp.solutions.drawing_utils
        self.mp_drawing_styles = mp.solutions.drawing_styles

    def analyze_video(self, video_path: str, exercise_type: str) -> Dict:
        """
        Analyze a video file for exercise form using MediaPipe Pose
        """
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise ValueError(f"Could not open video file: {video_path}")
        
        frame_count = 0
        pose_data = []
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        
        print(f"Analyzing video with {total_frames} frames...")
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            # Convert BGR to RGB
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Process the frame
            results = self.pose.process(rgb_frame)
            
            if results.pose_landmarks:
                # Extract pose landmarks
                landmarks = self._extract_landmarks(results.pose_landmarks)
                pose_data.append({
                    'frame': frame_count,
                    'landmarks': landmarks,
                    'visibility': self._calculate_visibility(results.pose_landmarks)
                })
            
            frame_count += 1
            
            # Progress update every 50 frames
            if frame_count % 50 == 0:
                print(f"Processed {frame_count}/{total_frames} frames...")
        
        cap.release()
        
        if not pose_data:
            return self._create_error_analysis("No pose detected in video")
        
        # Analyze the exercise based on pose data
        analysis_result = self._analyze_exercise(pose_data, exercise_type)
        
        return analysis_result

    def _extract_landmarks(self, pose_landmarks) -> Dict:
        """Extract landmark coordinates from MediaPipe pose results"""
        landmarks = {}
        for i, landmark in enumerate(pose_landmarks.landmark):
            landmarks[i] = {
                'x': landmark.x,
                'y': landmark.y,
                'z': landmark.z,
                'visibility': landmark.visibility
            }
        return landmarks

    def _calculate_visibility(self, pose_landmarks) -> float:
        """Calculate overall pose visibility score"""
        visibilities = [landmark.visibility for landmark in pose_landmarks.landmark]
        return np.mean(visibilities)

    def _analyze_exercise(self, pose_data: List[Dict], exercise_type: str) -> Dict:
        """Analyze exercise form based on pose data"""
        if exercise_type.lower() == "pushup":
            return self._analyze_pushup(pose_data)
        elif exercise_type.lower() == "squat":
            return self._analyze_squat(pose_data)
        elif exercise_type.lower() == "plank":
            return self._analyze_plank(pose_data)
        else:
            return self._analyze_generic(pose_data, exercise_type)

    def _analyze_pushup(self, pose_data: List[Dict]) -> Dict:
        """Analyze pushup form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for pushup analysis")
        
        # Key landmarks for pushup analysis
        # 11: left shoulder, 12: right shoulder, 23: left hip, 24: right hip
        # 25: left knee, 26: right knee, 27: left ankle, 28: right ankle
        # 15: left wrist, 16: right wrist, 13: left elbow, 14: right elbow
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze body alignment
        alignment_issues = self._check_body_alignment(pose_data)
        issues.extend(alignment_issues)
        form_score -= len(alignment_issues) * 10
        
        # Analyze arm positioning
        arm_issues = self._check_pushup_arms(pose_data)
        issues.extend(arm_issues)
        form_score -= len(arm_issues) * 15
        
        # Analyze depth
        depth_issues = self._check_pushup_depth(pose_data)
        issues.extend(depth_issues)
        form_score -= len(depth_issues) * 20
        
        # Generate recommendations
        if "Body not straight" in issues:
            recommendations.append("Keep your body in a straight line from head to heels")
        if "Arms too wide" in issues:
            recommendations.append("Keep your hands shoulder-width apart")
        if "Insufficient depth" in issues:
            recommendations.append("Lower your body until your chest nearly touches the ground")
        if "Elbows flaring out" in issues:
            recommendations.append("Keep your elbows close to your body")
        
        if not recommendations:
            recommendations.append("Great form! Keep up the good work")
        
        # Determine form rating
        if form_score >= 90:
            form_rating = "Excellent"
        elif form_score >= 75:
            form_rating = "Good"
        elif form_score >= 60:
            form_rating = "Fair"
        else:
            form_rating = "Poor"
        
        return {
            "exercise_type": "pushup",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _check_body_alignment(self, pose_data: List[Dict]) -> List[str]:
        """Check if body is in a straight line"""
        issues = []
        
        for pose in pose_data:
            landmarks = pose['landmarks']
            
            # Check if key points are available
            if not all(k in landmarks for k in [11, 12, 23, 24, 25, 26]):
                continue
            
            # Calculate body line (shoulder to hip to ankle)
            left_shoulder = np.array([landmarks[11]['x'], landmarks[11]['y']])
            right_shoulder = np.array([landmarks[12]['x'], landmarks[12]['y']])
            left_hip = np.array([landmarks[23]['x'], landmarks[23]['y']])
            right_hip = np.array([landmarks[24]['x'], landmarks[24]['y']])
            left_knee = np.array([landmarks[25]['x'], landmarks[25]['y']])
            right_knee = np.array([landmarks[26]['x'], landmarks[26]['y']])
            
            # Check if body is straight (shoulder-hip-knee alignment)
            shoulder_hip_vector = left_hip - left_shoulder
            hip_knee_vector = left_knee - left_hip
            
            # Calculate angle between vectors
            angle = np.degrees(np.arccos(np.dot(shoulder_hip_vector, hip_knee_vector) / 
                                       (np.linalg.norm(shoulder_hip_vector) * np.linalg.norm(hip_knee_vector))))
            
            if angle > 15:  # Allow some tolerance
                issues.append("Body not straight")
                break
        
        return issues

    def _check_pushup_arms(self, pose_data: List[Dict]) -> List[str]:
        """Check arm positioning for pushups"""
        issues = []
        
        for pose in pose_data:
            landmarks = pose['landmarks']
            
            if not all(k in landmarks for k in [11, 12, 15, 16]):
                continue
            
            # Check hand positioning relative to shoulders
            left_shoulder = landmarks[11]['x']
            right_shoulder = landmarks[12]['x']
            left_wrist = landmarks[15]['x']
            right_wrist = landmarks[16]['x']
            
            shoulder_width = abs(right_shoulder - left_shoulder)
            hand_width = abs(right_wrist - left_wrist)
            
            # Hands should be roughly shoulder-width apart
            if hand_width > shoulder_width * 1.5:
                issues.append("Arms too wide")
                break
        
        return issues

    def _check_pushup_depth(self, pose_data: List[Dict]) -> List[str]:
        """Check if pushup has sufficient depth"""
        issues = []
        
        if len(pose_data) < 5:
            return issues
        
        # Find the lowest point (highest y value) in the movement
        min_y = float('inf')
        for pose in pose_data:
            landmarks = pose['landmarks']
            if 11 in landmarks and 12 in landmarks:  # shoulders
                shoulder_y = (landmarks[11]['y'] + landmarks[12]['y']) / 2
                min_y = min(min_y, shoulder_y)
        
        # Check if the movement has sufficient depth
        # This is a simplified check - in practice, you'd compare start and end positions
        if min_y < 0.3:  # Arbitrary threshold
            issues.append("Insufficient depth")
        
        return issues

    def _analyze_squat(self, pose_data: List[Dict]) -> Dict:
        """Analyze squat form"""
        # Similar analysis for squats
        return self._analyze_generic(pose_data, "squat")

    def _analyze_plank(self, pose_data: List[Dict]) -> Dict:
        """Analyze plank form"""
        # Similar analysis for planks
        return self._analyze_generic(pose_data, "plank")

    def _analyze_generic(self, pose_data: List[Dict], exercise_type: str) -> Dict:
        """Generic analysis for exercises not yet implemented"""
        visibility_score = np.mean([p['visibility'] for p in pose_data])
        
        return {
            "exercise_type": exercise_type,
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": visibility_score,
            "form_rating": "Good" if visibility_score > 0.7 else "Fair",
            "form_score": int(visibility_score * 100),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": ["Analysis not yet implemented for this exercise"],
            "recommendations": ["This exercise type will be fully analyzed in a future update"],
            "areas_for_improvement": ["Exercise-specific analysis coming soon"]
        }

    def _create_error_analysis(self, error_message: str) -> Dict:
        """Create an error analysis result"""
        return {
            "exercise_type": "unknown",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": 0.0,
            "form_rating": "Error",
            "form_score": 0,
            "total_frames_analyzed": 0,
            "issues_detected": [error_message],
            "recommendations": ["Please ensure the video shows a clear view of the exercise"],
            "areas_for_improvement": ["Video quality or pose detection issues"]
        } 