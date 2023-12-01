from django.urls import path
from .views import transform_text, conversion_result

# API Endpoints
urlpatterns = [
    path("transform_text", transform_text, name="transform_text")
]