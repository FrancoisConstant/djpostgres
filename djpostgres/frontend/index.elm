module DjPostgres exposing (..)

import Array
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class, href, target)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Page
    = HomePage
    | SelectDatabasePage
    | DatabasePage
    | TablePage
    | UserPage


type alias Database =
    { djangoName : String
    , actualName : String
    , isPostgres : Bool
    }


type alias DatabasesListing =
    { databases : List Database }


type alias Table =
    { name : String }


type alias QueryResult =
    { columns : List String
    , results : List (List String)
    , page : Int
    , totalPage : Int
    , count : Int
    , totalCount : Int
    , from : Int
    , to : Int
    }


type alias Model =
    { currentPage : Page
    , currentDatabase : Maybe String
    , currentTable : Maybe String
    , currentQueryPage : Int
    , databases : Array.Array Database
    , tables : List Table
    , queryResult : QueryResult
    , resultsPerPage : Int
    }


init : ( Model, Cmd Msg )
init =
    ( getInitialModel, Cmd.none )


getEmptyQueryResult : QueryResult
getEmptyQueryResult =
    { columns = [], results = [], page = 1, totalPage = 1, count = 0, totalCount = 0, from = 1, to = 0 }


getInitialModel : Model
getInitialModel =
    -- User is on the Homepage and all the variables are null / empty
    Model HomePage Maybe.Nothing Maybe.Nothing 1 Array.empty [] getEmptyQueryResult 50



-- UPDATE


type Msg
    = ClickHomePage
    | ClickSelectDatabasePage
    | GoSelectDatabasePage
    | GotDatabases (Result Http.Error (Array.Array Database))
    | ClickDatabasePage String
    | GotTables (Result Http.Error (List Table))
    | ClickTablePage ( String, Int ) -- tableName,
    | GotTableContent (Result Http.Error QueryResult)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickHomePage ->
            ( getInitialModel, Cmd.none )

        ClickSelectDatabasePage ->
            ( model, getDatabases )

        GotDatabases (Ok databases) ->
            ( { getInitialModel
                | databases = databases
                , currentPage = SelectDatabasePage
              }
            , Cmd.none
            )

        GoSelectDatabasePage ->
            ( model, Cmd.none )

        GotDatabases (Err e) ->
            ( model, Cmd.none )

        ClickDatabasePage databaseName ->
            let
                newModel =
                    { getInitialModel | currentDatabase = Just databaseName }
            in
            ( newModel, getTables newModel )

        GotTables (Ok tables) ->
            ( { getInitialModel
                | currentDatabase = model.currentDatabase
                , tables = tables
                , currentPage = DatabasePage
              }
            , Cmd.none
            )

        GotTables (Err e) ->
            ( model, Cmd.none )

        ClickTablePage ( tableName, currentQueryPage ) ->
            let
                newModel =
                    { model | currentTable = Just tableName, currentQueryPage = currentQueryPage }
            in
            ( newModel, getTableContent newModel )

        GotTableContent (Ok queryResult) ->
            ( { model | currentPage = TablePage, queryResult = queryResult }, Cmd.none )

        GotTableContent (Err e) ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ renderHeader model
        , renderBreadcrumb model
        , renderPage model
        ]


renderHeader : Model -> Html Msg
renderHeader model =
    header []
        [ h1 []
            [ a [ href "https://github.com/FrancoisConstant/djpostgres", target "_blank" ]
                [ text "djPostgres" ]
            ]
        , nav []
            [ ul []
                [ li [ class (getLinkClass model HomePage) ]
                    [ a [ href "#homepage", onClick ClickHomePage ] [ text "Home" ]
                    ]
                , li [ class (getLinkClass model SelectDatabasePage) ]
                    [ a [ href "#databases", onClick ClickSelectDatabasePage ] [ text "Databases" ]
                    ]
                , li [ class (getLinkClass model UserPage) ]
                    [ a [ href "#todo" ] [ text "Users" ]
                    ]
                ]
            ]
        ]


