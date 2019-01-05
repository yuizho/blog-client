module Main exposing (Article, Model, Msg(..), Route(..), articlesDecorder, articlesUrl, contentUrl, fetchArticles, fetchContent, init, main, parseUrl, routeParser, subscriptions, update, view, viewLi)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Markdown exposing (Options, defaultOptions, toHtmlWith)
import Task
import Tuple
import Url
import Url.Builder as UrlBuilder
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, string)



-- MAIN


main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        route =
            parseUrl url
    in
    case route of
        Articles article ->
            ( Model key url route
            , fetchArticles
            )

        LoadingContent id ->
            ( Model key url (parseUrl url)
            , fetchContent id
            )

        Content _ _ ->
            ( Model key url (parseUrl url)
            , Cmd.none
            )



-- Article


type alias Article =
    { title : String
    , id : Int
    , createdAt : String
    }


type Route
    = Articles (List Article)
    | LoadingContent String
    | Content String String



-- Parser


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map LoadingContent (s "content" </> string)
        ]


parseUrl : Url.Url -> Route
parseUrl url =
    let
        -- The RealWorld spec treats the fragment like a path.
        -- This makes it *literally* the path, so we can proceed
        -- with parsing as if it had been a normal path all along.
        -- I refered This
        -- https://github.com/rtfeldman/elm-spa-example/blob/b5064c6ef0fde3395a7299f238acf68f93e71d03/src/Route.elm#L59
        parsed =
            { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
                |> parse routeParser
    in
    case parsed of
        Just route ->
            route

        Nothing ->
            Articles []



-- UPDATE


type Msg
    = ShowArticles (Result Http.Error (List Article))
    | ShowContent (Result Http.Error ( String, String ))
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowArticles result ->
            case result of
                Ok newArticle ->
                    ( { model | route = Articles newArticle }
                    , Cmd.none
                    )

                Err _ ->
                    ( model
                    , Cmd.none
                    )

        ShowContent result ->
            case result of
                Ok container ->
                    -- TODO: when came here directly, some loading image shold be shown
                    ( { model | route = Content (Tuple.first container) (Tuple.second container) }
                    , Cmd.none
                    )

                Err _ ->
                    ( model
                    , Cmd.none
                    )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                route =
                    parseUrl url
            in
            case route of
                Articles article ->
                    ( model
                    , fetchArticles
                    )

                LoadingContent id ->
                    ( model
                    , fetchContent id
                    )

                Content _ _ ->
                    ( model
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        title =
            "日常の記録"
    in
    -- decide view with Model Type
    -- refer: https://github.com/rtfeldman/elm-spa-example/blob/ad14ff6f8e50789ba59d8d2b17929f0737fc8373/src/Main.elm#L62
    case model.route of
        Articles articles ->
            { title = title
            , body = baseView (div [ class "siimple-grid-row" ] (List.map viewLi articles))
            }

        LoadingContent id ->
            { title = title
            , body = baseView (div [] [])
            }

        Content titleOfContent content ->
            { title = title
            , body =
                baseView
                    (div []
                        [ div
                            [ class "siimple-jumbotron"
                            ]
                            [ div [ class "siimple-jumbotron-title" ] [ text titleOfContent ]
                            ]
                        , div
                            [ class "siimple-rule"
                            , class "siimple--color-dark"
                            ]
                            []
                        , toHtmlWith options [] content
                        ]
                    )
            }


baseView : Html msg -> List (Html msg)
baseView container =
    [ div
        [ class "siimple-navbar"
        , class "siimple-navbar--large"
        , class "siimple-navbar--dark"
        ]
        [ a [ class "siimple-navbar-title ", href "/" ] [ text "日常の記録" ]
        ]
    , div
        [ class "siimple-content"
        , class "siimple-content--large"
        ]
        [ container ]
    , div
        [ class "siimple-footer"
        , align "center"
        ]
        [ text "© 2019 Yui Ito" ]
    ]


viewLi : Article -> Html msg
viewLi article =
    div
        [ class "siimple-grid-col"
        , class "siimple-grid-col--9"
        ]
        [ a
            [ class "siimple-link"
            , class "siimple--color-dark"
            , href ("#/content/" ++ String.fromInt article.id)
            ]
            [ text article.title ]
        , div [ class "siimple-small" ] [ text article.createdAt ]
        ]


options : Options
options =
    { defaultOptions | sanitize = True }



-- HTTP


fetchArticles : Cmd Msg
fetchArticles =
    Http.send ShowArticles (Http.get articlesUrl articlesDecorder)


articlesUrl : String
articlesUrl =
    UrlBuilder.crossOrigin "http://localhost:8080"
        [ "api", "articles" ]
        []


articlesDecorder : Decode.Decoder (List Article)
articlesDecorder =
    Decode.list
        (Decode.map3 Article
            (Decode.field "title" Decode.string)
            (Decode.field "id" Decode.int)
            (Decode.field "added_at" Decode.string)
        )


fetchContent : String -> Cmd Msg
fetchContent id =
    let
        contentTask =
            Http.getString (contentUrl id) |> Http.toTask

        articleTask =
            Http.get (articleUrl id) articleDecorder |> Http.toTask
    in
    Task.attempt ShowContent <|
        Task.map2 (\content article -> ( article, content )) contentTask articleTask


contentUrl : String -> String
contentUrl id =
    UrlBuilder.crossOrigin "http://localhost:8080"
        [ "api", "articles", id, "content" ]
        []


articleUrl : String -> String
articleUrl id =
    UrlBuilder.crossOrigin "http://localhost:8080"
        [ "api", "articles", id ]
        []


articleDecorder : Decode.Decoder String
articleDecorder =
    Decode.field "title" Decode.string
