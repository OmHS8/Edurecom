# Create your models here.
from django.utils import timezone
from django.db import models
from django.contrib.auth.models import User
from django.db.models import Avg
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=User)
def create_user_statistics(sender, instance, created, **kwargs):
    if created:
        UserStatistics.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_statistics(sender, instance, **kwargs):
    if hasattr(instance, 'statistics'):
        instance.statistics.save()
    else:
        UserStatistics.objects.create(user=instance)

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    
    def __str__(self):
        return self.user.username

class Subject(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    
    def __str__(self):
        return self.name

class Quiz(models.Model):
    title = models.CharField(max_length=255)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE, related_name='quizzes')
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.subject} - {self.title}"

class Question(models.Model):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    text = models.TextField()
    image = models.ImageField(upload_to='question_images/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.text[:50]

class Option(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='options')
    text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)
    
    def __str__(self):
        return self.text

class UserQuizAttempt(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='quiz_attempts')
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='attempts')
    score = models.IntegerField(default=0)
    completed = models.BooleanField(default=False)
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ('user', 'quiz')
    
    def __str__(self):
        return f"{self.user.username} - {self.quiz.title}"

class UserAnswer(models.Model):
    attempt = models.ForeignKey(UserQuizAttempt, on_delete=models.CASCADE, related_name='answers')
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    selected_option = models.ForeignKey(Option, on_delete=models.CASCADE)
    is_correct = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.attempt.user.username} - {self.question.text[:30]}"

class Keyword(models.Model):
    text = models.CharField(max_length=100, unique=True)
    
    def __str__(self):
        return self.text

class ResourceType(models.Model):
    name = models.CharField(max_length=50)  # e.g., 'YouTube', 'PDF', 'PPT'
    
    def __str__(self):
        return self.name

class Resource(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    url = models.URLField()
    resource_type = models.ForeignKey(ResourceType, on_delete=models.CASCADE)
    keywords = models.ManyToManyField(Keyword, related_name='resources')
    rating = models.FloatField(default=0.0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.title
    
    def update_average_rating(self):
        avg_rating = self.ratings.aggregate(avg=Avg('rating'))['avg'] or 0.0
        self.rating = round(avg_rating, 2)
        self.save(update_fields=['rating'])


class UserRecommendation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recommendations')
    resource = models.ForeignKey(Resource, on_delete=models.CASCADE)
    quiz_attempt = models.ForeignKey(UserQuizAttempt, on_delete=models.CASCADE, related_name='recommendations')
    relevance_score = models.FloatField(default=0.0)
    created_at = models.DateTimeField(auto_now_add=True)
    viewed = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ('user', 'resource', 'quiz_attempt')
    
    def __str__(self):
        return f"{self.user.username} - {self.resource.title}"
    
class ResourceRating(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    resource = models.ForeignKey(Resource, on_delete=models.CASCADE, related_name='ratings')
    rating = models.FloatField(default=0.0)  # e.g., 1-5 scale
    rated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'resource')  # Ensures one rating per user per resource

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self.resource.update_average_rating()

class UserStatistics(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='statistics')
    date_joined = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    
    # Derived fields that can be updated periodically
    quizzes_attempted = models.IntegerField(default=0)
    quizzes_completed = models.IntegerField(default=0)
    total_questions_attempted = models.IntegerField(default=0)
    total_questions_correct = models.IntegerField(default=0)
    accuracy_rate = models.FloatField(default=0.0)  # Percentage
    average_score = models.FloatField(default=0.0)  # Average quiz score
    average_completion_time = models.DurationField(null=True, blank=True)  # Average time to complete a quiz
    fastest_quiz_completion = models.DurationField(null=True, blank=True)  # Fastest quiz completion time
    slowest_quiz_completion = models.DurationField(null=True, blank=True)  # Slowest quiz completion time
    weakest_subject_id = models.IntegerField(null=True, blank=True)  # ID of the subject with lowest average score
    recommendations_received = models.IntegerField(default=0)  # Total recommendations received
    
    def __str__(self):
        return f"Statistics for {self.user.username}"
    
    def update_statistics(self):
        """Update all statistics for the user"""
        # Get all completed quiz attempts
        completed_attempts = UserQuizAttempt.objects.filter(
            user=self.user,
            completed=True
        )
        
        # Basic counts
        self.quizzes_attempted = UserQuizAttempt.objects.filter(user=self.user).count()
        self.quizzes_completed = completed_attempts.count()
        
        # Get total questions data
        user_answers = UserAnswer.objects.filter(attempt__user=self.user)
        self.total_questions_attempted = user_answers.count()
        self.total_questions_correct = user_answers.filter(is_correct=True).count()
        
        # Calculate accuracy rate
        if self.total_questions_attempted > 0:
            self.accuracy_rate = (self.total_questions_correct / self.total_questions_attempted) * 100
        
        # Calculate average score
        if self.quizzes_completed > 0:
            self.average_score = completed_attempts.aggregate(avg_score=Avg('score'))['avg_score'] or 0.0
        
        # Time-based statistics
        if self.quizzes_completed > 0:
            # Filter attempts with valid start and end times
            valid_attempts = completed_attempts.exclude(completed_at=None)
            
            if valid_attempts.exists():
                # Calculate time differences
                completion_times = []
                for attempt in valid_attempts:
                    if attempt.started_at and attempt.completed_at:
                        completion_time = attempt.completed_at - attempt.started_at
                        completion_times.append(completion_time)
                
                if completion_times:
                    # Average completion time
                    total_seconds = sum(ct.total_seconds() for ct in completion_times)
                    avg_seconds = total_seconds / len(completion_times)
                    self.average_completion_time = timezone.timedelta(seconds=avg_seconds)
                    
                    # Fastest and slowest
                    self.fastest_quiz_completion = min(completion_times)
                    self.slowest_quiz_completion = max(completion_times)
        
        # Find weakest subject
        subject_scores = {}
        for attempt in completed_attempts:
            subject_id = attempt.quiz.subject_id
            if subject_id not in subject_scores:
                subject_scores[subject_id] = []
            subject_scores[subject_id].append(attempt.score)
        
        if subject_scores:
            # Calculate average score per subject
            subject_avg_scores = {
                subj_id: sum(scores) / len(scores) 
                for subj_id, scores in subject_scores.items()
            }
            
            # Find subject with lowest average
            self.weakest_subject_id = min(subject_avg_scores, key=subject_avg_scores.get)
        
        # Count recommendations
        self.recommendations_received = UserRecommendation.objects.filter(user=self.user).count()
        
        self.save()