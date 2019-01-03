module Main exposing (Article, Model, Msg(..), Route(..), articlesDecorder, contentUrl, fetchArticles, fetchContent, init, main, parseUrl, routeParser, subscriptions, toBlogUrl, update, view, viewLi)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Markdown
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

        Content id ->
            ( Model key url (parseUrl url)
            , fetchContent id
            )



-- Article


type alias Article =
    { title : String
    , id : Int
    , createdAt : String
    }


type Route
    = Articles (List Article)
    | Content String



-- Parser


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Content (s "content" </> string)
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
    | ShowContent (Result Http.Error String)
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
                Ok newContent ->
                    -- TODO: when came here directly, some loading image shold be shown
                    ( { model | route = Content newContent }
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

                Content id ->
                    ( model
                    , fetchContent id
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    -- decide view with Model Type
    -- refer: https://github.com/rtfeldman/elm-spa-example/blob/ad14ff6f8e50789ba59d8d2b17929f0737fc8373/src/Main.elm#L62
    case model.route of
        Articles articles ->
            { title = "日常の記録"
            , body = baseView (div [ class "siimple-grid-row" ] (List.map viewLi articles))
            }

        Content content ->
            { title = "記事"
            , body =
                baseView (Markdown.toHtml [] content)
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



-- HTTP


fetchArticles : Cmd Msg
fetchArticles =
    Http.send ShowArticles (Http.get toBlogUrl articlesDecorder)


toBlogUrl : String
toBlogUrl =
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
    Http.send ShowContent <| Http.getString <| contentUrl id


contentUrl : String -> String
contentUrl id =
    UrlBuilder.crossOrigin "http://localhost:8080"
        [ "api", "articles", id, "content" ]
        []
