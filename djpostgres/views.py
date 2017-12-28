from django.conf import settings
from django.shortcuts import render


def db_select(request):
    selection = list()
    for index in settings.DATABASES:
        selection.append(
            (index, settings.DATABASES[index]['NAME'], bool('postgres' in settings.DATABASES[index]['ENGINE']))
        )
    return render(request, "djpostgres/db_select.html", {'selection': selection})
