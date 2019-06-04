module WebsocketResponse exposing (..)

import Json.Decode as Decode exposing (..)


typeDecoder : Decoder String
typeDecoder =
    Decode.field "type" Decode.string
payloadDecoder : Decoder a -> Decoder a
payloadDecoder decoder =
    Decode.field "payload" decoder

