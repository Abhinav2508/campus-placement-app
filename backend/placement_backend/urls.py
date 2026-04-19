from django.contrib import admin
from django.urls import path
from placement import views
from django.conf import settings
from django.conf.urls.static import static

# JWT views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('', views.index), # Root
    path('admin/', admin.site.urls),

    # ---------------- JWT AUTH ----------------
    path('api/login/', views.CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # ---------------- YOUR APIs ----------------
    path('api/students/', views.get_students),
    path('api/companies/', views.get_companies),
    path('api/add-student/', views.add_student),
    path('api/company/<int:company_id>/', views.company_detail),
    path('api/eligible/<int:company_id>/', views.eligible_students),
    path('api/apply/<int:company_id>/', views.apply_company),
    path('api/my-applications/', views.my_applications),
    path('api/profile/', views.my_profile),
    path('api/update-profile/', views.update_profile),
    path('api/dashboard/', views.dashboard_data),
    path('api/upload-resume/', views.upload_resume),
    
    # ---------------- ADMIN APIs ----------------
    path('api/admin/dashboard/', views.admin_dashboard),
    path('api/admin/students/', views.admin_students),
    path('api/admin/student/<int:student_id>/edit/', views.admin_edit_student),
    path('api/admin/companies/', views.admin_companies),
    path('api/admin/applications/', views.admin_applications),
    path('api/admin/company/add/', views.admin_add_company),
    path('api/admin/application/<int:app_id>/status/', views.admin_update_application_status),
    path('api/admin/analytics/', views.admin_analytics),

    # ---------------- SAVED JOBS ----------------
    path('api/save/<int:company_id>/', views.toggle_save_job),
    path('api/saved/', views.saved_jobs),

    # ---------------- NOTIFICATIONS ----------------
    path('api/notifications/', views.get_notifications),
    path('api/notifications/read/', views.mark_notifications_read),

    # ---------------- PASSWORD RESET ----------------
    path('api/forgot-password/', views.forgot_password),
    path('api/reset-password/', views.reset_password),
]
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)