getLinkClass : Model -> Page -> String
getLinkClass model page =
    if page == model.currentPage then
        "active"
    else if page == SelectDatabasePage && List.member model.currentPage [ DatabasePage, TablePage ] then
        "active"
    else
        ""


renderBreadcrumb : Model -> Html Msg
renderBreadcrumb model =
    div [ class "breadcrumb" ]
        [ ul []
            [ renderBreadcrumbHome model
            , renderBreadcrumbDatabases model
            , renderBreadcrumbDatabase model
            , renderBreadcrumbTable model
            ]
        ]


renderBreadcrumbHome : Model -> Html Msg
renderBreadcrumbHome model =
    if model.currentPage == HomePage then
        li [] [ text "Home" ]
    else
        li [] [ a [ href "#homepage", onClick ClickHomePage ] [ text "Home" ] ]


renderBreadcrumbDatabases : Model -> Html Msg
renderBreadcrumbDatabases model =
    if model.currentPage == SelectDatabasePage then
        li [] [ text "Databases" ]
    else if model.currentDatabase /= Maybe.Nothing then
        li []
            [ a [ href "#databases", onClick ClickSelectDatabasePage ] [ text "Databases" ]
            ]
    else
        text ""


renderBreadcrumbDatabase : Model -> Html Msg
renderBreadcrumbDatabase model =
    case model.currentDatabase of
        Nothing ->
            text ""

        Just currentDatabase ->
            if model.currentPage == DatabasePage then
                li [] [ text currentDatabase ]
            else
                li []
                    [ a [ href "#database", onClick (ClickDatabasePage currentDatabase) ] [ text currentDatabase ] ]


renderBreadcrumbTable : Model -> Html Msg
renderBreadcrumbTable model =
    case model.currentTable of
        Nothing ->
            text ""

        Just currentTable ->
            li [] [ text currentTable ]


renderPage : Model -> Html Msg
renderPage model =
    let
        pageContent =
            case model.currentPage of
                HomePage ->
                    renderHomePage model

                SelectDatabasePage ->
                    renderSelectDatabasePage model

                DatabasePage ->
                    renderDatabasePage model

                TablePage ->
                    renderTablePage model

                UserPage ->
                    renderHomePage model
    in
    pageContent


renderHomePage : Model -> Html Msg
renderHomePage model =
    div [ class "main" ]
        [ p [] [ text "Welcome to djPostgres" ]
        , br [] []
        , p [] [ text "To get started: ", a [ onClick ClickSelectDatabasePage, href "#select-db" ] [ text "select a database" ], text "." ]
        ]


renderSelectDatabasePage : Model -> Html Msg
renderSelectDatabasePage model =
    div [ class "main" ]
        [ p [] [ text "Select Database:" ]
        , model.databases
            |> Array.map renderDatabaseLink
            |> Array.toList
            |> ul []
        ]


renderDatabaseLink : Database -> Html Msg
renderDatabaseLink database =
    if database.isPostgres then
        li []
            [ button [ onClick (ClickDatabasePage database.djangoName), class "pure-button database-button" ]
                [ text database.djangoName, br [] [], span [] [ text database.actualName ] ]
            ]
    else
        li []
            [ button [ class "pure-button button-warning database-button" ]
                [ text database.djangoName, br [] [], span [] [ text database.actualName ] ]
            ]


renderDatabasePage : Model -> Html Msg
renderDatabasePage model =
    case model.currentDatabase of
        Nothing ->
            div [] []

        Just currentDatabase ->
            div [ class "main" ]
                [ ul [ class "tabs" ]
                    [ li [ class "active" ] [ text "Select table" ]
                    ]
                , div [ class "main-content" ]
                    [ table [ class "pure-table" ]
                        [ model.tables
                            |> List.indexedMap (\index dbTable -> tr [ class (getOddEvenString index) ] [ td [] [ renderTableLink dbTable ] ])
                            |> tbody []
                        ]
                    ]
                ]


getOddEvenString : Int -> String
getOddEvenString index =
    if index % 2 == 0 then
        "even"
    else
        "odd"


renderTableLink : Table -> Html Msg
renderTableLink table =
    a [ onClick (ClickTablePage ( table.name, 1 )), href "#view-table" ] [ text table.name ]


