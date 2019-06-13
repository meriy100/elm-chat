port module Api.Websocket exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode

import Api.Websocket.Action as Action exposing (Action)

-- JavaScript usage: app.ports.websocketIn.send(response);
port websocketIn : (String -> msg) -> Sub msg
-- JavaScript usage: app.ports.websocketOut.subscribe(handler);
port websocketOut : String -> Cmd msg
port websocketOnOpen : (String -> msg) -> Sub msg

type ResponseType =
    PostedMessage
    | GetRooms
    | SetRoomId
    | UnDefined String

stringToResponseType : String -> ResponseType
stringToResponseType s =
    case s of
        "POSTED_MESSAGE" ->
            PostedMessage
        "GET_ROOMS" ->
           GetRooms
        "SET_ROOM_ID" ->
           SetRoomId
        other ->
            UnDefined other


typeDecoder : Decoder ResponseType
typeDecoder =
    Decode.field "type" (Decode.map stringToResponseType Decode.string)
payloadDecoder : Decoder a -> Decoder a
payloadDecoder decoder =
    Decode.field "payload" decoder

type alias Request a =
    { action : Action
    , keys : List KeyPair
    , payload : a
    }

type alias KeyPair =
    { key : String
    , value : String
    }

keyPairsEncoder : List KeyPair -> Encode.Value
keyPairsEncoder keyPairs =
    keyPairs
    |> List.map (\kp -> (kp.key, Encode.string kp.value) )
    |> Encode.object

encoder : (a -> Encode.Value) -> Request a -> Encode.Value
encoder payloadEncoder request =
    Encode.object
        [ ( "action", Encode.string (Action.toString request.action) )
        , ( "keys", keyPairsEncoder request.keys)
        , ( "payload", payloadEncoder request.payload )
        ]
