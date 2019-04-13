port module Page.Article exposing (Model, Msg, init, update, view)

import Config exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Http
import Json.Decode as Decode
import Markdown exposing (Options, defaultOptions, toHtmlWith)
import RemoteData exposing (RemoteData(..), WebData)
import Task
import Url.Builder as UrlBuilder



-- ports


port addWidgets : () -> Cmd msg



-- MODEL


type alias Model =
    { articleInfo : WebData ArticleInfo
    , config : Config
    }


type alias ArticleInfo =
    { title : String
    , createdAt : String
    , tags : List String
    , content : String
    }


init : Config -> String -> ( Model, Cmd Msg )
init config id =
    ( Model Loading config
    , fetchContent config id
    )



-- UPDATE


type Msg
    = ShowArticle (WebData ArticleInfo)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowArticle result ->
            ( { model | articleInfo = result }
            , addWidgets ()
            )



-- VIEW


view : Model -> Html msg
view model =
    let
        article =
            case model.articleInfo of
                NotAsked ->
                    [ div [] [] ]

                Loading ->
                    [ div
                        [ class "siimple-spinner"
                        , class "siimple-spinner--navy"
                        ]
                        [ text "Loading..." ]
                    ]

                Failure err ->
                    case err of
                        Http.Timeout ->
                            [ div [] [ text "Time out" ] ]

                        Http.BadStatus resp ->
                            [ div [] [ text resp.body ] ]

                        _ ->
                            [ div [] [ text "Some Unexpected Error" ] ]

                Success articleInfo ->
                    [ div
                        []
                        [ div [ class "siimple-jumbotron-title" ] [ text articleInfo.title ]
                        , div [ class "siimple-jumbotron-detail" ] [ text <| "Posted at " ++ articleInfo.createdAt ]
                        , Keyed.node "div" [] (List.indexedMap viewTagElements articleInfo.tags)
                        ]
                    , div
                        [ class "siimple-rule"
                        , class "siimple--color-dark"
                        ]
                        []
                    , toHtmlWith options [] articleInfo.content
                    , div [ id "widgets", align "right" ] []
                    ]
    in
    div [ class "siimple-content--large" ] article


viewTagElements : Int -> String -> ( String, Html msg )
viewTagElements index tag =
    ( String.fromInt index
    , span
        [ class "siimple-tag"
        , class "siimple-tag--light"
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
    -- https://www.reddit.com/r/elm/comments/91t937/is_it_possible_to_make_multiple_http_requests_in/
    Task.attempt (RemoteData.fromResult >> ShowArticle) <|
        Task.map2 (\articleResult content -> ArticleInfo articleResult.title articleResult.createdAt articleResult.tags content) articleTask contentTask


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


type alias ArticleResult =
    { title : String
    , createdAt : String
    , tags : List String
    }


articleDecorder : Decode.Decoder ArticleResult
articleDecorder =
    Decode.map3 ArticleResult
        (Decode.field "title" Decode.string)
        (Decode.field "added_at" Decode.string)
        (Decode.field "tag_names" (Decode.list Decode.string))
