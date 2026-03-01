from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import parser_classes
from .serializers import ResumeUploadSerializer

from .models import Student, Company, Application
from .serializers import StudentSerializer
from .serializers import MyApplicationSerializer
from .serializers import ProfileSerializer


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
            "is_applied": applied
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

        # NEW FIELDS
        "is_eligible": eligible,
        "eligibility_reason": reason
    })


# ================= ADD STUDENT =================
@api_view(['POST'])
def add_student(request):
    serializer = StudentSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)


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