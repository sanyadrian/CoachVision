from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import Optional
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from pydantic import BaseModel
import os
from datetime import datetime

from database import get_session
from models import UserProfile
from routers.auth import verify_token

router = APIRouter(tags=["support"])

class SupportRequest(BaseModel):
    category: str
    subject: str
    message: str
    userName: str
    userEmail: str

class SupportResponse(BaseModel):
    success: bool
    message: str

@router.post("/submit", response_model=SupportResponse)
async def submit_support_request(
    request: SupportRequest,
    session: Session = Depends(get_session),
    current_user: UserProfile = Depends(verify_token)
):
    """Submit a support request and send email notification"""
    
    try:
        # Create email content
        email_content = f"""
New Support Request from CoachVision

Category: {request.category}
Subject: {request.subject}
Message: {request.message}

User Information:
- Name: {request.userName}
- Email: {request.userEmail}
- User ID: {current_user.id}

Submitted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

---
This is an automated message from CoachVision Support System.
        """
        
        # Send email (you'll need to configure your email settings)
        success = send_support_email(
            subject=f"CoachVision Support: {request.subject}",
            content=email_content,
            user_email=request.userEmail,
            user_name=request.userName
        )
        
        if success:
            return SupportResponse(
                success=True,
                message="Support request submitted successfully"
            )
        else:
            return SupportResponse(
                success=False,
                message="Failed to send support request"
            )
            
    except Exception as e:
        print(f"Error submitting support request: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

def send_support_email(subject: str, content: str, user_email: str, user_name: str) -> bool:
    """Send support request email to admin"""
    
    # Email configuration - you'll need to set these environment variables
    admin_email = os.getenv("ADMIN_EMAIL", "your-email@example.com")  # Your email address
    smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_username = os.getenv("SMTP_USERNAME", "your-email@gmail.com")
    smtp_password = os.getenv("SMTP_PASSWORD", "your-app-password")
    
    try:
        # Create message
        msg = MIMEMultipart()
        msg['From'] = smtp_username
        msg['To'] = admin_email
        msg['Subject'] = subject
        
        # Add body to email
        msg.attach(MIMEText(content, 'plain'))
        
        # Create SMTP session
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        
        # Login to the server
        server.login(smtp_username, smtp_password)
        
        # Send email
        text = msg.as_string()
        server.sendmail(smtp_username, admin_email, text)
        
        # Close the connection
        server.quit()
        
        print(f"Support email sent successfully to {admin_email}")
        return True
        
    except Exception as e:
        print(f"Error sending support email: {e}")
        return False 