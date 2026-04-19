from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


# ================= STUDENT =================
class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    roll_no = models.CharField(max_length=20)
    branch = models.CharField(max_length=50)
    cgpa = models.FloatField()
    skills = models.TextField()
    
    phone = models.CharField(max_length=20, null=True, blank=True)
    linkedin = models.URLField(max_length=200, null=True, blank=True)
    github = models.URLField(max_length=200, null=True, blank=True)

    resume = models.FileField(upload_to='resumes/', null=True, blank=True)

    def __str__(self):
        return self.name

    # helper: return list of skills
    def skill_list(self):
        return [s.strip().lower() for s in self.skills.split(',')]


# ================= COMPANY =================
class Company(models.Model):

    TYPE_CHOICES = [
        ('product', 'Product'),
        ('service', 'Service'),
        ('startup', 'Startup'),
    ]

    name = models.CharField(max_length=100)
    role = models.CharField(max_length=100)

    package = models.CharField(max_length=50)
    location = models.CharField(max_length=100)

    type = models.CharField(max_length=20, choices=TYPE_CHOICES)

    eligible_branch = models.CharField(max_length=50)
    min_cgpa = models.FloatField()

    required_skills = models.TextField()
    description = models.TextField()
    deadline = models.DateField()

    logo_url = models.URLField(max_length=500, null=True, blank=True)
    job_type = models.CharField(max_length=50, default='Full-Time')
    work_mode = models.CharField(max_length=50, default='On-Site')
    experience = models.CharField(max_length=50, default='Fresher')
    about_company = models.TextField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    posted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    # helper: required skills list
    def required_skill_list(self):
        return [s.strip().lower() for s in self.required_skills.split(',')]

    # helper: check deadline active
    def is_open(self):
        return self.deadline >= timezone.now().date()


# ================= APPLICATION =================
class Application(models.Model):

    STATUS_CHOICES = [
        ('applied', 'Applied'),
        ('shortlisted', 'Shortlisted'),
        ('interview', 'Interview'),
        ('selected', 'Selected'),
        ('rejected', 'Rejected'),
    ]

    student = models.ForeignKey(User, on_delete=models.CASCADE)
    company = models.ForeignKey(Company, on_delete=models.CASCADE)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='applied')

    applied_at = models.DateField(auto_now_add=True)
    shortlisted_at = models.DateField(null=True, blank=True)
    interview_at = models.DateField(null=True, blank=True)
    result_at = models.DateField(null=True, blank=True)

    # prevent duplicate apply
    class Meta:
        unique_together = ['student', 'company']

    def __str__(self):
        return f"{self.student.username} - {self.company.name} - {self.status}"


# ================= SAVED JOB =================
class SavedJob(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    company = models.ForeignKey(Company, on_delete=models.CASCADE)
    saved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'company']

    def __str__(self):
        return f"{self.user.username} saved {self.company.name}"


# ================= NOTIFICATION =================
class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.CharField(max_length=300)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username}: {self.message}"


# ================= PASSWORD RESET OTP =================
class PasswordResetOTP(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.otp}"