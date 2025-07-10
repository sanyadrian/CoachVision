from fastapi import FastAPI

app = FastAPI(
    title="CoachVision API",
    description="AI Sports Coaching App Backend",
    version="1.0.0"
)

@app.get("/")
async def root():
    return {"message": "Welcome to CoachVision API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/test")
async def test_endpoint():
    return {"message": "API is working!"} 