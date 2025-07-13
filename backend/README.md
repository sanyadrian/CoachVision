# CoachVision Backend

FastAPI backend for the CoachVision AI Sports Coaching App.

## Features

- **User Management**: Create, read, update, and delete user profiles
- **AI Training Plans**: Generate personalized training and diet plans using OpenAI
- **Video Analysis**: Upload and analyze exercise videos (basic analysis with placeholder for pose estimation)
- **SQLite Database**: Local database with SQLModel ORM

## Setup

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Environment setup**:
   ```bash
   cp env.example .env
   # Edit .env and add your OpenAI API key
   ```

3. **Run the server**:
   ```bash
   cd backend
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Access the API**:
   - API: http://localhost:8000
   - Interactive docs: http://localhost:8000/docs
   - Alternative docs: http://localhost:8000/redoc

## API Endpoints

### User Management (`/user`)

- `POST /user/` - Create user profile
- `GET /user/{user_id}` - Get user profile
- `GET /user/` - Get all users
- `PUT /user/{user_id}` - Update user profile
- `DELETE /user/{user_id}` - Delete user profile

### Training Plans (`/planner`)

- `POST /planner/generate` - Generate personalized training plan
- `GET /planner/user/{user_id}` - Get user's training plans
- `GET /planner/{plan_id}` - Get specific training plan
- `DELETE /planner/{plan_id}` - Delete training plan

### Video Analysis (`/video`)

- `POST /video/analyze` - Upload and analyze video
- `GET /video/user/{user_id}` - Get user's video analyses
- `GET /video/{analysis_id}` - Get specific video analysis
- `DELETE /video/{analysis_id}` - Delete video analysis

## Database Models

- **UserProfile**: User information and fitness goals
- **TrainingPlan**: Generated training plans linked to users
- **VideoAnalysis**: Video uploads and analysis results

## Environment Variables

- `OPENAI_API_KEY`: Required for training plan generation
- `DATABASE_URL`: Database connection string (defaults to SQLite)
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 8000)
- `DEBUG`: Debug mode (default: true)

## Development

The backend uses:
- **FastAPI**: Modern web framework
- **SQLModel**: SQL database ORM
- **OpenAI**: AI-powered training plan generation
- **SQLite**: Local database (can be changed to PostgreSQL)

## Next Steps

1. Implement actual pose estimation using Mediapipe or OpenPose
2. Add authentication and user sessions
3. Implement real-time video processing
4. Add progress tracking and analytics
5. Deploy to Render or Railway 