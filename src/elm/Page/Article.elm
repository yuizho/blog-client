module Page.Article exposing (Model, Msg, init, update, view)

import Config exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Http
import Json.Decode as Decode
import Markdown exposing (Options, defaultOptions, toHtmlWith)
import Task
import Url.Builder as UrlBuilder



-- MODEL


type alias Model =
    { articleInfo : ArticleInfo
    , content : String
    , config : Config

    -- TOOD: ここでLoadking状態とかもたせればよさげ。
    }


type alias ArticleInfo =
    { title : String
    , createdAt : String
    , tags : List String
    }


init : Config -> String -> ( Model, Cmd Msg )
init config id =
    ( Model (ArticleInfo "" "" []) "" config
    , fetchContent config id
    )



-- UPDATE


type Msg
    = ShowContent (Result Http.Error Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowContent result ->
            case result of
                Ok content ->
                    -- TODO: when came here directly, some loading image shold be shown
                    ( content
                    , Cmd.none
                    )

                Err _ ->
                    ( model
                    , Cmd.none
                    )



-- VIEW


view : Model -> Html msg
view model =
    div []
        [ div
            [ class "siimple-jumbotron"
            ]
            [ div [ class "siimple-jumbotron-title" ] [ text model.articleInfo.title ]
            , div [ class "siimple-jumbotron-detail" ] [ text <| "Posted at " ++ model.articleInfo.createdAt ]
            , Keyed.node "div" [] (List.indexedMap viewTagElements model.articleInfo.tags)
            ]
        , div
            [ class "siimple-rule"
            , class "siimple--color-dark"
            ]
            []
        , toHtmlWith options [] model.content
        ]


viewTagElements : Int -> String -> ( String, Html msg )
viewTagElements index tag =
    ( String.fromInt index
    , span
        [ class "siimple-tag"
        , class "siimple-tag--primary"
        , class "siimple-tag--rounded"
        , class "siimple--mt-2"
        , class "siimple--mr-1"
        ]
        [ text tag ]
    )


options : Options
options =
    { defaultOptions | sanitize = True }



-- HTTP


fetchContent : Config -> String -> Cmd Msg
fetchContent config id =
    let
        articleTask =
            Http.get (articleUrl config id) articleDecorder |> Http.toTask

        contentTask =
            Http.getString (contentUrl config id) |> Http.toTask
    in
    -- I refer this redit
    -- https://www.reddit.com/r/elm/comments/91t937/is_it_possible_to_make_multiple_http_requests_in/
    Task.attempt ShowContent <|
        Task.map2 (\articleInfo content -> Model articleInfo content config) articleTask contentTask


contentUrl : Config -> String -> String
contentUrl config id =
    UrlBuilder.crossOrigin config.hostName
        [ "api", "articles", id, "content" ]
        []


articleUrl : Config -> String -> String
articleUrl config id =
    UrlBuilder.crossOrigin config.hostName
        [ "api", "articles", id ]
        []


articleDecorder : Decode.Decoder ArticleInfo
articleDecorder =
    Decode.map3 ArticleInfo
        (Decode.field "title" Decode.string)
        (Decode.field "added_at" Decode.string)
        (Decode.field "tag_names" (Decode.list Decode.string))
