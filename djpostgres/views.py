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
    {"databases": [{"is_postgres": true, "actual_name": "project_x", "django_name": "secondary"},
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
    # TODO unit test
    conn = get_connection(using=database)
    cursor = conn.cursor()
    cursor.execute("""SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';""")

    return JsonResponse(
        data={
            'tables': __dictfetchall(cursor)
        }
    )


def table(request, database, table, page, per_page):
    # TODO: unit test
    conn = get_connection(using=database)
    cursor = conn.cursor()

    cursor.execute("""SELECT COUNT('id') FROM {table};""".format(table=table))
    total_count = cursor.fetchone()[0]

    offset = (page - 1) * per_page
    to = min(offset + per_page, total_count)
    count = to - offset

    cursor.execute(
        """SELECT * FROM {table} OFFSET {offset} LIMIT {limit};""".format(
            table=table,
            offset=offset,
            limit=per_page
        )
    )

    return JsonResponse(
        data={
            'page': page,
            'total_page': 1 + (total_count // per_page),
            'from': offset + 1,
            'to': to,
            'count': count,
            'total_count': total_count,
            'columns': [column.name for column in cursor.description],
            'results': [[str(column) for column in record] for record in cursor.fetchall()]
        }
    )


def __dictfetchall(cursor):
    """ Returns all rows from a cursor as a dict """
    desc = cursor.description
    return [
        dict(zip([col[0] for col in desc], row))
        for row in cursor.fetchall()
    ]
