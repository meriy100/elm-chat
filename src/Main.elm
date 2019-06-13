port module Main exposing (main)

import Browser
import Json.Encode as Encode
import Json.Decode as Decode exposing (decodeString, errorToString)
import Api.Websocket as Websocket
import Api.Websocket.Action as Action

import Page.Rooms as Rooms
import Room as Room exposing (..)
import Message as Message exposing (..)

-- JavaScript usage: app.ports.websocketIn.send(response);
port websocketIn : (String -> msg) -> Sub msg
-- JavaScript usage: app.ports.websocketOut.subscribe(handler);
port websocketOut : String -> Cmd msg
port websocketOnOpen : (String -> msg) -> Sub msg

main = Browser.element
    { init = init
    , update = update
    , view = Rooms.view
    , subscriptions = subscriptions
    }

init : () -> (Rooms.Model, Cmd Rooms.Msg)
init _ =
    ({ messages = [], rooms = Rooms.Loading, selectedRoomId = Nothing, newMessage = Message.init, error = "" }, Cmd.none)

getRooms : Cmd Rooms.Msg
getRooms =
    { action = Action.GetRooms, keys = [], payload = False }
    |> Websocket.encoder Encode.bool
    |> Encode.encode 0
    |> websocketOut

update : Rooms.Msg -> Rooms.Model -> (Rooms.Model, Cmd Rooms.Msg)
update msg model =
  case msg of
    Rooms.Change input ->
      ( { model | newMessage = { id = Nothing, content = input } }
      , Cmd.none
      )
    Rooms.Submit newMessage ->
      ( model
      ,  case model.selectedRoomId of
            Just roomId ->
               {action = Action.SendMessage, keys = [{key = "roomId", value = roomId}], payload = newMessage}
               |> Websocket.encoder Message.encoder
               |> Encode.encode 0
               |> websocketOut
            Nothing ->
                Cmd.none
      )
    Rooms.SelectRoom room ->
        ( {model | messages = room.messages, selectedRoomId = Just room.id}
        , {action = Action.SelectRoom, keys = [{ key = "id", value = room.id }], payload = False }
            |> Websocket.encoder Encode.bool
            |> Encode.encode 0
            |> websocketOut
        )
    Rooms.WebsocketOnOpen _ ->
      (model, getRooms)
    Rooms.WebsocketIn value ->
        case decodeString Websocket.typeDecoder value of
            Ok "POSTED_MESSAGE" ->
                let
                   result =
                       decodeString (Websocket.payloadDecoder Message.decoder) value
                in
                case result of
                    Err error ->
                        ({ model | error = errorToString error}, Cmd.none)
                    Ok message ->
                        ( { model | messages = message :: model.messages }, Cmd.none)
            Ok "GET_ROOMS" ->
                let
                   result =
                       decodeString (Websocket.payloadDecoder (Decode.list Room.decoder)) value
                in
                case result of
                    Err error ->
                        ({ model | error = errorToString error}, Cmd.none)
                    Ok rooms ->
                        ( { model | rooms = Rooms.Loaded rooms  }, Cmd.none)
            Ok _ ->
                (model, Cmd.none)
            Err error ->
                ({ model | error = errorToString error}, Cmd.none)

subscriptions : Rooms.Model -> Sub Rooms.Msg
subscriptions model =
    Sub.batch
        [ websocketIn Rooms.WebsocketIn
        , websocketOnOpen Rooms.WebsocketOnOpen
        ]

