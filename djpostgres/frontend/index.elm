module DjPostgres exposing (..)

import Array
import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode


--import Types exposing (..)


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Page
    = SelectDatabasePage
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
    ( Model SelectDatabasePage Maybe.Nothing Array.empty, Cmd.none )



-- UPDATE


type Msg
    = GoSelectDatabasePage
    | GotDatabases (Result Http.Error (Array.Array Database))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoSelectDatabasePage ->
            ( { model | currentPage = SelectDatabasePage }, getDatabases )

        GotDatabases (Ok databases) ->
            ( Model model.currentPage model.currentDatabase databases, Cmd.none )

        GotDatabases (Err e) ->
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
        [ button [ onClick GoSelectDatabasePage ] [ text "Select Database" ]
        ]


renderSelectDatabasePage : Model -> Html Msg
renderSelectDatabasePage model =
    div []
        [ text "Select Database" ]


renderDatabasePage : Model -> Html Msg
renderDatabasePage model =
    div []
        [ text "Database" ]


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
