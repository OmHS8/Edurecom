from rest_framework import serializers
from .models import *
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email')

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'first_name', 'last_name')
    
    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

class OptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Option
        fields = ('id', 'text')
        # Exclude is_correct to prevent cheating

class QuestionSerializer(serializers.ModelSerializer):
    options = OptionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Question
        fields = ('id', 'text', 'image', 'options')

class QuizSerializer(serializers.ModelSerializer):
    full_title = serializers.SerializerMethodField()

    class Meta:
        model = Quiz
        fields = ('id', 'title', 'full_title', 'description', 'subject')

    def get_full_title(self, obj):
        return f"{obj.subject.name} - {obj.title}"

class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = ('id', 'name', 'description')

class AnswerSubmissionSerializer(serializers.Serializer):
    question_id = serializers.IntegerField()
    selected_option_id = serializers.IntegerField()

class QuizSubmissionSerializer(serializers.Serializer):
    quiz_id = serializers.IntegerField()
    answers = AnswerSubmissionSerializer(many=True)

class KeywordSerializer(serializers.ModelSerializer):
    class Meta:
        model = Keyword
        fields = ('id', 'text')

class ResourceSerializer(serializers.ModelSerializer):
    keywords = KeywordSerializer(many=True, read_only=True)
    average_rating = serializers.FloatField(source='rating', read_only=True)
    
    class Meta:
        model = Resource
        fields = ('id', 'title', 'description', 'url', 'resource_type', 'keywords', 'average_rating')

class UserRecommendationSerializer(serializers.ModelSerializer):
    resource = ResourceSerializer(read_only=True)
    
    class Meta:
        model = UserRecommendation
        fields = ('id', 'resource', 'relevance_score', 'created_at', 'viewed')


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ('bio', 'profile_picture')

class UserStatisticsSerializer(serializers.ModelSerializer):
    total_quizzes_available = serializers.SerializerMethodField()
    weakest_subject_name = serializers.SerializerMethodField()
    fastest_quiz_name = serializers.SerializerMethodField()
    slowest_quiz_name = serializers.SerializerMethodField()
    quiz_completion_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = UserStatistics
        fields = (
            'quizzes_attempted', 'quizzes_completed', 'total_quizzes_available',
            'accuracy_rate', 'average_score', 'date_joined', 'weakest_subject_name',
            'recommendations_received', 'average_completion_time',
            'fastest_quiz_completion', 'fastest_quiz_name',
            'slowest_quiz_completion', 'slowest_quiz_name',
            'quiz_completion_rate'
        )
    
    def get_total_quizzes_available(self, obj):
        return Quiz.objects.count()
    
    def get_weakest_subject_name(self, obj):
        if obj.weakest_subject_id:
            try:
                subject = Subject.objects.get(id=obj.weakest_subject_id)
                return subject.name
            except Subject.DoesNotExist:
                return None
        return None
    
    def get_fastest_quiz_name(self, obj):
        if not obj.fastest_quiz_completion:
            return None
        
        # Find the quiz with the closest completion time to the fastest time
        user_attempts = UserQuizAttempt.objects.filter(
            user=obj.user,
            completed=True
        ).exclude(completed_at=None)
        
        fastest_attempt = None
        for attempt in user_attempts:
            completion_time = attempt.completed_at - attempt.started_at
            if completion_time == obj.fastest_quiz_completion:
                fastest_attempt = attempt
                break
        
        if fastest_attempt:
            return fastest_attempt.quiz.title
        return None
    
    def get_slowest_quiz_name(self, obj):
        if not obj.slowest_quiz_completion:
            return None
        
        # Find the quiz with the closest completion time to the slowest time
        user_attempts = UserQuizAttempt.objects.filter(
            user=obj.user,
            completed=True
        ).exclude(completed_at=None)
        
        slowest_attempt = None
        for attempt in user_attempts:
            completion_time = attempt.completed_at - attempt.started_at
            if completion_time == obj.slowest_quiz_completion:
                slowest_attempt = attempt
                break
        
        if slowest_attempt:
            return slowest_attempt.quiz.title
        return None
    
    def get_quiz_completion_rate(self, obj):
        total_quizzes = Quiz.objects.count()
        if total_quizzes > 0:
            return (obj.quizzes_completed / total_quizzes) * 100
        return 0.0