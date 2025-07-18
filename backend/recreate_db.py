import os
from database import engine
from models import SQLModel

def recreate_database():
    """Recreate the database with updated schema"""
    if os.path.exists("coachvision.db"):
        os.remove("coachvision.db")
        print("Removed existing database file")
    
    SQLModel.metadata.create_all(engine)
    print("Created new database with updated schema")

if __name__ == "__main__":
    recreate_database() 