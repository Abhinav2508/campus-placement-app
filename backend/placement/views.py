from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework import viewsets
from django.contrib.auth.models import User
from django.shortcuts import redirect
from django.utils import timezone
from datetime import timedelta
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import parser_classes
from .serializers import ResumeUploadSerializer

from .models import Student, Company, Application
from .serializers import StudentSerializer
from .serializers import MyApplicationSerializer
from .serializers import ProfileSerializer
from .serializers import AdminUserSerializer
from .serializers import AdminStudentSerializer
from .serializers import AdminCompanySerializer
from .serializers import AdminApplicationSerializer


# ================= ROOT LANDING =================
@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    return redirect('/admin/')


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


def get_or_create_student_profile(user):
    student, _ = Student.objects.get_or_create(
        user=user,
        defaults={
            "name": (user.first_name or user.username).strip(),
            "roll_no": "",
            "branch": "",
            "cgpa": 0.0,
            "skills": "",
        },
    )
    return student


# ================= GET ALL STUDENTS =================
@api_view(['GET'])
def get_students(request):
    students = Student.objects.all()
    serializer = StudentSerializer(students, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_students(request):
    students = Student.objects.all().order_by('name')
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
    student = get_or_create_student_profile(request.user)

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
    student = get_or_create_student_profile(request.user)

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
    student = get_or_create_student_profile(request.user)

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
    student = get_or_create_student_profile(request.user)
    serializer = ProfileSerializer(student)
    data = serializer.data
    data["resume_url"] = request.build_absolute_uri(student.resume.url) if student.resume else None
    data["is_admin"] = request.user.is_staff
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_check(request):
    return Response({"is_admin": request.user.is_staff})


class AdminUserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('id')
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminUser]


class AdminStudentViewSet(viewsets.ModelViewSet):
    queryset = Student.objects.select_related('user').all().order_by('name')
    serializer_class = AdminStudentSerializer
    permission_classes = [IsAdminUser]


class AdminCompanyViewSet(viewsets.ModelViewSet):
    queryset = Company.objects.all().order_by('name')
    serializer_class = AdminCompanySerializer
    permission_classes = [IsAdminUser]


class AdminApplicationViewSet(viewsets.ModelViewSet):
    queryset = Application.objects.select_related('student', 'company').all().order_by('-applied_at')
    serializer_class = AdminApplicationSerializer
    permission_classes = [IsAdminUser]
# ================= Update Profile =================
@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_profile(request):
    student = get_or_create_student_profile(request.user)

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
    student = get_or_create_student_profile(request.user)

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
    student = get_or_create_student_profile(request.user)

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