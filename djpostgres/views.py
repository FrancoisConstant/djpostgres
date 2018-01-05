from django.conf import settings
from django.db.transaction import get_connection
from django.http.response import JsonResponse
from django.shortcuts import render


def index(request):
    return render(request, "djpostgres/index.html", {})


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


def tables(request, database):

    conn = get_connection(using=database)
    cursor = conn.cursor()
    cursor.execute("""SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';""")

    #print(__dictfetchall(cursor))
    #print(cursor.fetchall())

    return JsonResponse(
        data={
            'tables': __dictfetchall(cursor)
        }
    )


def table(request, database, table, offset, limit):
    conn = get_connection(using=database)
    cursor = conn.cursor()
    cursor.execute(
        """SELECT * FROM {table} OFFSET {offset} LIMIT {limit};""".format(
            table=table,
            offset=offset,
            limit=limit
        )
    )

    # print(cursor.description) # [Column(name='id', type_code=23, display_size=None, internal_size=4, precision=None, scale=None, null_ok=None), ...

    return JsonResponse(
        data={
            'columns': [column.name for column in cursor.description],
            'results': [[str(column) for column in record] for record in cursor.fetchall()]
        }
    )


def __dictfetchall(cursor):
    # Returns all rows from a cursor as a dict
    desc = cursor.description
    return [
        dict(zip([col[0] for col in desc], row))
        for row in cursor.fetchall()
    ]
