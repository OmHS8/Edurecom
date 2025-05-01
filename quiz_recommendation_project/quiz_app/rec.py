import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from django.db.models import Count, Q, F
from .models import *
import logging
import re

logger = logging.getLogger(__name__)

class RecommendationEngine:
    def __init__(self):
        self.tfidf_vectorizer = TfidfVectorizer(
            stop_words='english',
            max_features=200,
            min_df=2,
            ngram_range=(1, 2)  # Include both unigrams and bigrams
        )
        
    def preprocess_text(self, text):
        """Clean and preprocess text"""
        if not text:
            return ""
        # Convert to lowercase
        text = text.lower()
        # Remove special characters but keep spaces between words
        text = re.sub(r'[^\w\s]', ' ', text)
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        return text
        
    def extract_keywords_from_questions_and_options(self, question_ids):
        """Extract keywords from questions and their options"""
        questions = Question.objects.filter(id__in=question_ids).prefetch_related('options')
        if not questions.exists():
            return []
        
        # Combine question texts with their options
        question_content = []
        
        for question in questions:
            # Start with the question text
            question_text = self.preprocess_text(question.text)
            
            # Add option texts (both correct and incorrect for better context)
            option_texts = " ".join([self.preprocess_text(option.text) for option in question.options.all()])
            
            # Combine question and options with more weight to the question
            combined_text = f"{question_text} {question_text} {option_texts}"
            question_content.append(combined_text)
        
        try:
            # Generate TF-IDF matrix
            tfidf_matrix = self.tfidf_vectorizer.fit_transform(question_content)
            feature_names = self.tfidf_vectorizer.get_feature_names_out()
            
            # Weight the terms by their TF-IDF values
            tfidf_sum = np.asarray(tfidf_matrix.sum(axis=0)).ravel()
            importance = np.argsort(tfidf_sum)[::-1]
            keywords = [feature_names[i] for i in importance]
            print(keywords)

            
            # Get top keywords (more keywords for better context)
            top_n = min(30, len(importance))  # Get up to 30 keywords
            top_keywords = [feature_names[i] for i in importance[:top_n]]
            
            return top_keywords
        except Exception as e:
            logger.error(f"Error extracting keywords: {e}")
            return []
    
    def content_based_recommendation(self, keywords, quiz_subject_id=None, limit=10):
        """Generate content-based recommendations using keywords with subject context"""
        if not keywords:
            return []
        
        # Get all resources, optionally filtered by quiz subject
        resource_query = Resource.objects.all()
        
        # If we have a subject, prioritize resources related to that subject
        # (We'll implement this through a relevance boost rather than filtering)
        
        # Create a list of resources with their keyword texts
        resource_keyword_texts = []
        resource_ids = []
        subject_relevance = []
        
        for resource in resource_query:
            # Get the resource keywords
            keyword_texts = [k.text for k in resource.keywords.all()]
            
            # Skip resources without keywords
            if not keyword_texts:
                continue
                
            # Add to our collection
            keyword_text = " ".join(self.preprocess_text(kt) for kt in keyword_texts)
            resource_keyword_texts.append(keyword_text)
            resource_ids.append(resource.id)
            
            # Track subject relevance (will be used to boost relevant resources)
            # This would be more effective with a Subject-Resource relation in the model
            subject_relevant = False
            if quiz_subject_id and any(kw.lower() in keyword_text.lower() for kw in keywords[:5]):
                subject_relevant = True
            subject_relevance.append(subject_relevant)
        
        if not resource_keyword_texts:
            return []
        
        try:
            # Query text is the combined keywords
            query_text = " ".join(self.preprocess_text(k) for k in keywords)
            
            # Vectorize resource keywords and query
            all_texts = resource_keyword_texts + [query_text]
            tfidf_matrix = self.tfidf_vectorizer.fit_transform(all_texts)
            
            # Calculate similarity between query and resources
            query_vector = tfidf_matrix[-1]
            resource_vectors = tfidf_matrix[:-1]
            
            similarities = cosine_similarity(query_vector, resource_vectors).flatten()
            
            # Apply subject boost if applicable
            if quiz_subject_id:
                for i, is_relevant in enumerate(subject_relevance):
                    if is_relevant:
                        similarities[i] *= 1.25  # 25% boost for subject-relevant resources
            
            # Get top matching resources
            top_indices = similarities.argsort()[::-1][:limit]
            recommended_resource_ids = [resource_ids[i] for i in top_indices if similarities[i] > 0]
            
            return recommended_resource_ids
        except Exception as e:
            logger.error(f"Error in content-based recommendation: {e}")
            return []
    
    def collaborative_filtering(self, user_id, wrong_question_ids, quiz_id=None, limit=5):
        """Enhanced collaborative filtering with performance weighting"""
        if not wrong_question_ids:
            return []
        
        try:
            # Find users who answered the same questions incorrectly
            similar_users = User.objects.filter(
                quiz_attempts__answers__question_id__in=wrong_question_ids,
                quiz_attempts__answers__is_correct=False
            ).exclude(id=user_id).distinct()
            
            if not similar_users.exists():
                return []
            
            # Get resources recommended to similar users with higher weight for:
            # 1. Resources with higher relevance scores
            # 2. Resources that have been viewed (indicating user interest)
            # 3. Resources recommended for multiple similar users
            recommended_resources = Resource.objects.filter(
                userrecommendation__user__in=similar_users
            ).annotate(
                rec_count=Count('userrecommendation'),
                avg_relevance=models.Avg('userrecommendation__relevance_score'),
                view_count=Count('userrecommendation', filter=Q(userrecommendation__viewed=True))
            ).order_by('-avg_relevance', '-view_count', '-rec_count')[:limit]
            
            return [r.id for r in recommended_resources]
        except Exception as e:
            logger.error(f"Error in collaborative filtering: {e}")
            return []
    
    def generate_recommendations(self, user_id, quiz_attempt_id):
        """Main method to generate and save recommendations"""
        try:
            # Get the quiz attempt
            quiz_attempt = UserQuizAttempt.objects.get(id=quiz_attempt_id)
            quiz_id = quiz_attempt.quiz_id
            
            # Get the subject of the quiz
            quiz_subject_id = Quiz.objects.get(id=quiz_id).subject_id
            
            # Get wrong answers
            wrong_answers = UserAnswer.objects.filter(
                attempt_id=quiz_attempt_id,
                is_correct=False
            ).select_related('question')
            
            if not wrong_answers.exists():
                logger.info(f"No wrong answers for user {user_id} in quiz attempt {quiz_attempt_id}")
                return []
            
            # Extract wrong question IDs
            wrong_question_ids = [answer.question_id for answer in wrong_answers]
            
            # Extract keywords from wrong questions and their options
            keywords = self.extract_keywords_from_questions_and_options(wrong_question_ids)
            logger.info(f"Extracted keywords: {keywords[:10]}")
            
            # Get content-based recommendations with subject context
            content_based_ids = self.content_based_recommendation(
                keywords, 
                quiz_subject_id=quiz_subject_id
            )
            logger.info(f"Content-based recommendations: {content_based_ids}")
            
            # Get collaborative filtering recommendations
            collab_ids = self.collaborative_filtering(user_id, wrong_question_ids, quiz_id=quiz_id)
            logger.info(f"Collaborative recommendations: {collab_ids}")
            
            # Combine recommendations with priority to collaborative filtering
            # since these have been useful to similar users
            all_resource_ids = []
            
            # First add collaborative filtering results
            all_resource_ids.extend(collab_ids)
            
            # Then add content-based results that aren't already included
            for res_id in content_based_ids:
                if res_id not in all_resource_ids:
                    all_resource_ids.append(res_id)
            
            logger.info(f"Combined resource IDs: {all_resource_ids}")
            
            # Save recommendations
            saved_recommendations = []
            
            for i, resource_id in enumerate(all_resource_ids):
                # Calculate relevance score (higher for top recommendations)
                # Scale from 0.5-1.0 to avoid too low relevance scores
                relevance_score = 1.0 - (0.5 * i / len(all_resource_ids)) if len(all_resource_ids) > 1 else 1.0
                
                # Check if this is a collaborative or content-based recommendation
                # Give slight boost to collaborative recommendations
                if resource_id in collab_ids:
                    relevance_score = min(1.0, relevance_score * 1.1)
                
                recommendation, created = UserRecommendation.objects.update_or_create(
                    user_id=user_id,
                    resource_id=resource_id,
                    quiz_attempt=quiz_attempt,
                    defaults={'relevance_score': relevance_score}
                )
                saved_recommendations.append(recommendation)
            
            logger.info(f"Saved {len(saved_recommendations)} recommendations")
            return saved_recommendations
        except Exception as e:
            logger.error(f"Error generating recommendations: {e}")
            return []