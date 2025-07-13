# CoachVision - AI Sports Coaching App

CoachVision is an AI-powered sports coaching application that helps users improve their fitness and technique using personalized training plans and video analysis.

## 🏗️ Architecture

- **Frontend**: SwiftUI iOS app
- **Backend**: FastAPI with Python
- **Database**: SQLite (development) / PostgreSQL (production)
- **AI**: OpenAI GPT for training plan generation
- **Video Analysis**: Basic analysis with placeholder for Mediapipe/OpenPose

## 🚀 Quick Start

### Backend Setup

1. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment**:
   ```bash
   cd backend
   cp env.example .env
   # Edit .env and add your OpenAI API key
   ```

3. **Start the backend server**:
   ```bash
   cd backend
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Test the API**:
   ```bash
   python test_api.py
   ```

### Frontend Setup (Coming Soon)

The SwiftUI frontend will be developed in the next phase.

## 📋 Features

### ✅ Backend (Completed)

- **User Management**: CRUD operations for user profiles
- **AI Training Plans**: Personalized training and diet plans using OpenAI
- **Video Analysis**: Upload and analyze exercise videos
- **RESTful API**: FastAPI with automatic documentation
- **Database**: SQLModel ORM with SQLite

### 🚧 Frontend (Planned)

- **User Profile Creation**: Input personal and fitness data
- **Training Plan Display**: View personalized weekly plans
- **Video Upload**: Record and upload exercise videos
- **Progress Tracking**: Monitor fitness progress
- **Daily Reminders**: Stay on track with notifications

## 🔧 API Endpoints

### User Management
- `POST /user/` - Create user profile
- `GET /user/{user_id}` - Get user profile
- `PUT /user/{user_id}` - Update user profile
- `DELETE /user/{user_id}` - Delete user profile

### Training Plans
- `POST /planner/generate` - Generate personalized plan
- `GET /planner/user/{user_id}` - Get user's plans
- `GET /planner/{plan_id}` - Get specific plan

### Video Analysis
- `POST /video/analyze` - Upload and analyze video
- `GET /video/user/{user_id}` - Get user's analyses
- `GET /video/{analysis_id}` - Get specific analysis

## 🛠️ Tech Stack

### Backend
- **FastAPI**: Modern Python web framework
- **SQLModel**: SQL database ORM
- **OpenAI**: AI-powered training plan generation
- **SQLite**: Local database (PostgreSQL for production)
- **Uvicorn**: ASGI server

### Frontend (Planned)
- **SwiftUI**: Modern iOS UI framework
- **URLSession**: HTTP networking
- **@AppStorage**: Local data persistence
- **VideoPicker**: Video capture and upload

## 📁 Project Structure

```
CoachVision/
├── backend/
│   ├── main.py              # FastAPI application
│   ├── database.py          # Database configuration
│   ├── models.py            # SQLModel models
│   ├── config.py            # Settings and configuration
│   ├── routers/
│   │   ├── user.py         # User management endpoints
│   │   ├── planner.py      # Training plan endpoints
│   │   └── video.py        # Video analysis endpoints
│   ├── uploads/            # Video file storage
│   ├── requirements.txt    # Python dependencies
│   ├── env.example        # Environment variables template
│   ├── test_api.py        # API testing script
│   └── README.md          # Backend documentation
├── frontend/              # SwiftUI app (coming soon)
├── requirements.txt       # Root dependencies
└── README.md             # This file
```

## 🔑 Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Required
OPENAI_API_KEY=your_openai_api_key_here

# Optional (defaults shown)
DATABASE_URL=sqlite:///./coachvision.db
HOST=0.0.0.0
PORT=8000
DEBUG=true
UPLOAD_DIR=uploads
MAX_FILE_SIZE=104857600
```

## 🧪 Testing

Run the test script to verify the API works:

```bash
cd backend
python test_api.py
```

## 📚 API Documentation

Once the server is running, visit:
- **Interactive Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc

## 🚀 Deployment

### Backend Deployment

The backend can be deployed to:
- **Render**: Easy deployment with PostgreSQL
- **Railway**: Simple deployment with database
- **Heroku**: Traditional deployment option

### Frontend Deployment

The iOS app will be distributed through:
- **App Store**: Public distribution
- **TestFlight**: Beta testing

## 🔮 Roadmap

### Phase 1: Backend Foundation ✅
- [x] FastAPI setup with CORS
- [x] Database models and migrations
- [x] User management endpoints
- [x] Basic video upload functionality
- [x] OpenAI integration for training plans

### Phase 2: Frontend Development 🚧
- [ ] SwiftUI project setup
- [ ] User profile creation views
- [ ] Training plan display
- [ ] Video upload functionality
- [ ] Local data persistence

### Phase 3: Advanced Features 📋
- [ ] Real-time pose estimation with Mediapipe
- [ ] Progress tracking and analytics
- [ ] Push notifications
- [ ] Social features and sharing
- [ ] Advanced video analysis

### Phase 4: Production Ready 🚀
- [ ] Authentication and security
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] App Store submission
- [ ] Production deployment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the API documentation at `/docs`
- Review the backend README for detailed setup instructions 