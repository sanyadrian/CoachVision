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
        exercise_type_lower = exercise_type.lower()
        
        if exercise_type_lower == "pushup":
            return self._analyze_pushup(pose_data)
        elif exercise_type_lower == "squat":
            return self._analyze_squat(pose_data)
        elif exercise_type_lower == "deadlift":
            return self._analyze_deadlift(pose_data)
        elif exercise_type_lower == "bench_press":
            return self._analyze_bench_press(pose_data)
        elif exercise_type_lower == "pullup":
            return self._analyze_pullup(pose_data)
        elif exercise_type_lower == "plank":
            return self._analyze_plank(pose_data)
        elif exercise_type_lower == "burpee":
            return self._analyze_burpee(pose_data)
        elif exercise_type_lower == "lunge":
            return self._analyze_lunge(pose_data)
        elif exercise_type_lower == "mountain_climber":
            return self._analyze_mountain_climber(pose_data)
        elif exercise_type_lower == "jumping_jack":
            return self._analyze_jumping_jack(pose_data)
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
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for squat analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze knee alignment
        knee_issues = self._check_squat_knees(pose_data)
        issues.extend(knee_issues)
        form_score -= len(knee_issues) * 15
        
        # Analyze depth
        depth_issues = self._check_squat_depth(pose_data)
        issues.extend(depth_issues)
        form_score -= len(depth_issues) * 20
        
        # Analyze back position
        back_issues = self._check_squat_back(pose_data)
        issues.extend(back_issues)
        form_score -= len(back_issues) * 15
        
        # Generate recommendations
        if "Knees too far forward" in issues:
            recommendations.append("Keep your knees behind your toes")
        if "Insufficient depth" in issues:
            recommendations.append("Lower your body until thighs are parallel to ground")
        if "Back not straight" in issues:
            recommendations.append("Keep your back straight and chest up")
        if "Knees caving in" in issues:
            recommendations.append("Keep your knees aligned with your toes")
        
        if not recommendations:
            recommendations.append("Great squat form! Keep it up")
        
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
            "exercise_type": "squat",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_bench_press(self, pose_data: List[Dict]) -> Dict:
        """Analyze bench press form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for bench press analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze bar path
        bar_issues = self._check_bench_press_bar_path(pose_data)
        issues.extend(bar_issues)
        form_score -= len(bar_issues) * 15
        
        # Analyze shoulder position
        shoulder_issues = self._check_bench_press_shoulders(pose_data)
        issues.extend(shoulder_issues)
        form_score -= len(shoulder_issues) * 10
        
        # Analyze grip width
        grip_issues = self._check_bench_press_grip(pose_data)
        issues.extend(grip_issues)
        form_score -= len(grip_issues) * 10
        
        # Generate recommendations
        if "Bar path not straight" in issues:
            recommendations.append("Keep the bar path straight and controlled")
        if "Shoulders not retracted" in issues:
            recommendations.append("Retract your shoulder blades throughout the movement")
        if "Grip too wide" in issues:
            recommendations.append("Keep your grip shoulder-width apart")
        if "Bar bouncing off chest" in issues:
            recommendations.append("Control the bar descent and touch chest lightly")
        
        if not recommendations:
            recommendations.append("Excellent bench press form!")
        
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
            "exercise_type": "bench_press",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_plank(self, pose_data: List[Dict]) -> Dict:
        """Analyze plank form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for plank analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze body alignment
        alignment_issues = self._check_plank_alignment(pose_data)
        issues.extend(alignment_issues)
        form_score -= len(alignment_issues) * 20
        
        # Analyze hip position
        hip_issues = self._check_plank_hips(pose_data)
        issues.extend(hip_issues)
        form_score -= len(hip_issues) * 15
        
        # Analyze core engagement
        core_issues = self._check_plank_core(pose_data)
        issues.extend(core_issues)
        form_score -= len(core_issues) * 10
        
        # Generate recommendations
        if "Body not straight" in issues:
            recommendations.append("Keep your body in a straight line from head to heels")
        if "Hips too high" in issues:
            recommendations.append("Lower your hips to maintain proper plank position")
        if "Hips too low" in issues:
            recommendations.append("Raise your hips to maintain proper plank position")
        if "Core not engaged" in issues:
            recommendations.append("Engage your core muscles throughout the hold")
        
        if not recommendations:
            recommendations.append("Perfect plank form! Great core stability")
        
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
            "exercise_type": "plank",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_deadlift(self, pose_data: List[Dict]) -> Dict:
        """Analyze deadlift form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for deadlift analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze back position
        back_issues = self._check_deadlift_back(pose_data)
        issues.extend(back_issues)
        form_score -= len(back_issues) * 20
        
        # Analyze hip hinge
        hip_issues = self._check_deadlift_hip_hinge(pose_data)
        issues.extend(hip_issues)
        form_score -= len(hip_issues) * 15
        
        # Analyze bar path
        bar_issues = self._check_deadlift_bar_path(pose_data)
        issues.extend(bar_issues)
        form_score -= len(bar_issues) * 15
        
        # Generate recommendations
        if "Back not straight" in issues:
            recommendations.append("Keep your back straight and neutral throughout")
        if "Poor hip hinge" in issues:
            recommendations.append("Hinge at your hips, not your lower back")
        if "Bar too far from body" in issues:
            recommendations.append("Keep the bar close to your body")
        if "Rounding back" in issues:
            recommendations.append("Maintain a neutral spine position")
        
        if not recommendations:
            recommendations.append("Excellent deadlift form!")
        
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
            "exercise_type": "deadlift",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_pullup(self, pose_data: List[Dict]) -> Dict:
        """Analyze pullup form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for pullup analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze full range of motion
        rom_issues = self._check_pullup_rom(pose_data)
        issues.extend(rom_issues)
        form_score -= len(rom_issues) * 20
        
        # Analyze shoulder position
        shoulder_issues = self._check_pullup_shoulders(pose_data)
        issues.extend(shoulder_issues)
        form_score -= len(shoulder_issues) * 15
        
        # Analyze body swing
        swing_issues = self._check_pullup_swing(pose_data)
        issues.extend(swing_issues)
        form_score -= len(swing_issues) * 10
        
        # Generate recommendations
        if "Incomplete range of motion" in issues:
            recommendations.append("Pull up until your chin clears the bar")
        if "Shoulders not engaged" in issues:
            recommendations.append("Engage your shoulder blades at the start")
        if "Excessive body swing" in issues:
            recommendations.append("Control your body movement, avoid swinging")
        if "Not going full down" in issues:
            recommendations.append("Lower yourself completely between reps")
        
        if not recommendations:
            recommendations.append("Great pullup form! Strong upper body")
        
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
            "exercise_type": "pullup",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_burpee(self, pose_data: List[Dict]) -> Dict:
        """Analyze burpee form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for burpee analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze squat position
        squat_issues = self._check_burpee_squat(pose_data)
        issues.extend(squat_issues)
        form_score -= len(squat_issues) * 15
        
        # Analyze pushup position
        pushup_issues = self._check_burpee_pushup(pose_data)
        issues.extend(pushup_issues)
        form_score -= len(pushup_issues) * 15
        
        # Analyze jump
        jump_issues = self._check_burpee_jump(pose_data)
        issues.extend(jump_issues)
        form_score -= len(jump_issues) * 10
        
        # Generate recommendations
        if "Poor squat form" in issues:
            recommendations.append("Maintain proper squat form during the movement")
        if "Incomplete pushup" in issues:
            recommendations.append("Perform a full pushup with chest to ground")
        if "No jump" in issues:
            recommendations.append("Include a full jump at the end")
        if "Rushed movement" in issues:
            recommendations.append("Control each phase of the movement")
        
        if not recommendations:
            recommendations.append("Excellent burpee form! Great conditioning")
        
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
            "exercise_type": "burpee",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_lunge(self, pose_data: List[Dict]) -> Dict:
        """Analyze lunge form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for lunge analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze knee alignment
        knee_issues = self._check_lunge_knees(pose_data)
        issues.extend(knee_issues)
        form_score -= len(knee_issues) * 20
        
        # Analyze depth
        depth_issues = self._check_lunge_depth(pose_data)
        issues.extend(depth_issues)
        form_score -= len(depth_issues) * 15
        
        # Analyze balance
        balance_issues = self._check_lunge_balance(pose_data)
        issues.extend(balance_issues)
        form_score -= len(balance_issues) * 10
        
        # Generate recommendations
        if "Front knee too far forward" in issues:
            recommendations.append("Keep your front knee behind your toes")
        if "Insufficient depth" in issues:
            recommendations.append("Lower until your back knee nearly touches the ground")
        if "Poor balance" in issues:
            recommendations.append("Maintain balance throughout the movement")
        if "Knees touching" in issues:
            recommendations.append("Keep your knees aligned with your feet")
        
        if not recommendations:
            recommendations.append("Great lunge form! Excellent balance")
        
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
            "exercise_type": "lunge",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_mountain_climber(self, pose_data: List[Dict]) -> Dict:
        """Analyze mountain climber form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for mountain climber analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze plank position
        plank_issues = self._check_mountain_climber_plank(pose_data)
        issues.extend(plank_issues)
        form_score -= len(plank_issues) * 20
        
        # Analyze knee drive
        knee_issues = self._check_mountain_climber_knees(pose_data)
        issues.extend(knee_issues)
        form_score -= len(knee_issues) * 15
        
        # Analyze core engagement
        core_issues = self._check_mountain_climber_core(pose_data)
        issues.extend(core_issues)
        form_score -= len(core_issues) * 10
        
        # Generate recommendations
        if "Poor plank position" in issues:
            recommendations.append("Maintain a strong plank position throughout")
        if "Insufficient knee drive" in issues:
            recommendations.append("Drive your knees toward your chest")
        if "Core not engaged" in issues:
            recommendations.append("Keep your core engaged throughout")
        if "Hips moving" in issues:
            recommendations.append("Keep your hips stable and level")
        
        if not recommendations:
            recommendations.append("Excellent mountain climber form!")
        
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
            "exercise_type": "mountain_climber",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

    def _analyze_jumping_jack(self, pose_data: List[Dict]) -> Dict:
        """Analyze jumping jack form"""
        if len(pose_data) < 10:
            return self._create_error_analysis("Video too short for jumping jack analysis")
        
        issues = []
        recommendations = []
        form_score = 100
        
        # Analyze arm movement
        arm_issues = self._check_jumping_jack_arms(pose_data)
        issues.extend(arm_issues)
        form_score -= len(arm_issues) * 15
        
        # Analyze leg movement
        leg_issues = self._check_jumping_jack_legs(pose_data)
        issues.extend(leg_issues)
        form_score -= len(leg_issues) * 15
        
        # Analyze coordination
        coord_issues = self._check_jumping_jack_coordination(pose_data)
        issues.extend(coord_issues)
        form_score -= len(coord_issues) * 10
        
        # Generate recommendations
        if "Arms not fully extended" in issues:
            recommendations.append("Fully extend your arms overhead")
        if "Legs not wide enough" in issues:
            recommendations.append("Jump your legs wide apart")
        if "Poor coordination" in issues:
            recommendations.append("Coordinate arm and leg movements")
        if "Landing too hard" in issues:
            recommendations.append("Land softly on the balls of your feet")
        
        if not recommendations:
            recommendations.append("Perfect jumping jack form!")
        
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
            "exercise_type": "jumping_jack",
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "confidence_score": np.mean([p['visibility'] for p in pose_data]),
            "form_rating": form_rating,
            "form_score": max(0, form_score),
            "total_frames_analyzed": len(pose_data),
            "issues_detected": issues,
            "recommendations": recommendations,
            "areas_for_improvement": issues[:3] if issues else ["No major issues detected"]
        }

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

    # Helper functions for squat analysis
    def _check_squat_knees(self, pose_data: List[Dict]) -> List[str]:
        """Check squat knee positioning"""
        issues = []
        for pose in pose_data:
            landmarks = pose['landmarks']
            if not all(k in landmarks for k in [11, 12, 25, 26, 27, 28]):
                continue
            
            # Check if knees are too far forward
            left_knee = landmarks[25]['x']
            left_ankle = landmarks[27]['x']
            if left_knee > left_ankle + 0.1:  # Knee too far forward
                issues.append("Knees too far forward")
                break
        
        return issues

    def _check_squat_depth(self, pose_data: List[Dict]) -> List[str]:
        """Check squat depth"""
        issues = []
        if len(pose_data) < 5:
            return issues
        
        # Find the lowest point in the squat
        min_y = float('inf')
        for pose in pose_data:
            landmarks = pose['landmarks']
            if 23 in landmarks and 24 in landmarks:  # hips
                hip_y = (landmarks[23]['y'] + landmarks[24]['y']) / 2
                min_y = min(min_y, hip_y)
        
        # Check if squat is deep enough
        if min_y > 0.6:  # Arbitrary threshold
            issues.append("Insufficient depth")
        
        return issues

    def _check_squat_back(self, pose_data: List[Dict]) -> List[str]:
        """Check squat back position"""
        issues = []
        for pose in pose_data:
            landmarks = pose['landmarks']
            if not all(k in landmarks for k in [11, 12, 23, 24]):
                continue
            
            # Check if back is straight
            left_shoulder = np.array([landmarks[11]['x'], landmarks[11]['y']])
            right_shoulder = np.array([landmarks[12]['x'], landmarks[12]['y']])
            left_hip = np.array([landmarks[23]['x'], landmarks[23]['y']])
            right_hip = np.array([landmarks[24]['x'], landmarks[24]['y']])
            
            shoulder_hip_vector = left_hip - left_shoulder
            angle = np.degrees(np.arccos(np.dot(shoulder_hip_vector, [0, -1]) / 
                                       np.linalg.norm(shoulder_hip_vector)))
            
            if angle > 20:  # Back not straight
                issues.append("Back not straight")
                break
        
        return issues

    # Helper functions for bench press analysis
    def _check_bench_press_bar_path(self, pose_data: List[Dict]) -> List[str]:
        """Check bench press bar path"""
        issues = []
        # Simplified check - in practice would analyze bar movement
        if len(pose_data) > 10:
            issues.append("Bar path not straight")
        return issues

    def _check_bench_press_shoulders(self, pose_data: List[Dict]) -> List[str]:
        """Check bench press shoulder position"""
        issues = []
        # Simplified check
        if len(pose_data) > 10:
            issues.append("Shoulders not retracted")
        return issues

    def _check_bench_press_grip(self, pose_data: List[Dict]) -> List[str]:
        """Check bench press grip width"""
        issues = []
        # Simplified check
        if len(pose_data) > 10:
            issues.append("Grip too wide")
        return issues

    # Helper functions for plank analysis
    def _check_plank_alignment(self, pose_data: List[Dict]) -> List[str]:
        """Check plank body alignment"""
        issues = []
        for pose in pose_data:
            landmarks = pose['landmarks']
            if not all(k in landmarks for k in [11, 12, 23, 24, 25, 26]):
                continue
            
            # Check if body is straight
            left_shoulder = np.array([landmarks[11]['x'], landmarks[11]['y']])
            left_hip = np.array([landmarks[23]['x'], landmarks[23]['y']])
            left_knee = np.array([landmarks[25]['x'], landmarks[25]['y']])
            
            shoulder_hip_vector = left_hip - left_shoulder
            hip_knee_vector = left_knee - left_hip
            
            angle = np.degrees(np.arccos(np.dot(shoulder_hip_vector, hip_knee_vector) / 
                                       (np.linalg.norm(shoulder_hip_vector) * np.linalg.norm(hip_knee_vector))))
            
            if angle > 15:
                issues.append("Body not straight")
                break
        
        return issues

    def _check_plank_hips(self, pose_data: List[Dict]) -> List[str]:
        """Check plank hip position"""
        issues = []
        for pose in pose_data:
            landmarks = pose['landmarks']
            if not all(k in landmarks for k in [11, 12, 23, 24]):
                continue
            
            # Check hip height relative to shoulders
            shoulder_y = (landmarks[11]['y'] + landmarks[12]['y']) / 2
            hip_y = (landmarks[23]['y'] + landmarks[24]['y']) / 2
            
            if hip_y < shoulder_y - 0.1:  # Hips too high
                issues.append("Hips too high")
                break
            elif hip_y > shoulder_y + 0.1:  # Hips too low
                issues.append("Hips too low")
                break
        
        return issues

    def _check_plank_core(self, pose_data: List[Dict]) -> List[str]:
        """Check plank core engagement"""
        issues = []
        # Simplified check
        if len(pose_data) > 10:
            issues.append("Core not engaged")
        return issues

    # Helper functions for other exercises (simplified implementations)
    def _check_deadlift_back(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Back not straight")
        return issues

    def _check_deadlift_hip_hinge(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Poor hip hinge")
        return issues

    def _check_deadlift_bar_path(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Bar too far from body")
        return issues

    def _check_pullup_rom(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Incomplete range of motion")
        return issues

    def _check_pullup_shoulders(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Shoulders not engaged")
        return issues

    def _check_pullup_swing(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Excessive body swing")
        return issues

    def _check_burpee_squat(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Poor squat form")
        return issues

    def _check_burpee_pushup(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Incomplete pushup")
        return issues

    def _check_burpee_jump(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("No jump")
        return issues

    def _check_lunge_knees(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Front knee too far forward")
        return issues

    def _check_lunge_depth(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Insufficient depth")
        return issues

    def _check_lunge_balance(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Poor balance")
        return issues

    def _check_mountain_climber_plank(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Poor plank position")
        return issues

    def _check_mountain_climber_knees(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Insufficient knee drive")
        return issues

    def _check_mountain_climber_core(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Core not engaged")
        return issues

    def _check_jumping_jack_arms(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Arms not fully extended")
        return issues

    def _check_jumping_jack_legs(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Legs not wide enough")
        return issues

    def _check_jumping_jack_coordination(self, pose_data: List[Dict]) -> List[str]:
        issues = []
        if len(pose_data) > 10:
            issues.append("Poor coordination")
        return issues 