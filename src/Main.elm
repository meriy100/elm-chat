port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as JE
import Json.Decode exposing (decodeString, errorToString)
import WebsocketResponse as WebsocketResponse

import Message as Message exposing (..)

-- JavaScript usage: app.ports.websocketIn.send(response);
port websocketIn : (String -> msg) -> Sub msg
-- JavaScript usage: app.ports.websocketOut.subscribe(handler);
port websocketOut : String -> Cmd msg
main = Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

{- MODEL -}

type alias Model =
    { messages : List Message
    , input : String
    , error : String
    }

init : () -> (Model, Cmd Msg)
init _ =
    ( { messages = []
      , input = ""
      , error = ""
      }
    , Cmd.none
    )

{- UPDATE -}

type Msg = Change String
    | Submit String
    | WebsocketIn String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Change input ->
      ( { model | input = input }
      , Cmd.none
      )
    Submit value ->
      ( model
      , websocketOut ("{ \"action\": \"sendMessage\", \"data\": {  \"content\": \"" ++ value ++ "\" } }")
      )
    WebsocketIn value ->
        case decodeString WebsocketResponse.typeDecoder value of
            Ok "POSTED_MESSAGE" ->
                let
                   result =
                       decodeString (WebsocketResponse.payloadDecoder Message.decoder) value
                in
                case result of
                    Err error ->
                        ({ model | error = errorToString error}, Cmd.none)
                    Ok message ->
                        ( { model | messages = message :: model.messages }, Cmd.none)
            Ok _ ->
                (model, Cmd.none)
            Err error ->
                ({ model | error = errorToString error}, Cmd.none)

{- SUBSCRIPTIONS -}

subscriptions : Model -> Sub Msg
subscriptions model =
    websocketIn WebsocketIn

{- VIEW -}

li : String -> Html Msg
li string = Html.li [] [Html.text string]

view : Model -> Html Msg
view model = Html.div []
    --[ Html.form [HE.onSubmit (WebsocketIn model.input)] -- Short circuit to test without ports
    [ Html.form [onSubmit (Submit model.input)]
      [ Html.input [Attributes.placeholder "Enter some text.", Attributes.value model.input, onInput Change] []
      , model.messages |> List.map .content |> List.map li |> Html.ol []
      ]
    , Html.div []
        [ Html.p [Attributes.style "color" "#f88"] [Html.text model.error]
        ]
    ]
