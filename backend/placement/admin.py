from django.contrib import admin
from .models import Student, Company, Application


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['user', 'name', 'roll_no', 'branch', 'cgpa', 'resume']


@admin.register(Company)
class CompanyAdmin(admin.ModelAdmin):
    list_display = ['name', 'role', 'eligible_branch', 'min_cgpa', 'deadline']


@admin.register(Application)
class ApplicationAdmin(admin.ModelAdmin):
    list_display = ['student', 'company', 'status', 'applied_at']