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
from .rec import RecommendationEngine

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
    
class UpdateProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        """Update user's username and email."""
        user = request.user

        # Validate and update the fields
        username = request.data.get("username")
        email = request.data.get("email")

        if username:
            user.username = username
        if email:
            user.email = email

        # Save the updated user
        user.save()

        # Return updated user data
        serializer = UserSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)

class UploadProfilePhotoView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Upload user's profile photo."""
        user_profile = UserProfile.objects.get(user=request.user)
        
        # Check if the file is present in the request
        if 'photo' not in request.FILES:
            return Response({"error": "No photo uploaded"}, status=status.HTTP_400_BAD_REQUEST)
        
        photo = request.FILES['photo']
        
        # Save the uploaded photo
        user_profile.profile_picture = photo
        user_profile.save()

        # Return updated user profile data
        serializer = UserProfileSerializer(user_profile)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
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

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def rate_resource(request):
    resource_id = request.query_params.get("resource_id", None)
    try:
        resource = Resource.objects.get(pk=resource_id)
    except Resource.DoesNotExist:
        return Response({'detail': 'Resource not found'}, status=404)

    rating_value = float(request.data.get('rating', 0))
    if rating_value < 1 or rating_value > 5:
        return Response({'detail': 'Rating must be between 1 and 5'}, status=400)

    rating_obj, created = ResourceRating.objects.update_or_create(
        user=request.user,
        resource=resource,
        defaults={'rating': rating_value}
    )

    resource.refresh_from_db()

    print(resource.title)

    print(resource.rating)

    # The signal to update average is handled in the model save

    return Response({
        'detail': 'Rating submitted successfully',
        'average_rating': resource.rating
    })

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_attempted_quizzes(request):
    user = request.user
    quizzes_attempted = UserQuizAttempt.objects.filter(user=user).count()
    print(quizzes_attempted)
    return Response({
        "message" : "Attempts fetched successfully",
        "quizzes_attempted" : quizzes_attempted
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_statistics(request):
    """Get user statistics"""
    try:
        stats = UserStatistics.objects.get(user=request.user)
    except UserStatistics.DoesNotExist:
        stats = UserStatistics.objects.create(user=request.user)
    
    # Update statistics before returning
    stats.update_statistics()
    
    serializer = UserStatisticsSerializer(stats)
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_quiz_timing_data(request):
    """Get quiz timing data for charts"""
    attempts = UserQuizAttempt.objects.filter(
        user=request.user,
        completed=True
    ).exclude(completed_at=None).order_by('started_at')
    
    data = []
    for attempt in attempts:
        # Calculate duration in minutes
        if attempt.completed_at and attempt.started_at:
            duration = (attempt.completed_at - attempt.started_at).total_seconds() / 60
            
            # Count questions in this quiz
            question_count = Question.objects.filter(quiz=attempt.quiz).count()
            
            # Count correct answers
            correct_answers = UserAnswer.objects.filter(
                attempt=attempt,
                is_correct=True
            ).count()
            
            data.append({
                'quiz_id': attempt.quiz.id,
                'quiz_title': attempt.quiz.__str__(),
                'date': attempt.completed_at.strftime('%Y-%m-%d'),
                'duration_minutes': round(duration, 2),
                'question_count': question_count,
                'correct_answers': correct_answers,
                'score': attempt.score
            })
    
    return Response(data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_subject_performance(request):
    """Get subject-wise performance data for charts"""
    attempts = UserQuizAttempt.objects.filter(
        user=request.user,
        completed=True
    )
    
    subject_data = {}
    
    for attempt in attempts:
        subject_id = attempt.quiz.subject_id
        subject_name = attempt.quiz.subject.name
        
        if subject_id not in subject_data:
            subject_data[subject_id] = {
                'subject_name': subject_name,
                'attempts': 0,
                'total_score': 0,
                'average_score': 0
            }
        0
        subject_data[subject_id]['attempts'] += 1
        subject_data[subject_id]['total_score'] += attempt.score
        subject_data[subject_id]['average_score'] = (
            float("{:.2f}".format(subject_data[subject_id]['total_score'] / subject_data[subject_id]['attempts']))
        )
    
    return Response(list(subject_data.values()))

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_stats_overview(request):
    user = request.user
    userStatistics = UserStatistics.objects.get(user=user)
    completion_rate = round((userStatistics.quizzes_attempted / Quiz.objects.count()) * 100, 2)
    accuracy = round(userStatistics.accuracy_rate, 2)
    return Response({
        "accuracy" : accuracy,
        "quizzes_taken" : userStatistics.quizzes_attempted,
        "completion_rate": completion_rate
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_profile_stats(request):
    user = request.user
    userStatistics = UserStatistics.objects.get(user=user)
    weakestSubject = Subject.objects.get(id=userStatistics.weakest_subject_id)
    return Response({
        "date_joined" : userStatistics.date_joined,
        "quizzes_attempted" : userStatistics.quizzes_attempted,
        "avg_score" : userStatistics.average_score,
        "weakest_subject" : weakestSubject
    })
