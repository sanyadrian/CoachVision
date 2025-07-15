from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
import os

from database import create_db_and_tables
from routers import auth, user, planner, video

app = FastAPI(
    title="CoachVision API",
    description="AI Sports Coaching App Backend",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables on startup
@app.on_event("startup")
async def startup_event():
    create_db_and_tables()

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["authentication"])
app.include_router(user.router, prefix="/users", tags=["users"])
app.include_router(planner.router, prefix="/plans", tags=["training plans"])
app.include_router(video.router, prefix="/videos", tags=["video analysis"])

@app.get("/")
async def root():
    return {"message": "Welcome to CoachVision API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/test")
async def test_endpoint():
    return {"message": "API is working!"} 