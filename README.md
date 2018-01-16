# djpostgres

WIP - barely started - learning ELM basically

## TODO:

* run custom SQL
* pip versioning
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
ACTIVATE_DJPOSTGRES = DEBUG
```


```
urlpatterns = [
    ...
    path('djpg/', include('djpostgres.urls'))
]
```
