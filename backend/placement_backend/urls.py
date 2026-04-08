from django.contrib import admin
from django.urls import include, path
from placement import views
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter

# JWT views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

admin_router = DefaultRouter()
admin_router.register(r'users', views.AdminUserViewSet, basename='admin-users')
admin_router.register(r'students', views.AdminStudentViewSet, basename='admin-students')
admin_router.register(r'companies', views.AdminCompanyViewSet, basename='admin-companies')
admin_router.register(r'applications', views.AdminApplicationViewSet, basename='admin-applications')

urlpatterns = [
    path('', views.api_root),
    path('admin/', admin.site.urls),

    # ---------------- JWT AUTH ----------------
    path('api/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # ---------------- YOUR APIs ----------------
    path('api/students/', views.get_students),
    path('api/admin/check/', views.admin_check),
    path('api/admin/', include(admin_router.urls)),
    path('api/companies/', views.get_companies),
    path('api/add-student/', views.add_student),
    path('api/company/<int:company_id>/', views.company_detail),
    path('api/eligible/<int:company_id>/', views.eligible_students),
    path('api/apply/<int:company_id>/', views.apply_company),
    path('api/my-applications/', views.my_applications),
    path('api/profile/', views.my_profile),
    path("api/update-profile/", views.update_profile),
    path('api/dashboard/', views.dashboard_data),
    path('api/upload-resume/', views.upload_resume),
]
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)