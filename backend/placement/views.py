from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.response import Response
from django.http import HttpResponse
from django.utils import timezone
from datetime import timedelta
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import parser_classes
from django.contrib.auth.models import User
from .serializers import ResumeUploadSerializer

from .models import Student, Company, Application, SavedJob, Notification, PasswordResetOTP
from .serializers import StudentSerializer, CompanySerializer
from .serializers import MyApplicationSerializer, AdminApplicationSerializer
from .serializers import ProfileSerializer

def index(request):
    return HttpResponse("<h1>Welcome to Campus Placement API</h1><p>The backend is running successfully. Please use the Flutter app to interact with the system.</p>")
from .serializers import CustomTokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


# ================= HELPER FUNCTION =================
def check_student_eligibility(student, company):

    # CGPA
    if student.cgpa < company.min_cgpa:
        return False, f"Required CGPA is {company.min_cgpa}"

    # Branch
    if student.branch.lower() != company.eligible_branch.lower():
        return False, "Branch not eligible"

    # Skills
    company_skills = company.required_skill_list()
    student_skills = student.skill_list()

    missing = [skill for skill in company_skills if skill not in student_skills]

    if missing:
        return False, f"Missing skills: {', '.join(missing)}"

    return True, "Eligible"


# ================= GET ALL STUDENTS =================
@api_view(['GET'])
def get_students(request):
    students = Student.objects.all()
    serializer = StudentSerializer(students, many=True)
    return Response(serializer.data)


# ================= GET ALL COMPANIES =================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_companies(request):

    companies = Company.objects.all()
    data = []

    for company in companies:
        applied = Application.objects.filter(
            student=request.user,
            company=company
        ).exists()

        data.append({
            "id": company.id,
            "name": company.name,
            "role": company.role,
            "package": company.package,
            "location": company.location,
            "type": company.type,
            "min_cgpa": company.min_cgpa,
            "deadline": company.deadline,
            "is_open": company.is_open(),
            "is_applied": applied,
            "logo_url": company.logo_url,
            "job_type": company.job_type,
            "work_mode": company.work_mode,
            "experience": company.experience,
            "posted_at": company.posted_at
        })

    return Response(data)


# ================= COMPANY DETAIL =================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def company_detail(request, company_id):

    try:
        student = Student.objects.get(user=request.user)
    except Student.DoesNotExist:
        return Response({"message": "Student profile not found"}, status=400)

    try:
        company = Company.objects.get(id=company_id)
    except Company.DoesNotExist:
        return Response({"message": "Company not found"}, status=404)

    applied = Application.objects.filter(
        student=request.user,
        company=company
    ).exists()

    # check eligibility
    eligible, reason = check_student_eligibility(student, company)

    return Response({
        "id": company.id,
        "name": company.name,
        "role": company.role,
        "package": company.package,
        "location": company.location,
        "type": company.type,
        "min_cgpa": company.min_cgpa,
        "deadline": company.deadline,
        "description": company.description,
        "required_skills": company.required_skills,
        "is_open": company.is_open(),
        "is_applied": applied,
        "logo_url": company.logo_url,
        "job_type": company.job_type,
        "work_mode": company.work_mode,
        "experience": company.experience,
        "about_company": company.about_company,
        "posted_at": company.posted_at,
        "is_eligible": eligible,
        "eligibility_reason": reason
    })


# ================= ADD STUDENT =================
@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdminUser])
def add_student(request):
    data = request.data
    username = data.get("username")
    password = data.get("password")
    
    if not username or not password:
        return Response({"error": "Username and password required."}, status=400)

    if User.objects.filter(username=username).exists():
        return Response({"error": "Username already exists."}, status=400)

    try:
        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=data.get("name", ""),
            email=data.get("email", "")
        )

        student = Student.objects.create(
            user=user,
            roll_no=data.get("roll_no", ""),
            branch=data.get("branch", ""),
            cgpa=data.get("cgpa", 0.0),
            phone=data.get("phone", "")
        )
        return Response({"message": "Student created successfully."}, status=201)
    except Exception as e:
        return Response({"error": str(e)}, status=400)


