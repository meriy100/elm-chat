module Message exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode

type alias Message =
    { id : Maybe String
    , content : String
    }

init =
    { id = Nothing
    , content = ""
    }

decoder : Decoder Message
decoder =
    Decode.map2 Message
        (Decode.field "id" (Decode.maybe Decode.string))
        (Decode.field "content" Decode.string)

encoder : Message -> Encode.Value
encoder message =
    Encode.object
        [ ("content", Encode.string message.content)
        ]
