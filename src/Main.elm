module Main exposing (Model, Msg, main)

import Browser
import Countries exposing (Country)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Events.Extra as Events
import Random
import Random.List
import Svg
import Svg.Attributes as SvgAttr


main : Program () Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = always Sub.none }


type alias GameState =
    { correct : Int, failed : Int }


type Model
    = Idle
    | Playing Country (List Country) String GameState
    | Finished GameState


init : () -> ( Model, Cmd msg )
init () =
    ( Idle, Cmd.none )


type Msg
    = Start
    | Restart
    | RandomCountry GameState ( Maybe Country, List Country )
    | OnInput Country (List Country) GameState String
    | CheckAnswer Country (List Country) GameState String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnInput country countries state str ->
            ( Playing country countries str state, Cmd.none )

        Start ->
            let
                countryGenerator =
                    Random.List.choose Countries.all
            in
            ( model, Random.generate (RandomCountry { correct = 0, failed = 0 }) countryGenerator )

        Restart ->
            ( Idle, Cmd.none )

        RandomCountry state ( Just country, remainingCountries ) ->
            ( Playing country remainingCountries "" state, Cmd.none )

        RandomCountry result ( Nothing, [] ) ->
            ( Finished result, Cmd.none )

        RandomCountry _ ( Nothing, _ ) ->
            ( model, Cmd.none )

        CheckAnswer country countries state answer ->
            let
                countryGenerator =
                    Random.List.choose countries

                updatedGameState =
                    if String.contains (String.toLower answer) (String.toLower country.name) then
                        { state | correct = state.correct + 1 }

                    else
                        { state | failed = state.failed + 1 }
            in
            ( model, Random.generate (RandomCountry updatedGameState) countryGenerator )


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "h-screen" ]
        [ Html.div
            [ Attr.class "navbar bg-base-100 shadow-sm"
            ]
            [ Html.div
                [ Attr.class "flex-1"
                ]
                [ Html.a
                    [ Attr.class "btn btn-ghost text-xl"
                    ]
                    [ Html.text "elm-countries-quiz" ]
                ]
            , Html.div
                [ Attr.class "flex-none"
                ]
                [ Html.ul
                    [ Attr.class "menu menu-horizontal px-1"
                    ]
                    [ Html.li []
                        [ Html.a
                            [ Events.onClick Restart
                            ]
                            [ Html.text "Restart" ]
                        ]
                    ]
                ]
            ]
        , Html.div [ Attr.class "h-full grid place-items-center" ] <|
            case model of
                Idle ->
                    [ Html.button
                        [ Attr.class "btn btn-primary btn-lg"
                        , Events.onClick Start
                        ]
                        [ Html.text "Start!" ]
                    ]

                Playing country countries input gameState ->
                    [ Html.div
                        -- FIXME: make toats appear/disappear properly
                        [ Attr.class "toast toast-top toast-start"
                        ]
                        [ Html.div
                            [ Attr.attribute "role" "alert"
                            , Attr.class "alert alert-error"
                            ]
                            [ Svg.svg
                                [ SvgAttr.class "h-6 w-6 shrink-0 stroke-current"
                                , SvgAttr.fill "none"
                                , SvgAttr.viewBox "0 0 24 24"
                                ]
                                [ Svg.path
                                    [ SvgAttr.strokeLinecap "round"
                                    , SvgAttr.strokeLinejoin "round"
                                    , SvgAttr.strokeWidth "2"
                                    , SvgAttr.d "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                                    ]
                                    []
                                ]
                            , Html.span []
                                [ Html.text <| "Mistake! The country was: " ++ country.name ]
                            ]
                        , Html.div
                            [ Attr.attribute "role" "alert"
                            , Attr.class "alert alert-success"
                            ]
                            [ Svg.svg
                                [ SvgAttr.class "h-6 w-6 shrink-0 stroke-current"
                                , SvgAttr.fill "none"
                                , SvgAttr.viewBox "0 0 24 24"
                                ]
                                [ Svg.path
                                    [ SvgAttr.strokeLinecap "round"
                                    , SvgAttr.strokeLinejoin "round"
                                    , SvgAttr.strokeWidth "2"
                                    , SvgAttr.d "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                                    ]
                                    []
                                ]
                            , Html.span []
                                [ Html.text "Correct!" ]
                            ]
                        ]
                    , Html.div [ Attr.class "flex flex-col" ]
                        [ Html.div
                            [ Attr.class "card w-96 bg-base-100 card-md shadow-sm"
                            ]
                            [ Html.div
                                [ Attr.class "card-body flex items-center justify-center"
                                ]
                                [ Html.h2
                                    [ Attr.class "card-title text-9xl text-center"
                                    ]
                                    [ Html.text <| country.flag ]
                                ]
                            ]
                        , Html.input
                            [ Attr.type_ "text"
                            , Attr.placeholder "Type here"
                            , Attr.class "input w-full"
                            , Events.onInput <| OnInput country countries gameState
                            , Attr.value input
                            , Events.onEnter <| CheckAnswer country countries gameState input
                            ]
                            []
                        ]
                    ]

                Finished { correct, failed } ->
                    [ Html.div
                        [ Attr.class "card w-96 bg-base-100 card-md shadow-sm"
                        ]
                        [ Html.div
                            [ Attr.class "card-body flex items-center justify-center"
                            ]
                            [ Html.h2
                                [ Attr.class "card-title text-3xl text-center"
                                ]
                                [ Html.text "Congratulations! 🎉🎉🎉" ]
                            , Html.p
                                [ Attr.class "text-lime-500 text-xl text-center" ]
                                [ Html.text <| "Correct answers: " ++ String.fromInt correct ]
                            , Html.p
                                [ Attr.class "text-red-500 text-xl text-center" ]
                                [ Html.text <| "Incorrect answers: " ++ String.fromInt failed ]
                            ]
                        ]
                    ]
        ]
