module Message exposing (..)

import Json.Decode as Decode exposing (..)

type alias Message =
    { id : Maybe String
    , content : String
    }

decoder : Decoder Message
decoder =
    Decode.map2 Message
        (Decode.field "id" (Decode.maybe Decode.string))
        (Decode.field "content" Decode.string)

