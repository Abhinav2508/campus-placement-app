from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Student, Company
from placement.models import Application

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


class ProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.first_name")

    class Meta:
        model = Student
        fields = ["name", "roll_no", "branch", "cgpa", "skills"]

    def update(self, instance, validated_data):
        user_data = validated_data.pop("user", None)

        # update student fields
        instance.roll_no = validated_data.get("roll_no", instance.roll_no)
        instance.branch = validated_data.get("branch", instance.branch)
        instance.cgpa = validated_data.get("cgpa", instance.cgpa)
        instance.skills = validated_data.get("skills", instance.skills)
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


class AdminUserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "is_staff",
            "is_superuser",
            "is_active",
            "password",
        ]

    def create(self, validated_data):
        password = validated_data.pop("password", None)
        user = User(**validated_data)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for key, value in validated_data.items():
            setattr(instance, key, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class AdminStudentSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = Student
        fields = [
            "id",
            "user",
            "user_username",
            "name",
            "roll_no",
            "branch",
            "cgpa",
            "skills",
            "resume",
        ]


class AdminCompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = "__all__"


class AdminApplicationSerializer(serializers.ModelSerializer):
    student_username = serializers.CharField(source="student.username", read_only=True)
    company_name = serializers.CharField(source="company.name", read_only=True)

    class Meta:
        model = Application
        fields = [
            "id",
            "student",
            "student_username",
            "company",
            "company_name",
            "status",
            "applied_at",
            "shortlisted_at",
            "interview_at",
            "result_at",
        ]