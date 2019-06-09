module WebsocketResponse exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode


type alias ActionType = String

typeDecoder : Decoder String
typeDecoder =
    Decode.field "type" Decode.string
payloadDecoder : Decoder a -> Decoder a
payloadDecoder decoder =
    Decode.field "payload" decoder


encoder : (a -> Encode.Value) -> ActionType -> a -> Encode.Value
encoder payloadEncoder actionType payload =
    Encode.object
        [ ( "action", Encode.string actionType )
        , ( "payload", payloadEncoder payload )
        ]
