module Room exposing (..)

import Json.Decode as Decode exposing (..)
import Message as Message exposing (Message)

type alias RoomId = String

type alias Room =
    { id : RoomId
    , messages : List Message
    }

decoder : Decoder Room
decoder =
    Decode.map2
        Room
        (Decode.field "id" Decode.string)
        (Decode.field "messages" (Decode.list Message.decoder))
