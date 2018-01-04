module DjPostgres exposing (..)

import Array
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


type alias Model =
    { currentPage : Page
    , currentDatabase : Maybe String
    , databases : Array.Array Database
    , tables : List Table
    }


init : ( Model, Cmd Msg )
init =
    ( Model HomePage Maybe.Nothing Array.empty [], Cmd.none )



-- UPDATE


type Msg
    = ClickHomePage
    | ClickSelectDatabasePage
    | GoSelectDatabasePage
    | GotDatabases (Result Http.Error (Array.Array Database))
    | ClickDatabasePage String
    | GotTables (Result Http.Error (List Table))
    | ClickTablePage String
    | GotTable (Result Http.Error (List List))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickHomePage ->
            ( { model | currentPage = HomePage }, Cmd.none )

        ClickSelectDatabasePage ->
            ( model, getDatabases )

        GotDatabases (Ok databases) ->
            ( { model | databases = databases, currentPage = SelectDatabasePage }, Cmd.none )

        GoSelectDatabasePage ->
            ( model, Cmd.none )

        GotDatabases (Err e) ->
            ( model, Cmd.none )

        ClickDatabasePage databaseName ->
            ( { model | currentDatabase = Just databaseName }, getTables { model | currentDatabase = Just databaseName } )

        GotTables (Ok tables) ->
            ( { model | tables = tables, currentPage = DatabasePage }, Cmd.none )

        GotTables (Err e) ->
            ( model, Cmd.none )

        ClickTablePage tableName ->
            ( model, Cmd.none )

        GotTable (Ok listing) ->
            ( model, Cmd.none )

        GotTable (Err e) ->
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
            [ li []
                [ a [ href "#homepage", onClick ClickHomePage ] [ text "Home" ]
                ]
            , li []
                [ a [ href "#databases", onClick ClickSelectDatabasePage ] [ text "Databases" ]
                ]
            , li []
                [ a [ href "/todo" ] [ text "default" ]
                ]
            , li [] [ text "some_table" ]
            ]
        ]


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
        [ p [] [ text "Welcome to djPostgres" ] ]


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
    li []
        [ button [ onClick (ClickDatabasePage database.djangoName), class "pure-button database-button" ]
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
        "odd"
    else
        "even"


renderTableLink : Table -> Html Msg
renderTableLink table =
    a [ onClick (ClickTablePage table.name), href "#view-table" ] [ text table.name ]


renderTablePage : Model -> Html Msg
renderTablePage model =
    div []
        [ text "Table" ]



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
