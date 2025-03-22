from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'subjects', views.SubjectViewSet)
router.register(r'quizzes', views.QuizViewSet, basename='quiz')

urlpatterns = [
    path('', include(router.urls)),
    path('get-questions/', views.get_questions, name='get-questions'),
    path('submit-quiz/', views.submit_quiz, name='submit-quiz'),
    path('get-quizzes/', views.get_quizzes, name='get-quizzes'),
    path('get-recommendations/', views.get_recommendations, name='get-recommendations'),
    path('mark-recommendation-viewed/<int:recommendation_id>/', views.mark_recommendation_viewed, name='mark-recommendation-viewed'),
    path('register/', views.UserRegistrationView.as_view(), name='user-register'),
    path('profile/', views.UserProfileView.as_view(), name='user-profile'),
]