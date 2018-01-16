from functools import wraps

from django.conf import settings
from django.http import HttpResponseForbidden


def djpostgres_access():
    """
    Checks the setting ACTIVATE_DJPOSTGRES
    :return:
    """
    def decorator(func):
        @wraps(func)
        def inner(request, *args, **kwargs):
            if not getattr(settings, 'ACTIVATE_DJPOSTGRES', False):
                return HttpResponseForbidden()
            return func(request, *args, **kwargs)
        return inner
    return decorator
