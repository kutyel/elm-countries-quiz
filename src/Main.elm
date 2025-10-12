module Main exposing (Model, Msg, main)

import Browser
import Countries exposing (Country)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Events.Extra as Events
import Process
import Random exposing (Generator)
import Random.List exposing (shuffle)
import Svg
import Svg.Attributes as SvgAttr
import Task
import Toast


emptyTray : Toast.Tray Toast
emptyTray =
    Toast.tray


main : Program () Model Msg
main =
    Browser.element { init = init, update = update, view = view, subscriptions = always Sub.none }


type Toast
    = Red String
    | Green


type alias Score =
    { correct : Int, failed : Int }


type alias GameState =
    { currentCountry : Country
    , remainingCountries : List Country
    , score : Score
    , guess : String
    }


type Model
    = Idle
    | Playing GameState (Toast.Tray Toast)
    | Finished Score


init : () -> ( Model, Cmd msg )
init () =
    ( Idle, Cmd.none )


type Msg
    = Start
    | Restart
    | ToastMsg Toast.Msg
    | AddToast Toast
    | OnInput GameState
    | CheckAnswer GameState
    | RandomCountry Score (List Country)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnInput gameState ->
            ( Playing gameState emptyTray, Cmd.none )

        Start ->
            let
                countryGenerator : Generator (List Country)
                countryGenerator =
                    -- the whole game revolves around this!
                    shuffle Countries.all
            in
            ( model, Random.generate (RandomCountry (Score 0 0)) countryGenerator )

        Restart ->
            ( Idle, Cmd.none )

        AddToast content ->
            case model of
                Playing state oldTray ->
                    let
                        ( tray, tmesg ) =
                            Toast.add oldTray <| Toast.expireIn 1000 content
                    in
                    ( Playing state tray, Cmd.map ToastMsg tmesg )

                _ ->
                    ( model, Cmd.none )

        ToastMsg tmsg ->
            case model of
                Playing state oldTray ->
                    let
                        ( tray, newTmesg ) =
                            Toast.update tmsg oldTray
                    in
                    ( Playing state tray, Cmd.map ToastMsg newTmesg )

                _ ->
                    ( model, Cmd.none )

        RandomCountry score (country :: remainingCountries) ->
            ( Playing (GameState country remainingCountries score "") emptyTray, Cmd.none )

        RandomCountry state [] ->
            ( Finished state, Cmd.none )

        CheckAnswer { currentCountry, remainingCountries, score, guess } ->
            let
                answerWasCorrect : Bool
                answerWasCorrect =
                    (not <| String.isEmpty guess)
                        && String.contains
                            (String.toLower <| String.trim guess)
                            (String.toLower currentCountry.name)

                updatedGameScore : Score
                updatedGameScore =
                    if answerWasCorrect then
                        { score | correct = score.correct + 1 }

                    else
                        { score | failed = score.failed + 1 }
            in
            ( case remainingCountries of
                c :: cs ->
                    Playing (GameState c cs updatedGameScore "") emptyTray

                [] ->
                    -- we run out of countries, the game is finished!
                    Finished updatedGameScore
            , if answerWasCorrect then
                delay 0 (AddToast Green)

              else
                delay 0 (AddToast <| Red currentCountry.name)
            )


delay : Int -> msg -> Cmd msg
delay ms msg =
    Task.perform (always msg) (Process.sleep <| toFloat ms)


viewToast : List (Html.Attribute Msg) -> Toast.Info Toast -> Html Msg
viewToast attributes toast =
    Html.div
        attributes
    <|
        case toast.content of
            Red correct ->
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
                        [ Html.text <| "Mistake! The country was: " ++ correct ]
                    ]
                ]

            Green ->
                [ Html.div
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
        , Html.div [ Attr.class "h-1/3 grid place-items-center" ] <|
            case model of
                Idle ->
                    [ Html.button
                        [ Attr.class "btn btn-primary btn-lg"
                        , Events.onClick Start
                        ]
                        [ Html.text "Start!" ]
                    ]

                Playing ({ currentCountry, guess } as gameState) tray ->
                    [ Html.div
                        [ Attr.class "toast toast-top toast-center" ]
                        [ Toast.render viewToast tray (Toast.config ToastMsg) ]
                    , Html.div [ Attr.class "flex flex-col" ]
                        [ Html.div
                            [ Attr.class "card w-96 bg-base-100 card-md shadow-sm" ]
                            [ Html.div
                                [ Attr.class "card-body flex items-center justify-center" ]
                                [ Html.h2
                                    [ Attr.class "card-title text-9xl text-center" ]
                                    [ Html.text <| currentCountry.flag ]
                                ]
                            ]
                        , Html.input
                            [ Attr.type_ "text"
                            , Attr.placeholder "Country name..."
                            , Attr.class "input w-full"
                            , Events.onInput <| \s -> OnInput { gameState | guess = s }
                            , Attr.value guess
                            , Events.onEnter <| CheckAnswer gameState
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
