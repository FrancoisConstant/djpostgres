# djpostgres

WIP - barely started.

## TODO:

* list DBs
* list tables
* list record with pagination
* run custom SQL
* secure (via setting + login?)
* pip versioning
* README


## Installation:
```
pip install -e git+git@github.com:FrancoisConstant/djpostgres.git#egg=djpostgres
```

```
INSTALLED_APPS = [
    ...
    'djpostgres'
]
```

```
urlpatterns = [
    ...
    path('djpg/', include('djpostgres.urls'))
]
```
