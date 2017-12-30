module DjPostgres exposing (..)

import Array
import Html exposing (..)
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


type alias Database =
    { djangoName : String
    , actualName : String
    , isPostgres : Bool
    }


type alias DatabasesListing =
    { databases : List Database }


type alias Model =
    { currentPage : Page
    , currentDatabase : Maybe String
    , databases : Array.Array Database
    }


init : ( Model, Cmd Msg )
init =
    ( Model HomePage Maybe.Nothing Array.empty, Cmd.none )



-- UPDATE


type Msg
    = ClickSelectDatabasePage
    | GoSelectDatabasePage
    | GotDatabases (Result Http.Error (Array.Array Database))
    | ClickDatabasePage String
    | GoDatabasePage
    | GotTables (Result Http.Error (Array.Array Database))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickSelectDatabasePage ->
            ( model, getDatabases )

        GotDatabases (Ok databases) ->
            ( { model | databases = databases, currentPage = SelectDatabasePage }, Cmd.none )

        GoSelectDatabasePage ->
            ( model, Cmd.none )

        GotDatabases (Err e) ->
            ( model, Cmd.none )

        ClickDatabasePage databaseName ->
            ( { model | currentDatabase = Just databaseName }, getTables )

        GotTables (Ok tables) ->
            ( { model | currentPage = DatabasePage }, Cmd.none )

        GotTables (Err e) ->
            ( model, Cmd.none )

        GoDatabasePage ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "DJ Postgres" ]
        , renderMenu model
        , renderPage model
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
    in
    pageContent


renderMenu : Model -> Html Msg
renderMenu model =
    div []
        [ button [ onClick ClickSelectDatabasePage ] [ text "Select Database" ]
        ]


renderHomePage : Model -> Html Msg
renderHomePage model =
    div []
        [ text "Welcome" ]


renderSelectDatabasePage : Model -> Html Msg
renderSelectDatabasePage model =
    div []
        [ text "Select Database"
        , model.databases
            |> Array.map renderDatabaseLink
            |> Array.toList
            |> ul []
        ]


renderDatabaseLink : Database -> Html Msg
renderDatabaseLink database =
    li []
        [ button [ onClick (ClickDatabasePage database.djangoName) ]
            [ text <| "#" ++ database.actualName ]
        , text database.djangoName
        ]


renderDatabasePage : Model -> Html Msg
renderDatabasePage model =
    case model.currentDatabase of
        Nothing ->
            div [] []

        Just currentDatabase ->
            div []
                [ text "Database ", text currentDatabase ]


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
            "http://localhost:8001/djpg/api/databases"
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


getTables : Cmd Msg
getTables =
    let
        url =
            "http://localhost:8001/djpg/api/databases"

        -- TODO
    in
    Http.send GotTables (Http.get url databasesDecoder)
