module Page.ArticleList exposing (Model, Msg, init, update, view)

import Config exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed as Keyed
import Http
import Json.Decode as Decode
import RemoteData exposing (RemoteData(..), WebData)
import Url.Builder as UrlBuilder



-- MODEL


type alias Model =
    { articles : WebData (List Article)
    , config : Config
    }


type alias Article =
    { title : String
    , id : Int
    , createdAt : String
    , tags : List String
    }


init : Config -> ( Model, Cmd Msg )
init config =
    ( Model Loading config
    , fetchArticles config
    )



-- UPDATE


type Msg
    = ShowArticles (WebData (List Article))
    | ClickTag String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowArticles result ->
            ( { model | articles = result }
            , Cmd.none
            )

        ClickTag tag ->
            ( model, fetchArticlesWithTag model.config tag )



-- VIEW


view : Model -> Html Msg
view model =
    let
        contents =
            case model.articles of
                NotAsked ->
                    [ div [] [] ]

                Loading ->
                    [ div
                        [ class "siimple-spinner"
                        , class "siimple-spinner--navy"
                        ]
                        [ text "Loaking..." ]
                    ]

                Failure err ->
                    case err of
                        Http.Timeout ->
                            [ div [] [ text "Time out" ] ]

                        Http.BadStatus resp ->
                            [ div [] [ text resp.body ] ]

                        _ ->
                            [ div [] [ text "Some Unexpected Error" ] ]

                Success articles ->
                    List.map viewArticle articles
    in
    div [ class "siimple-grid-row" ] contents


viewArticle : Article -> Html Msg
viewArticle article =
    div
        [ class "siimple-grid-col"
        , class "siimple-grid-col--9"
        ]
        [ a
            [ class "siimple-link"
            , class "siimple--color-dark"
            , href ("#/article/" ++ String.fromInt article.id)
            ]
            [ text article.title ]
        , div [ class "siimple-small" ] [ text article.createdAt ]
        , Keyed.node "div" [] (List.indexedMap viewTagElements article.tags)
        ]


viewTagElements : Int -> String -> ( String, Html Msg )
viewTagElements index tag =
    ( String.fromInt index
    , span
        [ class "siimple-tag"
        , class "siimple-tag--primary"
        , class "siimple-tag--rounded"
        , class "siimple--mt-2"
        , class "siimple--mr-1"
        , class "pointer-hand"
        , onClick (ClickTag tag)
        ]
        [ text tag ]
    )



-- HTTP


fetchArticles : Config -> Cmd Msg
fetchArticles config =
    Http.send (RemoteData.fromResult >> ShowArticles) (Http.get (articlesUrl config) articlesDecorder)


articlesUrl : Config -> String
articlesUrl config =
    UrlBuilder.crossOrigin config.hostName
        [ "api", "articles" ]
        []


fetchArticlesWithTag : Config -> String -> Cmd Msg
fetchArticlesWithTag config tag =
    Http.send (RemoteData.fromResult >> ShowArticles) (Http.get (articlesUrlWithTag config tag) articlesDecorder)


articlesUrlWithTag : Config -> String -> String
articlesUrlWithTag config tag =
    UrlBuilder.crossOrigin config.hostName
        [ "api", "articles" ]
        [ UrlBuilder.string "tags" tag ]


articlesDecorder : Decode.Decoder (List Article)
articlesDecorder =
    Decode.list
        (Decode.map4 Article
            (Decode.field "title" Decode.string)
            (Decode.field "id" Decode.int)
            (Decode.field "added_at" Decode.string)
            (Decode.field "tag_names" (Decode.list Decode.string))
        )