renderTablePage : Model -> Html Msg
renderTablePage model =
    let
        result =
            model.queryResult
    in
    div [ class "main" ]
        [ ul [ class "tabs" ]
            [ li [ class "active" ]
                [ text (toString result.count ++ " results out of " ++ toString result.totalCount ++ " records (" ++ toString result.from ++ " to " ++ toString result.to ++ ").") ]
            ]
        , div [ class "main-content" ]
            [ table [ class "pure-table" ]
                [ thead []
                    [ tr [] (List.map (\column -> th [] [ text column ]) result.columns)
                    ]
                , tbody []
                    (List.indexedMap
                        (\index record ->
                            tr
                                [ class (getOddEvenString index) ]
                                (List.map (\column -> td [] [ text column ]) record)
                        )
                        result.results
                    )
                ]
            ]
        , renderPagination model
        ]


renderPagination : Model -> Html Msg
renderPagination model =
    case model.currentTable of
        Nothing ->
            div [] []

        Just currentTable ->
            if model.queryResult.totalPage == 1 then
                div [] []
            else
                ul [ class "pagination" ]
                    (List.map
                        (\pageIndex ->
                            if pageIndex == model.currentQueryPage then
                                li [ class "current" ]
                                    [ text (toString pageIndex) ]
                            else
                                li []
                                    [ a [ onClick (ClickTablePage ( currentTable, pageIndex )), href "#view-table" ]
                                        [ text (toString pageIndex) ]
                                    ]
                        )
                        (List.range 1 (min 20 model.queryResult.totalPage))
                    )



-- TODO handle pagination after 20 with good UX
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


getDatabases : Cmd Msg
getDatabases =
    let
        url =
            "http://localhost:8000/djpg/api/databases"
    in
    Http.send GotDatabases (Http.get url databasesDecoder)


databasesDecoder : Decode.Decoder (Array.Array Database)
databasesDecoder =
    Decode.at [ "databases" ] (Decode.array databaseDecoder)


databaseDecoder : Decode.Decoder Database
databaseDecoder =
    Decode.map3
        Database
        (Decode.at [ "django_name" ] Decode.string)
        (Decode.at [ "actual_name" ] Decode.string)
        (Decode.at [ "is_postgres" ] Decode.bool)



--
--


getTables : Model -> Cmd Msg
getTables model =
    case model.currentDatabase of
        Nothing ->
            Cmd.none

        Just currentDatabase ->
            let
                url =
                    "http://localhost:8000/djpg/api/database/" ++ currentDatabase ++ "/tables/"
            in
            Http.send GotTables (Http.get url tablesDecoder)


tablesDecoder : Decode.Decoder (List Table)
tablesDecoder =
    Decode.at [ "tables" ] (Decode.list tableDecoder)


tableDecoder : Decode.Decoder Table
tableDecoder =
    Decode.map
        Table
        (Decode.at [ "table_name" ] Decode.string)



--
--


getTableContent : Model -> Cmd Msg
getTableContent model =
    case model.currentDatabase of
        Nothing ->
            Cmd.none

        Just currentDatabase ->
            case model.currentTable of
                Nothing ->
                    Cmd.none

                Just currentTable ->
                    let
                        url =
                            "http://localhost:8000/djpg/api/database/" ++ currentDatabase ++ "/tables/" ++ currentTable ++ "/" ++ toString model.currentQueryPage ++ "/" ++ toString model.resultsPerPage ++ "/"
                    in
                    Http.send GotTableContent (Http.get url tableContentDecoder)


tableContentDecoder : Decode.Decoder QueryResult
tableContentDecoder =
    Decode.map8
        QueryResult
        (Decode.field "columns" (Decode.list Decode.string))
        (Decode.field "results" (Decode.list (Decode.list Decode.string)))
        (Decode.field "page" Decode.int)
        (Decode.field "total_page" Decode.int)
        (Decode.field "count" Decode.int)
        (Decode.field "total_count" Decode.int)
        (Decode.field "from" Decode.int)
        (Decode.field "to" Decode.int)
