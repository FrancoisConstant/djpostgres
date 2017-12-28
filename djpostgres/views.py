from django.conf import settings
from django.http.response import JsonResponse


def databases(request):
    """
    TODO: test
    :return: JSON with databases listing.
    For example:
    {"databases": [{"is_postgres": true, "actual_name": "iwc_forum_master_4", "django_name": "secondary"},
                   {"is_postgres": false, "actual_name": ".../db.sqlite3", "django_name": "default"}]}
    """
    return JsonResponse(
        data={
            'databases': [
                {
                    'django_name': index,
                    'actual_name': settings.DATABASES[index]['NAME'],
                    'is_postgres': 'postgres' in settings.DATABASES[index]['ENGINE']
                } for index in settings.DATABASES
            ]
        }
    )
