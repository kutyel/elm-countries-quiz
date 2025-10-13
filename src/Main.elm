module Main exposing (Model, Msg, main)

import Browser
import Countries exposing (Country)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Events.Extra as Events
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
    { correct : Int
    , failed : Int
    , streak : Int
    , maxStreak : Int
    }


type alias GameState =
    { currentCountry : Country
    , remainingCountries : List Country
    , guessedCountries : List Country
    , score : Score
    , guess : String
    }


type GameMode
    = All
    | Random50
    | Random100


type Model
    = Idle
    | Playing GameState (Toast.Tray Toast)
    | Finished Score


init : () -> ( Model, Cmd msg )
init () =
    ( Idle, Cmd.none )


type Msg
    = Start GameMode
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

        Start mode ->
            let
                countryGenerator : Generator (List Country)
                countryGenerator =
                    -- the whole game revolves around this!
                    shuffle Countries.all
                        |> Random.map
                            (\countries ->
                                case mode of
                                    All ->
                                        countries

                                    Random50 ->
                                        List.take 50 countries

                                    Random100 ->
                                        List.take 100 countries
                            )
            in
            ( model, Random.generate (RandomCountry (Score 0 0 0 0)) countryGenerator )

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
            ( Playing (GameState country remainingCountries [] score "") emptyTray, Cmd.none )

        RandomCountry state [] ->
            ( Finished state, Cmd.none )

        CheckAnswer { currentCountry, remainingCountries, guessedCountries, score, guess } ->
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
                        { score
                            | correct = score.correct + 1
                            , streak = score.streak + 1
                            , maxStreak = max (score.streak + 1) score.maxStreak
                        }

                    else
                        { score
                            | failed = score.failed + 1
                            , streak = 0
                        }
            in
            ( case remainingCountries of
                c :: cs ->
                    if answerWasCorrect then
                        Playing (GameState c cs (currentCountry :: guessedCountries) updatedGameScore "") emptyTray

                    else
                        Playing (GameState c cs guessedCountries updatedGameScore "") emptyTray

                [] ->
                    -- we run out of countries, the game is finished!
                    Finished updatedGameScore
            , if answerWasCorrect then
                Task.perform identity <| Task.succeed (AddToast Green)

              else
                Task.perform identity <| Task.succeed (AddToast <| Red currentCountry.name)
            )


