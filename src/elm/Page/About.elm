module Page.About exposing (Model, init, view)

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



-- MODEL


type alias Model =
    { config : Config
    }


init : Config -> ( Model, Cmd msg )
init config =
    ( Model config
    , Cmd.none
    )



-- VIEW


view : Model -> Html msg
view model =
    div [ class "siimple-content--extra-small" ]
        [ div [ class "siimple-content", align "center" ]
            [ img [ src "yuizho.jpeg", style "width" "50%" ] []
            , h2 [] [ text "yuizho" ]
            , p [ align "left" ] [ text "プログラマーをしています。ラーメンが好きで、東京ヤクルトスワローズのファンです。色々あり、最近フランス語を勉強しています。" ]
            ]
        , div [ class "siimple-rule", class "siimple--color-dark" ] []
        , div []
            [ h3 [] [ text "Links" ]
            , ul []
                [ li []
                    [ a
                        [ class "siimple-link"
                        , href "mailto:yuizho3@gmail.com"
                        ]
                        [ text "E-Mail (yuizho3@gmail.com)" ]
                    ]
                , li []
                    [ a
                        [ class "siimple-link"
                        , href "https://twitter.com/yuizho"
                        ]
                        [ text "Twitter" ]
                    ]
                , li []
                    [ a
                        [ class "siimple-link"
                        , href "https://github.com/yuizho"
                        ]
                        [ text "GitHub" ]
                    ]
                , li []
                    [ a
                        [ class "siimple-link"
                        , href "https://qiita.com/yuizho"
                        ]
                        [ text "Qiita" ]
                    ]
                , li []
                    [ a
                        [ class "siimple-link"
                        , href "https://www.slideshare.net/yuiito94"
                        ]
                        [ text "SlideShare" ]
                    ]
                ]
            ]
        ]
