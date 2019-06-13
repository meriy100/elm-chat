module Api.Websocket.Action exposing (..)

type Action =
    GetRooms
    | SendMessage
    | SelectRoom


toString : Action -> String
toString action =
    case action of
        GetRooms ->
            "getRooms"
        SendMessage ->
            "sendMessage"
        SelectRoom ->
            "selectRoom"
