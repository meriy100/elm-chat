module Api.Websocket exposing (..)

import Json.Decode as Decode exposing (..)
import Json.Encode as Encode

import Api.Websocket.Action as Action exposing (Action)

typeDecoder : Decoder String
typeDecoder =
    Decode.field "type" Decode.string
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
