import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from gensim.models import Word2Vec
from .models import *
import logging

logger = logging.getLogger(__name__)

class RecommendationEngine:
    def __init__(self):
        self.tfidf_vectorizer = TfidfVectorizer(stop_words='english')
        # Word2Vec model would ideally be trained on your corpus
        # For simplicity, we'll use a placeholder method
        
    def extract_keywords_from_questions(self, question_ids):
        """Extract keywords from incorrectly answered questions"""
        questions = Question.objects.filter(id__in=question_ids)
        if not questions.exists():
            return []
        
        # Combine question texts
        texts = [q.text for q in questions]
        
        try:
            # Generate TF-IDF matrix
            tfidf_matrix = self.tfidf_vectorizer.fit_transform(texts)
            feature_names = self.tfidf_vectorizer.get_feature_names_out()
            
            # Get top keywords
            importance = np.argsort(np.asarray(tfidf_matrix.sum(axis=0)).ravel())[::-1]
            # print(importance)
            top_keywords = [feature_names[i] for i in importance]  # Get top 10 keywords
            
            return top_keywords
        except Exception as e:
            logger.error(f"Error extracting keywords: {e}")
            return []
    
    def content_based_recommendation(self, keywords, limit=5):
        """Generate content-based recommendations using keywords"""
        if not keywords:
            return []
        
        # Get all resources
        all_resources = Resource.objects.all()
        if not all_resources.exists():
            return []
        
        # Create a list of resources with their keyword texts
        resource_keyword_texts = []
        resource_ids = []
        
        for resource in all_resources:
            keyword_text = " ".join([k.text for k in resource.keywords.all()])
            if keyword_text:  # Only include resources with keywords
                resource_keyword_texts.append(keyword_text)
                resource_ids.append(resource.id)
        
        if not resource_keyword_texts:
            return []
        
        try:
            # Query text is the combined keywords
            query_text = " ".join(keywords)
            
            # Vectorize resource keywords and query
            all_texts = resource_keyword_texts + [query_text]
            tfidf_matrix = self.tfidf_vectorizer.fit_transform(all_texts)
            
            # Calculate similarity between query and resources
            query_vector = tfidf_matrix[-1]
            resource_vectors = tfidf_matrix[:-1]
            
            similarities = cosine_similarity(query_vector, resource_vectors).flatten()
            
            # Get top matching resources
            top_indices = similarities.argsort()[::-1][:limit]
            recommended_resource_ids = [resource_ids[i] for i in top_indices if similarities[i] > 0]
            
            return recommended_resource_ids
        except Exception as e:
            logger.error(f"Error in content-based recommendation: {e}")
            return []
    
    def collaborative_filtering(self, user_id, wrong_question_ids, limit=5):
        """Simple collaborative filtering based on similar question patterns"""
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
            
            # Get resources recommended to similar users
            recommended_resources = Resource.objects.filter(
                userrecommendation__user__in=similar_users,
                userrecommendation__relevance_score__gt=0.5
            ).order_by('-userrecommendation__relevance_score').distinct()[:limit]
            
            return [r.id for r in recommended_resources]
        except Exception as e:
            logger.error(f"Error in collaborative filtering: {e}")
            return []
    
    def generate_recommendations(self, user_id, quiz_attempt_id):
        """Main method to generate and save recommendations"""
        try:
            # Get wrong answers
            wrong_answers = UserAnswer.objects.filter(
                attempt_id=quiz_attempt_id,
                is_correct=False
            )
            
            if not wrong_answers.exists():
                logger.info(f"No wrong answers for user {user_id} in quiz attempt {quiz_attempt_id}")
                return []
            
            # Extract wrong question IDs
            wrong_question_ids = [answer.question_id for answer in wrong_answers]
            
            # Extract keywords from wrong questions
            keywords = self.extract_keywords_from_questions(wrong_question_ids)

            print("Keywords", keywords)
            
            # Get content-based recommendations
            content_based_ids = self.content_based_recommendation(keywords)
            print(f"content_based_ids: {content_based_ids}")

            # Get collaborative filtering recommendations
            collab_ids = self.collaborative_filtering(user_id, wrong_question_ids)
            print(f"collab_ids: {collab_ids}")

            # Combine and deduplicate recommendations
            all_resource_ids = list(set(content_based_ids + collab_ids))

            print("All resource ids", all_resource_ids)
            
            # Save recommendations
            quiz_attempt = UserQuizAttempt.objects.get(id=quiz_attempt_id)
            saved_recommendations = []
            
            for i, resource_id in enumerate(all_resource_ids):
                # Calculate relevance score (higher for top recommendations)
                relevance_score = 1.0 - (i / len(all_resource_ids)) if len(all_resource_ids) > 1 else 1.0
                
                recommendation, created = UserRecommendation.objects.update_or_create(
                    user_id=user_id,
                    resource_id=resource_id,
                    quiz_attempt=quiz_attempt,
                    defaults={'relevance_score': relevance_score}
                )
                saved_recommendations.append(recommendation)

            print("Saved recommendations", saved_recommendations)
            return saved_recommendations
        except Exception as e:
            logger.error(f"Error generating recommendations: {e}")
            return []