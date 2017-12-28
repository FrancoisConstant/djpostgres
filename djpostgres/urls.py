from django.urls import path

from . import views


urlpatterns = [
    path('api/databases', views.databases, name='databases')
]
