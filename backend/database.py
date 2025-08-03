import os
from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy.orm import sessionmaker

# Database URL - read directly from environment
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./coachvision.db")

# Create engine
if DATABASE_URL.startswith("sqlite"):
    # SQLite configuration
    engine = create_engine(
        DATABASE_URL,
        echo=True,  # False in production
        connect_args={"check_same_thread": False}
    )
else:
    # PostgreSQL configuration
    engine = create_engine(
        DATABASE_URL,
        echo=True  # False in production
    )

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_db_and_tables():
    """Create database tables"""
    SQLModel.metadata.create_all(engine)

def get_session():
    """Dependency to get database session"""
    with SessionLocal() as session:
        yield session 