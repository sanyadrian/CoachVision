import os
from decouple import config

class Settings:
    # Database
    DATABASE_URL: str = config("DATABASE_URL", default="sqlite:///./coachvision.db")
    
    # JWT Authentication
    SECRET_KEY: str = config("SECRET_KEY", default="your-secret-key-here")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = config("ACCESS_TOKEN_EXPIRE_MINUTES", default=30, cast=int)
    
    # OpenAI
    OPENAI_API_KEY: str = config("OPENAI_API_KEY", default="")
    
    # Server
    HOST: str = config("HOST", default="0.0.0.0")
    PORT: int = config("PORT", default=8000, cast=int)
    DEBUG: bool = config("DEBUG", default=True, cast=bool)
    
    # File uploads
    UPLOAD_DIR: str = config("UPLOAD_DIR", default="uploads")
    MAX_FILE_SIZE: int = config("MAX_FILE_SIZE", default=100 * 1024 * 1024, cast=int)  # 100MB

settings = Settings() 