viewToast : List (Html.Attribute Msg) -> Toast.Info Toast -> Html Msg
viewToast attributes toast =
    Html.div attributes <|
        case toast.content of
            Red correct ->
                [ Html.div
                    [ Attr.attribute "role" "alert"
                    , Attr.class "alert alert-error animate-in slide-in-from-top duration-500 animate-out slide-out-to-top"
                    ]
                    [ Svg.svg
                        [ SvgAttr.class "h-6 w-6 shrink-0 stroke-current animate-pulse"
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
                    , Html.span [ Attr.class "animate-in fade-in duration-300" ]
                        [ Html.text <| "Mistake! The country was: " ++ correct ]
                    ]
                ]

            Green ->
                [ Html.div
                    [ Attr.attribute "role" "alert"
                    , Attr.class "alert alert-success animate-in slide-in-from-top duration-500 animate-out slide-out-to-top"
                    ]
                    [ Svg.svg
                        [ SvgAttr.class "h-6 w-6 shrink-0 stroke-current animate-bounce"
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
                    , Html.span [ Attr.class "animate-in fade-in duration-300" ]
                        [ Html.text "Correct!" ]
                    ]
                ]


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "min-h-screen flex flex-col bg-base-200" ]
        [ Html.div
            [ Attr.class "navbar bg-base-100 shadow-md sticky top-0 z-50"
            ]
            [ Html.div
                [ Attr.class "flex-1" ]
                [ Html.a
                    [ Attr.class "btn btn-ghost text-lg md:text-xl normal-case"
                    ]
                    [ Html.text "🌍 Countries Quiz" ]
                ]
            , Html.div
                [ Attr.class "flex-none"
                ]
                [ Html.button
                    [ Attr.class "btn btn-ghost btn-sm md:btn-md"
                    , Events.onClick Restart
                    ]
                    [ Html.text "🔄 Restart" ]
                ]
            ]
        , Html.div [ Attr.class "flex-1 flex items-center justify-center p-4 md:p-8" ] <|
            case model of
                Idle ->
                    [ Html.div [ Attr.class "text-center space-y-6 animate-in fade-in zoom-in duration-700" ]
                        [ Html.h1 [ Attr.class "text-4xl md:text-6xl font-bold mb-4" ]
                            [ Html.text "Flag Quiz" ]
                        , Html.p [ Attr.class "text-lg md:text-xl text-base-content/70 mb-8" ]
                            [ Html.text " 🧠 Can you guess all the countries? 🌍" ]
                        , Html.div [ Attr.class "flex flex-col gap-3" ]
                            [ Html.button
                                [ Attr.class "btn btn-primary btn-lg btn-wide text-lg"
                                , Events.onClick <| Start All
                                ]
                                [ Html.text "🚀 All Countries" ]
                            , Html.button
                                [ Attr.class "btn btn-secondary btn-lg btn-wide text-lg"
                                , Events.onClick <| Start Random50
                                ]
                                [ Html.text "🎲 Random 50" ]
                            , Html.button
                                [ Attr.class "btn btn-accent btn-lg btn-wide text-lg"
                                , Events.onClick <| Start Random100
                                ]
                                [ Html.text "🎯 Random 100" ]
                            ]
                        ]
                    ]

                Playing ({ currentCountry, guessedCountries, score, guess } as gameState) tray ->
                    [ Html.div
                        [ Attr.class "toast toast-top toast-center z-50" ]
                        [ Toast.render viewToast tray (Toast.config ToastMsg) ]
                    , Html.div [ Attr.class "w-full max-w-4xl mx-auto flex flex-col gap-4 md:gap-6" ]
                        [ Html.div [ Attr.class "sticky top-16 z-40 bg-base-200 pb-2 md:relative md:top-0 md:order-2" ]
                            [ Html.input
                                [ Attr.type_ "text"
                                , Attr.placeholder "Type country name..."
                                , Attr.class "input input-bordered input-lg w-full text-lg md:text-xl focus:input-primary shadow-lg"
                                , Attr.attribute "autocomplete" "off"
                                , Attr.attribute "autocapitalize" "words"
                                , Events.onInput <| \s -> OnInput { gameState | guess = s }
                                , Attr.value guess
                                , Events.onEnter <| CheckAnswer gameState
                                ]
                                []
                            ]
                        , Html.div
                            [ Attr.class "card bg-base-100 shadow-xl md:order-1" ]
                            [ Html.div
                                [ Attr.class "card-body flex items-center justify-center py-8 md:py-16" ]
                                [ Html.h2
                                    [ Attr.class "text-7xl md:text-9xl text-center select-none" ]
                                    [ Html.text <| currentCountry.flag ]
                                ]
                            ]
                        , Html.div [ Attr.class "stats stats-vertical sm:stats-horizontal bg-base-100 shadow-xl w-full md:order-3" ]
                            [ Html.div [ Attr.class "stat place-items-center py-2" ]
                                [ Html.div [ Attr.class "stat-title text-xs" ] [ Html.text "Correct" ]
                                , Html.div [ Attr.class "stat-value text-success text-xl md:text-4xl transition-all duration-300" ]
                                    [ Html.text <| "✅ " ++ String.fromInt score.correct ]
                                ]
                            , Html.div [ Attr.class "stat place-items-center py-2" ]
                                [ Html.div [ Attr.class "stat-title text-xs" ] [ Html.text "Incorrect" ]
                                , Html.div [ Attr.class "stat-value text-error text-xl md:text-4xl transition-all duration-300" ]
                                    [ Html.text <| "❌ " ++ String.fromInt score.failed ]
                                ]
                            , Html.div [ Attr.class "stat place-items-center py-2" ]
                                [ Html.div [ Attr.class "stat-title text-xs" ] [ Html.text "Streak" ]
                                , Html.div
                                    [ Attr.class <|
                                        "stat-value text-primary text-xl md:text-4xl transition-all duration-300 "
                                            ++ (if score.streak > 0 then
                                                    "animate-pulse scale-110"

                                                else
                                                    ""
                                               )
                                    ]
                                    [ Html.text <|
                                        (if score.streak > 2 then
                                            "🔥 "

                                         else
                                            ""
                                        )
                                            ++ String.fromInt score.streak
                                    ]
                                ]
                            , Html.div [ Attr.class "stat place-items-center py-2" ]
                                [ Html.div [ Attr.class "stat-title text-xs" ] [ Html.text "Best" ]
                                , Html.div
                                    [ Attr.class "stat-value text-secondary text-xl md:text-4xl transition-all duration-500" ]
                                    [ Html.text <|
                                        (if score.maxStreak > 2 then
                                            "🔥 "

                                         else
                                            ""
                                        )
                                            ++ String.fromInt score.maxStreak
                                    ]
                                ]
                            ]
                        , if List.isEmpty guessedCountries then
                            Html.text ""

                          else
                            Html.div [ Attr.class "card bg-base-100 shadow-lg animate-in fade-in duration-500 md:order-4" ]
                                [ Html.div [ Attr.class "card-body p-4" ]
                                    [ Html.h3 [ Attr.class "text-sm font-semibold text-center opacity-60 mb-2" ]
                                        [ Html.text <| "Guessed: " ++ String.fromInt (List.length guessedCountries) ]
                                    , Html.div [ Attr.class "flex flex-wrap gap-2 justify-center" ]
                                        (List.map
                                            (\country ->
                                                Html.span
                                                    [ Attr.class "text-3xl md:text-4xl line-through opacity-50 hover:opacity-80 transition-opacity animate-in zoom-in duration-300"
                                                    , Attr.title country.name
                                                    ]
                                                    [ Html.text country.flag ]
                                            )
                                            (List.reverse guessedCountries)
                                        )
                                    ]
                                ]
                        ]
                    ]

                Finished { correct, failed, maxStreak } ->
                    [ Html.div
                        [ Attr.class "card w-full max-w-md bg-base-100 shadow-2xl animate-in zoom-in duration-500"
                        ]
                        [ Html.div
                            [ Attr.class "card-body p-6 md:p-8"
                            ]
                            [ Html.h2
                                [ Attr.class "card-title text-2xl md:text-4xl text-center justify-center mb-6 animate-in slide-in-from-top duration-700"
                                ]
                                [ Html.text "Congratulations! 🎉" ]
                            , Html.div [ Attr.class "stats stats-vertical shadow w-full mb-4" ]
                                [ Html.div [ Attr.class "stat animate-in slide-in-from-left duration-500 delay-200" ]
                                    [ Html.div [ Attr.class "stat-figure text-success" ]
                                        [ Html.div [ Attr.class "text-4xl" ] [ Html.text "✅" ] ]
                                    , Html.div [ Attr.class "stat-title" ] [ Html.text "Correct" ]
                                    , Html.div [ Attr.class "stat-value text-success" ] [ Html.text <| String.fromInt correct ]
                                    ]
                                , Html.div [ Attr.class "stat animate-in slide-in-from-right duration-500 delay-300" ]
                                    [ Html.div [ Attr.class "stat-figure text-error" ]
                                        [ Html.div [ Attr.class "text-4xl" ] [ Html.text "❌" ] ]
                                    , Html.div [ Attr.class "stat-title" ] [ Html.text "Incorrect" ]
                                    , Html.div [ Attr.class "stat-value text-error" ] [ Html.text <| String.fromInt failed ]
                                    ]
                                , Html.div [ Attr.class "stat animate-in slide-in-from-bottom duration-500 delay-400" ]
                                    [ Html.div [ Attr.class "stat-figure text-warning" ]
                                        [ Html.div [ Attr.class "text-4xl animate-pulse" ] [ Html.text "🔥" ] ]
                                    , Html.div [ Attr.class "stat-title" ] [ Html.text "Best Streak" ]
                                    , Html.div [ Attr.class "stat-value text-warning" ] [ Html.text <| String.fromInt maxStreak ]
                                    ]
                                ]
                            , Html.div [ Attr.class "card-actions justify-center mt-4" ]
                                [ Html.button
                                    [ Attr.class "btn btn-primary btn-wide"
                                    , Events.onClick Restart
                                    ]
                                    [ Html.text "🚀 Play Again" ]
                                ]
                            ]
                        ]
                    ]
        ]
