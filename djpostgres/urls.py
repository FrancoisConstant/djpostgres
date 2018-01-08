from django.urls import path

from . import views


app_name = "djpostgres"

urlpatterns = [
    path('', views.index, name="index"),
    path('api/databases', views.databases, name='databases'),
    path('api/database/<database>/tables/', views.tables, name='tables'),
    path('api/database/<database>/tables/<table>/<int:page>/<int:per_page>/', views.table, name='tables')
]
