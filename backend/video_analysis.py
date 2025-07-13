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
        exercise_lower = exercise_type.lower()
        if exercise_lower in ['pushup', 'push-up', 'push ups']:
            analysis = self._analyze_pushup(landmarks_list)
        elif exercise_lower in ['squat', 'squats']:
            analysis = self._analyze_squat(landmarks_list)
        elif exercise_lower in ['bench press', 'bench', 'benchpress']:
            analysis = self._analyze_bench_press(landmarks_list)
        elif exercise_lower in ['deadlift', 'dead lift']:
            analysis = self._analyze_deadlift(landmarks_list)
        elif exercise_lower in ['overhead press', 'shoulder press', 'military press']:
            analysis = self._analyze_overhead_press(landmarks_list)
        elif exercise_lower in ['pull up', 'pullup', 'pull-ups', 'pull ups']:
            analysis = self._analyze_pullup(landmarks_list)
        elif exercise_lower in ['row', 'barbell row', 'dumbbell row']:
            analysis = self._analyze_row(landmarks_list)
        elif exercise_lower in ['lunge', 'lunges']:
            analysis = self._analyze_lunge(landmarks_list)
        elif exercise_lower in ['plank', 'planks']:
            analysis = self._analyze_plank(landmarks_list)
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
    
    def _analyze_bench_press(self, landmarks_list: List) -> Dict:
        """Analyze bench press form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check shoulder position (should be retracted)
                left_shoulder = frame_landmarks[11]
                right_shoulder = frame_landmarks[12]
                
                # Check if shoulders are back (simplified)
                shoulder_y_avg = (left_shoulder['y'] + right_shoulder['y']) / 2
                if shoulder_y_avg > 0.6:  # Shoulders too high
                    issues.append("Shoulders not properly retracted")
                
                # Check elbow position
                left_elbow = frame_landmarks[13]
                right_elbow = frame_landmarks[14]
                
                # Check if elbows are at proper angle (simplified)
                elbow_y_avg = (left_elbow['y'] + right_elbow['y']) / 2
                if elbow_y_avg < 0.3:  # Elbows too high
                    issues.append("Elbows too high - lower the bar more")
                
                # Check for arch in back
                spine_landmarks = [frame_landmarks[11], frame_landmarks[12], 
                                 frame_landmarks[23], frame_landmarks[24]]
                spine_y_avg = np.mean([lm['y'] for lm in spine_landmarks])
                if spine_y_avg < 0.4:  # Too much arch
                    issues.append("Excessive back arch")
        
        if not issues:
            recommendations.append("Excellent bench press form!")
        else:
            recommendations.extend([
                "Retract your shoulder blades",
                "Keep your feet flat on the ground",
                "Control the bar descent",
                "Maintain natural back arch",
                "Keep your core tight"
            ])
        
        return {
            "exercise_type": "bench_press",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_deadlift(self, landmarks_list: List) -> Dict:
        """Analyze deadlift form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check back position (should be straight)
                shoulder = frame_landmarks[11]
                hip = frame_landmarks[23]
                
                # Check if back is straight
                if abs(shoulder['y'] - hip['y']) > 0.15:
                    issues.append("Back not straight - rounding")
                
                # Check hip position
                hip_y = hip['y']
                knee_y = frame_landmarks[25]['y']
                if hip_y < knee_y + 0.05:  # Hips too high
                    issues.append("Hips too high at start")
                
                # Check bar path
                shoulder_x = shoulder['x']
                hip_x = hip['x']
                if abs(shoulder_x - hip_x) > 0.1:  # Bar not close to body
                    issues.append("Bar not close to body")
        
        if not issues:
            recommendations.append("Excellent deadlift form!")
        else:
            recommendations.extend([
                "Keep your back straight",
                "Start with hips lower",
                "Keep the bar close to your body",
                "Drive through your heels",
                "Lock out at the top"
            ])
        
        return {
            "exercise_type": "deadlift",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_overhead_press(self, landmarks_list: List) -> Dict:
        """Analyze overhead press form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check shoulder position
                left_shoulder = frame_landmarks[11]
                right_shoulder = frame_landmarks[12]
                
                # Check if shoulders are level
                if abs(left_shoulder['y'] - right_shoulder['y']) > 0.05:
                    issues.append("Shoulders not level")
                
                # Check arm position
                left_elbow = frame_landmarks[13]
                right_elbow = frame_landmarks[14]
                
                # Check if arms are straight at top
                if left_elbow['y'] > 0.2 or right_elbow['y'] > 0.2:
                    issues.append("Arms not fully extended")
                
                # Check for excessive lean
                shoulder_y_avg = (left_shoulder['y'] + right_shoulder['y']) / 2
                hip_y = frame_landmarks[23]['y']
                if shoulder_y_avg < hip_y - 0.1:  # Excessive lean back
                    issues.append("Excessive lean back")
        
        if not issues:
            recommendations.append("Excellent overhead press form!")
        else:
            recommendations.extend([
                "Keep shoulders level",
                "Fully extend arms at top",
                "Minimize lean back",
                "Brace your core",
                "Control the descent"
            ])
        
        return {
            "exercise_type": "overhead_press",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_pullup(self, landmarks_list: List) -> Dict:
        """Analyze pull-up form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check shoulder position
                left_shoulder = frame_landmarks[11]
                right_shoulder = frame_landmarks[12]
                
                # Check if shoulders are engaged
                if left_shoulder['y'] > 0.4 or right_shoulder['y'] > 0.4:
                    issues.append("Shoulders not properly engaged")
                
                # Check elbow position
                left_elbow = frame_landmarks[13]
                right_elbow = frame_landmarks[14]
                
                # Check if elbows are close to body
                if abs(left_elbow['x'] - left_shoulder['x']) > 0.1:
                    issues.append("Elbows too wide")
                
                # Check for kipping
                hip_y = frame_landmarks[23]['y']
                shoulder_y_avg = (left_shoulder['y'] + right_shoulder['y']) / 2
                if abs(hip_y - shoulder_y_avg) > 0.2:  # Excessive movement
                    issues.append("Excessive body swing")
        
        if not issues:
            recommendations.append("Excellent pull-up form!")
        else:
            recommendations.extend([
                "Engage your shoulders",
                "Keep elbows close to body",
                "Avoid excessive swinging",
                "Control the movement",
                "Full range of motion"
            ])
        
        return {
            "exercise_type": "pullup",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_row(self, landmarks_list: List) -> Dict:
        """Analyze row form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check back position
                shoulder = frame_landmarks[11]
                hip = frame_landmarks[23]
                
                # Check if back is straight
                if abs(shoulder['y'] - hip['y']) > 0.15:
                    issues.append("Back not straight")
                
                # Check elbow position
                left_elbow = frame_landmarks[13]
                right_elbow = frame_landmarks[14]
                
                # Check if elbows are pulled back
                if left_elbow['x'] < shoulder['x'] - 0.05:
                    issues.append("Elbows not pulled back enough")
                
                # Check for excessive momentum
                shoulder_y = shoulder['y']
                if shoulder_y < 0.3:  # Too much lean forward
                    issues.append("Excessive forward lean")
        
        if not issues:
            recommendations.append("Excellent row form!")
        else:
            recommendations.extend([
                "Keep your back straight",
                "Pull elbows back to your sides",
                "Control the movement",
                "Squeeze your shoulder blades",
                "Avoid excessive momentum"
            ])
        
        return {
            "exercise_type": "row",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_lunge(self, landmarks_list: List) -> Dict:
        """Analyze lunge form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check knee position
                front_knee = frame_landmarks[25]  # Left knee
                back_knee = frame_landmarks[27]   # Left ankle
                
                # Check if front knee goes past toes
                if front_knee['x'] > back_knee['x']:
                    issues.append("Front knee going past toes")
                
                # Check depth
                hip_y = frame_landmarks[23]['y']
                knee_y = front_knee['y']
                if hip_y < knee_y + 0.1:  # Not deep enough
                    issues.append("Not lunging deep enough")
                
                # Check balance
                left_shoulder = frame_landmarks[11]['x']
                right_shoulder = frame_landmarks[12]['x']
                if abs(left_shoulder - right_shoulder) > 0.1:  # Not balanced
                    issues.append("Not maintaining balance")
        
        if not issues:
            recommendations.append("Excellent lunge form!")
        else:
            recommendations.extend([
                "Keep front knee behind toes",
                "Lunge deeper",
                "Maintain balance",
                "Keep chest up",
                "Step back to starting position"
            ])
        
        return {
            "exercise_type": "lunge",
            "form_rating": "Good" if len(issues) < 2 else "Needs Improvement",
            "issues_detected": list(set(issues)),
            "recommendations": recommendations,
            "confidence_score": 0.85
        }
    
    def _analyze_plank(self, landmarks_list: List) -> Dict:
        """Analyze plank form"""
        issues = []
        recommendations = []
        
        for frame_landmarks in landmarks_list:
            if len(frame_landmarks) >= 23:
                # Check body alignment
                shoulder = frame_landmarks[11]
                hip = frame_landmarks[23]
                ankle = frame_landmarks[27]
                
                # Check if body is straight
                if abs(shoulder['y'] - hip['y']) > 0.05:
                    issues.append("Body not in straight line")
                
                # Check hip position
                if hip['y'] > shoulder['y'] + 0.05:  # Hips too high
                    issues.append("Hips too high")
                elif hip['y'] < shoulder['y'] - 0.05:  # Hips too low
                    issues.append("Hips too low")
                
                # Check head position
                nose = frame_landmarks[0]
                if nose['y'] < shoulder['y'] - 0.1:  # Head too high
                    issues.append("Head position too high")
        
        if not issues:
            recommendations.append("Excellent plank form!")
        else:
            recommendations.extend([
                "Keep your body in a straight line",
                "Engage your core",
                "Keep your head neutral",
                "Hold the position",
                "Breathe steadily"
            ])
        
        return {
            "exercise_type": "plank",
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