from django.contrib import admin
from django.urls import path
from placement import views
from django.conf import settings
from django.conf.urls.static import static

# JWT views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),

    # ---------------- JWT AUTH ----------------
    path('api/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
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
    path("api/update-profile/", views.update_profile),
    path('api/dashboard/', views.dashboard_data),
    path('api/upload-resume/', views.upload_resume),
]
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)