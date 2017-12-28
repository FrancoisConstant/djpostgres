from django.urls import path

from . import views


urlpatterns = [
    path('', views.db_select, name='index'),
]
