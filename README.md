# djpostgres

WIP - barely started - learning ELM basically

## TODO:

* list record with pagination
* run custom SQL
* secure (via setting + login?)
* pip versioning
* style
* README


## Installation:
```
https://github.com/avh4/elm-format#installation-
```

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
