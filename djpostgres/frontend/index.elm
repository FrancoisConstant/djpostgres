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
            (Model model.currentPage model.currentDatabase databases, Cmd.none)

        GotDatabases (Err e) ->
            (model, Cmd.none)


-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "DJ Postgres" ]
        , render_menu model
        , render_page model
        ]


render_page : Model -> Html Msg
render_page model =
    let
        page_content =
            case model.currentPage of
                SelectDatabasePage ->
                    render_select_database_page model
                DatabasePage ->
                    render_database_page model
                TablePage ->
                     render_table_page model
    in
        page_content


render_menu : Model -> Html Msg
render_menu model =
    div []
        [ button [ onClick GoSelectDatabasePage ] [ text "Select Database" ]
        ]


render_select_database_page : Model -> Html Msg
render_select_database_page model =
    div []
        [ text "Select Database" ]


render_database_page : Model -> Html Msg
render_database_page model =
    div []
        [ text "Database" ]


render_table_page : Model -> Html Msg
render_table_page model =
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
    url = "http://localhost:8001/djpg/api/databases"
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
