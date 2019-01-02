module Main exposing (Model, Msg(..), articlesDecorder, fetchArticles, init, main, subscriptions, toBlogUrl, update, view)

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
    , page : Page
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url (Articles [])
    , fetchArticles
    )



-- Article


type alias Article =
    { title : String
    , id : Int
    }


type Page
    = Articles (List Article)
    | Content String



-- Parser


routeParser : Parser (Page -> a) a
routeParser =
    oneOf
        [ map Content (s "content" </> string)
        ]


parseUrl : Url.Url -> Page
parseUrl url =
    case parse routeParser url of
        Just page ->
            page

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
                    ( { model | page = Articles newArticle }
                    , Cmd.none
                    )

                Err _ ->
                    ( model
                    , Cmd.none
                    )

        ShowContent result ->
            case result of
                Ok newContent ->
                    ( { model | page = Content newContent }
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
                page =
                    parseUrl url

                updated =
                    { model | page = page }
            in
            case page of
                Articles article ->
                    ( updated
                    , fetchArticles
                    )

                Content id ->
                    ( updated
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
    case model.page of
        Articles articles ->
            { title = "一覧"
            , body =
                [ div []
                    [ h2 [] [ text "一覧" ]
                    , ul [] (List.map viewLi articles)
                    ]
                ]
            }

        Content content ->
            { title = "記事"
            , body =
                [ Markdown.toHtml [] content ]
            }


viewLi : Article -> Html msg
viewLi article =
    li []
        [ div []
            [ a [ href ("/content/" ++ String.fromInt article.id) ] [ text article.title ]
            ]
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
        (Decode.map2 Article
            (Decode.field "title" Decode.string)
            (Decode.field "id" Decode.int)
        )


fetchContent : String -> Cmd Msg
fetchContent id =
    Http.send ShowContent <| Http.getString <| contentUrl id


contentUrl : String -> String
contentUrl id =
    UrlBuilder.crossOrigin "http://localhost:8080"
        [ "api", "articles", id, "content" ]
        []
