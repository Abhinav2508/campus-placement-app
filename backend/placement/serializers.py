from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import Student, Company
from placement.models import Application

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        data['is_staff'] = self.user.is_staff
        return data

class StudentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Student
        fields = '__all__'


class CompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = '__all__'

class MyApplicationSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(source="company.name")
    role = serializers.CharField(source="company.role")
    package = serializers.CharField(source="company.package")
    location = serializers.CharField(source="company.location")

    class Meta:
        model = Application
        fields = [
            "id",
            "company_name",
            "role",
            "package",
            "location",
            "status",
            "applied_at",
            "shortlisted_at",
            "interview_at",
            "result_at"
        ]

class AdminApplicationSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(source="company.name")
    student_name = serializers.CharField(source="student.student.name", allow_null=True, required=False)
    student_roll = serializers.CharField(source="student.student.roll_no", allow_null=True, required=False)
    student_phone = serializers.CharField(source="student.student.phone", allow_null=True, required=False)
    resume_url = serializers.FileField(source="student.student.resume", use_url=True, read_only=True)
    
    class Meta:
        model = Application
        fields = [
            "id",
            "student_name",
            "student_roll",
            "student_phone",
            "company_name",
            "status",
            "applied_at",
            "shortlisted_at",
            "interview_at",
            "result_at",
            "resume_url"
        ]

class ProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.first_name")
    email = serializers.EmailField(source="user.email", read_only=True)
    resume_url = serializers.FileField(source="resume", use_url=True, read_only=True)

    class Meta:
        model = Student
        fields = ["name", "roll_no", "branch", "cgpa", "skills", "phone", "linkedin", "github", "email", "resume_url"]

    def update(self, instance, validated_data):
        user_data = validated_data.pop("user", None)

        # update student fields
        instance.roll_no = validated_data.get("roll_no", instance.roll_no)
        instance.branch = validated_data.get("branch", instance.branch)
        instance.cgpa = validated_data.get("cgpa", instance.cgpa)
        instance.skills = validated_data.get("skills", instance.skills)
        instance.phone = validated_data.get("phone", instance.phone)
        instance.linkedin = validated_data.get("linkedin", instance.linkedin)
        instance.github = validated_data.get("github", instance.github)
        instance.save()

        # update user name (IMPORTANT PART)
        if user_data:
            instance.user.first_name = user_data.get("first_name", instance.user.first_name)
            instance.user.save()

        return instance
    
class ResumeUploadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Student
        fields = ['resume']