# ================= EDIT STUDENT =================
@api_view(['PUT'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_edit_student(request, student_id):
    try:
        student = Student.objects.get(id=student_id)
    except Student.DoesNotExist:
        return Response({"error": "Student not found"}, status=404)

    data = request.data

    # Update Student Model
    student.roll_no = data.get("roll_no", student.roll_no)
    student.branch = data.get("branch", student.branch)
    try:
        student.cgpa = float(data.get("cgpa", student.cgpa))
    except ValueError:
        pass
    student.phone = data.get("phone", student.phone)
    student.skills = data.get("skills", student.skills)
    student.linkedin = data.get("linkedin", student.linkedin)
    student.github = data.get("github", student.github)
    student.save()

    # Update User Model
    if "name" in data:
        student.user.first_name = data.get("name")
    if "email" in data:
        student.user.email = data.get("email")
    student.user.save()

    serializer = StudentSerializer(student)
    return Response(serializer.data, status=200)


# ================= CHECK ELIGIBILITY =================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def eligible_students(request, company_id):

    try:
        student = Student.objects.get(user=request.user)
    except Student.DoesNotExist:
        return Response({"eligible": False, "reason": "Student profile not found"})

    try:
        company = Company.objects.get(id=company_id)
    except Company.DoesNotExist:
        return Response({"eligible": False, "reason": "Company not found"})

    eligible, reason = check_student_eligibility(student, company)

    return Response({
        "eligible": eligible,
        "reason": reason
    })


# ================= APPLY COMPANY (SECURE) =================
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def apply_company(request, company_id):

    try:
        student = Student.objects.get(user=request.user)
    except Student.DoesNotExist:
        return Response({"message": "Student profile not found"}, status=400)

    try:
        company = Company.objects.get(id=company_id)
    except Company.DoesNotExist:
        return Response({"message": "Company not found"}, status=404)

    if not company.is_open():
        return Response({"message": "Application deadline passed"}, status=400)

    if Application.objects.filter(student=request.user, company=company).exists():
        return Response({"message": "Already applied"}, status=400)

    # 🔐 RECHECK ELIGIBILITY HERE
    eligible, reason = check_student_eligibility(student, company)

    if not eligible:
        return Response({"message": f"Not eligible: {reason}"}, status=403)

    Application.objects.create(student=request.user, company=company)

    return Response({"message": "Applied successfully"}, status=201)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_applications(request):
    applications = Application.objects.filter(student=request.user).order_by("-applied_at")
    serializer = MyApplicationSerializer(applications, many=True)
    return Response(serializer.data)

# ================= Get My Profile =================
from .serializers import ProfileSerializer

# ================= Get My Profile =================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_profile(request):
    try:
        student = Student.objects.get(user=request.user)
        serializer = ProfileSerializer(student)
        return Response(serializer.data)

    except Student.DoesNotExist:
        return Response({"message": "Profile not found"}, status=404)
# ================= Update Profile =================
@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_profile(request):
    try:
        student = Student.objects.get(user=request.user)
    except Student.DoesNotExist:
        return Response({"error": "Student not found"}, status=404)

    # update name in auth user
    name = request.data.get("name")
    if name:
        request.user.first_name = name
        request.user.save()

    student.branch = request.data.get("branch", student.branch)
    student.cgpa = request.data.get("cgpa", student.cgpa)
    student.skills = request.data.get("skills", student.skills)
    student.phone = request.data.get("phone", student.phone)
    student.linkedin = request.data.get("linkedin", student.linkedin)
    student.github = request.data.get("github", student.github)

    student.save()

    return Response({"message": "Profile updated successfully"})


# ================= DASHBOARD DATA =================

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def dashboard_data(request):

    try:
        student = Student.objects.get(user=request.user)
    except Student.DoesNotExist:
        return Response({"error": "Student profile not found"}, status=404)

    # 1️ Eligible companies count
    companies = Company.objects.all()
    eligible_count = 0

    for company in companies:
        eligible, _ = check_student_eligibility(student, company)
        if eligible:
            eligible_count += 1

    # 2️ Applied count
    applied_count = Application.objects.filter(student=request.user).count()

    # 3️ Upcoming drives (deadline future me)
    upcoming_count = Company.objects.filter(deadline__gte=timezone.now()).count()

    # 4️ Recent activity (last 5 applications)
    recent_apps = Application.objects.filter(student=request.user).order_by("-applied_at")[:5]

    activity = []
    for app in recent_apps:
        activity.append({
            "company": app.company.name,
            "role": app.company.role,
            "status": app.status
        })

    return Response({
        "name": student.name,
        "cgpa": student.cgpa,
        "eligible_companies": eligible_count,
        "applied": applied_count,
        "upcoming": upcoming_count,
        "recent_activity": activity
    })

# ================= RESUME UPLOAD =================
@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def upload_resume(request):

    try:
        student = request.user.student
    except:
        return Response({"error": "Student profile not found"}, status=404)

    if 'resume' not in request.FILES:
        return Response({"error": "No file uploaded"}, status=400)

    serializer = ResumeUploadSerializer(
        student,
        data=request.data,
        partial=True
    )

    if serializer.is_valid():
        serializer.save()
        return Response({
            "message": "Resume uploaded successfully",
            "resume_url": request.build_absolute_uri(student.resume.url)
        })

    return Response(serializer.errors, status=400)


# ========================================================
# ================= ADMIN APIS ===========================
# ========================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_dashboard(request):
    total_companies = Company.objects.count()
    total_students = Student.objects.count()
    total_applications = Application.objects.count()

    recent_apps = Application.objects.all().order_by("-applied_at")[:5]
    activity = []
    for app in recent_apps:
        # Check if student profile exists to avoid crash
        student_name = "Unknown"
        if hasattr(app.student, 'student'):
            student_name = app.student.student.name

        activity.append({
            "student": student_name,
            "company": app.company.name,
            "status": app.status
        })

    return Response({
        "total_companies": total_companies,
        "total_students": total_students,
        "total_applications": total_applications,
        "recent_activity": activity
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_students(request):
    students = Student.objects.all()
    serializer = StudentSerializer(students, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_companies(request):
    companies = Company.objects.all()
    serializer = CompanySerializer(companies, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_applications(request):
    applications = Application.objects.all().order_by("-applied_at")
    serializer = AdminApplicationSerializer(applications, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_add_company(request):
    serializer = CompanySerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)

@api_view(['PUT'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_update_application_status(request, app_id):
    try:
        app = Application.objects.get(id=app_id)
    except Application.DoesNotExist:
        return Response({"error": "Application not found"}, status=404)
        
    new_status = request.data.get("status")
    if new_status in dict(Application.STATUS_CHOICES):
        app.status = new_status
        # Handle date updates automatically
        if new_status == 'shortlisted':
            app.shortlisted_at = timezone.now().date()
        elif new_status == 'interview':
            app.interview_at = timezone.now().date()
        elif new_status in ['selected', 'rejected']:
            app.result_at = timezone.now().date()

        app.save()

        # AUTO-CREATE NOTIFICATION
        status_label = new_status.capitalize()
        Notification.objects.create(
            user=app.student,
            message=f"Your application to {app.company.name} ({app.company.role}) has been {status_label}!"
        )

        return Response({"message": "Status updated successfully", "status": new_status})
    return Response({"error": "Invalid status"}, status=400)


# ================= SAVE / UNSAVE JOB =================
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def toggle_save_job(request, company_id):
    try:
        company = Company.objects.get(id=company_id)
    except Company.DoesNotExist:
        return Response({"error": "Company not found"}, status=404)

    saved = SavedJob.objects.filter(user=request.user, company=company)
    if saved.exists():
        saved.delete()
        return Response({"saved": False, "message": "Job unsaved"})
    else:
        SavedJob.objects.create(user=request.user, company=company)
        return Response({"saved": True, "message": "Job saved"})


# ================= GET SAVED JOBS =================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def saved_jobs(request):
    saves = SavedJob.objects.filter(user=request.user).select_related('company')
    data = []
    for s in saves:
        c = s.company
        applied = Application.objects.filter(student=request.user, company=c).exists()
        data.append({
            "id": c.id,
            "name": c.name,
            "role": c.role,
            "package": c.package,
            "location": c.location,
            "deadline": c.deadline,
            "logo_url": c.logo_url,
            "job_type": c.job_type,
            "work_mode": c.work_mode,
            "experience": c.experience,
            "is_applied": applied,
            "is_open": c.is_open(),
        })
    return Response(data)


# ================= NOTIFICATIONS =================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_notifications(request):
    notifications = Notification.objects.filter(user=request.user)[:20]
    data = [{
        "id": n.id,
        "message": n.message,
        "is_read": n.is_read,
        "created_at": n.created_at
    } for n in notifications]
    unread_count = Notification.objects.filter(user=request.user, is_read=False).count()
    return Response({"notifications": data, "unread_count": unread_count})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notifications_read(request):
    Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
    return Response({"message": "All notifications marked as read"})


# ================= ADMIN ANALYTICS =================
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdminUser])
def admin_analytics(request):
    total_students = Student.objects.count()
    placed = Application.objects.filter(status='selected').values('student').distinct().count()
    not_placed = total_students - placed

    company_apps = []
    for company in Company.objects.all():
        count = Application.objects.filter(company=company).count()
        company_apps.append({"company": company.name, "count": count})

    return Response({
        "placed": placed,
        "not_placed": not_placed,
        "company_applications": company_apps,
    })


# ================= FORGOT PASSWORD (OTP GENERATION) =================
import random
from django.utils import timezone
from datetime import timedelta
from django.core.mail import send_mail
from django.conf import settings

@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password(request):
    username = request.data.get("username")
    if not username:
        return Response({"error": "Username is required"}, status=400)
    
    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)

    # Generate a secure 6-digit OTP
    otp = str(random.randint(100000, 999999))

    # Delete any previous OTPs for this user
    PasswordResetOTP.objects.filter(user=user).delete()

    # Save new OTP
    PasswordResetOTP.objects.create(user=user, otp=otp)

    # Simulating email/SMS sending by logging to terminal
    print("\n" + "="*50)
    print(f"🔐 PASSWORD RESET OTP REQUESTED")
    print(f"User: {username} (Email: {user.email})")
    print(f"OTP : {otp}")
    print("="*50 + "\n")

    # ----- REAL EMAIL LOGIC -----
    if user.email:
        try:
            send_mail(
                subject='Campus Placement App - Password Reset',
                message=f'Hello {user.first_name},\n\nYou requested a password reset. Here is your 6-digit OTP code: {otp}\n\nThis code will expire in 15 minutes.\n\nIf you did not request this, please ignore this email.',
                from_email=getattr(settings, 'EMAIL_HOST_USER', 'noreply@campus.com'),
                recipient_list=[user.email],
                fail_silently=False, 
            )
        except Exception as e:
            print("\n❌ FAILED TO SEND REAL EMAIL:")
            print(e)
            print("="*50 + "\n")

    return Response({"message": "If the account exists, an OTP has been sent."})


# ================= RESET PASSWORD (OTP VERIFICATION) =================
@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    username = request.data.get("username")
    otp = request.data.get("otp")
    new_password = request.data.get("new_password")

    if not all([username, otp, new_password]):
        return Response({"error": "Missing fields"}, status=400)

    try:
        user = User.objects.get(username=username)
        otp_record = PasswordResetOTP.objects.get(user=user, otp=otp)
    except (User.DoesNotExist, PasswordResetOTP.DoesNotExist):
        return Response({"error": "Invalid OTP or User"}, status=400)

    # Check if OTP is expired (e.g., older than 15 minutes)
    if timezone.now() > otp_record.created_at + timedelta(minutes=15):
        otp_record.delete()
        return Response({"error": "OTP expired"}, status=400)

    # Valid OTP -> Update Password
    user.set_password(new_password)
    user.save()

    # Clean up OTP record
    otp_record.delete()

    return Response({"message": "Password updated successfully!"})

