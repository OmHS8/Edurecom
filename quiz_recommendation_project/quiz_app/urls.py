from django.urls import path, include
from django.conf.urls.static import static
from django.conf import settings
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'subjects', views.SubjectViewSet)
router.register(r'quizzes', views.QuizViewSet, basename='quiz')

urlpatterns = [
    path('', include(router.urls)),
    path('get-questions/', views.get_questions, name='get-questions'),
    path('submit-quiz/', views.submit_quiz, name='submit-quiz'),
    path('get-subjects/', views.SubjectViewSet.as_view({'get' : 'list'}),  name='get-subjects'),
    path('get-quizzes/', views.get_quizzes, name='get-quizzes'),
    path('get-recommendations/', views.get_recommendations, name='get-recommendations'),
    path('mark-recommendation-viewed/<int:recommendation_id>/', views.mark_recommendation_viewed, name='mark-recommendation-viewed'),
    path('register/', views.UserRegistrationView.as_view(), name='user-register'),
    path('profile/', views.UserProfileView.as_view(), name='user-profile'),
    path('rate-resource/', views.rate_resource, name='rate-resource'),
    path('quizzes-attempted/', views.get_attempted_quizzes, name="quizzes-attempted"),
    path('updateprofile/', views.UpdateProfileView.as_view(), name="update-profile"),
    path('uploadphoto/', views.UploadProfilePhotoView.as_view(), name="upload-photo"),
    path('user/statistics/', views.get_user_statistics, name='user-statistics'),
    path('user/quiz-timing-data/', views.get_quiz_timing_data, name='quiz-timing-data'),
    path('user/subject-performance/', views.get_subject_performance, name='subject-performance'),
    path('user/stats-overview/', views.get_stats_overview, name='stats-overview'),
    path('profile-stats/', views.get_profile_stats, name='profile-stats')
]