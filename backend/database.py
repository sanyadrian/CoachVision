from sqlmodel import SQLModel, create_engine, Session
from sqlalchemy.orm import sessionmaker

# Database URL - using SQLite for development
DATABASE_URL = "sqlite:///./coachvision.db"

# Create engine
engine = create_engine(
    DATABASE_URL,
    echo=True,  # Set to False in production
    connect_args={"check_same_thread": False}  # Only needed for SQLite
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