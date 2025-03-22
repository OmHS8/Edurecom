from rest_framework import viewsets, status, generics
from rest_framework.decorators import api_view, permission_classes
from django.http import JsonResponse
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny
from .models import *
from .serializers import *
from .recommendation import RecommendationEngine

class UserRegistrationView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "User registered successfully"},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SubjectViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Subject.objects.all()
    serializer_class = SubjectSerializer

class QuizViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = QuizSerializer
    
    def get_queryset(self):
        queryset = Quiz.objects.all()
        subject_id = self.request.query_params.get('subject_id', None)
        if subject_id is not None:
            queryset = queryset.filter(subject_id=subject_id)
        return queryset

class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_quizzes(request):
    """Get all quizzes along with their ids."""
    subject_id = request.query_params.get('subject_id', None)
    if subject_id is not None:
        subject = get_object_or_404(Subject, id=subject_id)
        quizzes = Quiz.objects.filter(subject=subject).all()
    else:
        quizzes = Quiz.objects.all()
    serializers = QuizSerializer(quizzes, many=True)
    return Response({
        "quizzes" : serializers.data
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_questions(request):
    """Get all questions for a quiz"""
    quiz_id = request.query_params.get('quiz_id', None)
    
    if not quiz_id:
        return Response(
            {"error": "Either quiz_id parameter is required"}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get the first quiz in the subject
    quiz = get_object_or_404(Quiz, id=quiz_id)
    questions = Question.objects.filter(quiz=quiz)

    # Create or get user attempt
    attempt, created = UserQuizAttempt.objects.get_or_create(
        user=request.user,
        quiz=quiz,
        defaults={'started_at': timezone.now()}
    )
    
    # If attempt already exists but is not completed, update started_at
    if not created and not attempt.completed:
        attempt.started_at = timezone.now()
        attempt.save()
    
    serializer = QuestionSerializer(questions, many=True)
    
    return Response({
        'quiz_id': quiz.id,
        'quiz_title': quiz.title,
        'attempt_id': attempt.id,
        'questions': serializer.data
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_quiz(request):
    """Submit quiz answers and get recommendations"""
    serializer = QuizSubmissionSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    quiz_id = serializer.validated_data['quiz_id']
    submitted_answers = serializer.validated_data['answers']
    
    quiz = get_object_or_404(Quiz, id=quiz_id)
    
    # Get all questions in the quiz
    all_questions = Question.objects.filter(quiz=quiz)
    total_questions = all_questions.count()
    
    # Get or create user attempt
    attempt, _ = UserQuizAttempt.objects.get_or_create(
        user=request.user,
        quiz=quiz,
        defaults={'started_at': timezone.now()}
    )
    
    # If attempt is already completed, return error
    if attempt.completed:
        return Response(
            {"error": "This quiz has already been completed"}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Clear previous answers if any
    UserAnswer.objects.filter(attempt=attempt).delete()
    
    # Process answers
    correct_answers = 0
    
    # Process all questions in the quiz
    for answer_data in submitted_answers:
        question_id = answer_data['question_id']
        selected_option_id = answer_data['selected_option_id']
        
        question = get_object_or_404(Question, id=question_id, quiz=quiz)
        
        # Check if this is an unanswered question (option_id = -1)
        if selected_option_id == -1:
            # Find an incorrect option to use
            incorrect_option = Option.objects.filter(question=question, is_correct=False).first()
            
            # If no incorrect option found, use any option
            if not incorrect_option:
                incorrect_option = Option.objects.filter(question=question).first()
            
            # Create answer record with is_correct explicitly set to false
            UserAnswer.objects.create(
                attempt=attempt,
                question=question,
                selected_option=incorrect_option,
                is_correct=False  # Explicitly mark as incorrect
            )
        else:
            # Normal case: user selected an option
            selected_option = get_object_or_404(Option, id=selected_option_id, question=question)
            is_correct = selected_option.is_correct
            
            # Count correct answers
            if is_correct:
                correct_answers += 1
            
            # Save user answer
            UserAnswer.objects.create(
                attempt=attempt,
                question=question,
                selected_option=selected_option,
                is_correct=is_correct
            )
    
    # Update attempt
    score_percentage = (correct_answers / total_questions) * 100 if total_questions > 0 else 0
    attempt.score = score_percentage
    attempt.completed = True
    attempt.completed_at = timezone.now()
    attempt.save()
    
    # Generate recommendations
    recommendation_engine = RecommendationEngine()
    recommendation_engine.generate_recommendations(request.user.id, attempt.id)
    
    # Get recommendations
    recommendations = UserRecommendation.objects.filter(
        user=request.user,
        quiz_attempt=attempt
    ).order_by('-relevance_score')
    
    recommendation_serializer = UserRecommendationSerializer(recommendations, many=True)
    
    return Response({
        'score': score_percentage,
        'correct_answers': correct_answers,
        'total_questions': total_questions,
        'completed_at': attempt.completed_at,
        'recommendations': recommendation_serializer.data
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_recommendations(request):
    """Get recommendations for a user"""
    quiz_attempt_id = request.query_params.get('quiz_attempt_id', None)
    
    if quiz_attempt_id:
        recommendations = UserRecommendation.objects.filter(
            user=request.user,
            quiz_attempt_id=quiz_attempt_id
        ).order_by('-relevance_score')
    else:
        # Get latest recommendations if no quiz_attempt_id specified
        recommendations = UserRecommendation.objects.filter(
            user=request.user
        ).order_by('-created_at')
    
    serializer = UserRecommendationSerializer(recommendations, many=True)
    
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_recommendation_viewed(request, recommendation_id):
    """Mark a recommendation as viewed"""
    recommendation = get_object_or_404(
        UserRecommendation, 
        id=recommendation_id,
        user=request.user
    )
    
    recommendation.viewed = True
    recommendation.save()
    
    return Response({'status': 'success'})