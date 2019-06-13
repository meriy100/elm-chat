module Page exposing (Model, init, update, subscriptions, view)

import Json.Encode as Encode
import Json.Decode as Decode
import Api.Websocket as Websocket
import Html exposing (Html)
import Message as Message exposing (..)
import Room as Room
import Page.Rooms as Rooms

import Task as Task

type alias Model =
    { roomsModel : Rooms.Model
    }

type Msg =
    RoomsMsg Rooms.Msg
    | WebsocketIn String
    | WebsocketOnOpen String


init : () -> ( Model, Cmd Msg )
init _ =
    ( { roomsModel = Rooms.initModel
      }
    , Cmd.none
    )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        RoomsMsg roomsMsg ->
            let
                (roomsModel, roomsCmdMsg) =
                    Rooms.update roomsMsg model.roomsModel
            in
            ({ model | roomsModel = roomsModel }, Cmd.map RoomsMsg roomsCmdMsg )
        WebsocketOnOpen s ->
            ( model
            , Task.perform Rooms.WebsocketOnOpen (Task.succeed s)
                |> Cmd.map RoomsMsg
            )

        WebsocketIn value ->
            case Decode.decodeString Websocket.typeDecoder value of
                Ok Websocket.PostedMessage ->
                    ( model
                    , value
                        |> Decode.decodeString (Websocket.payloadDecoder Message.decoder)
                        |> Task.succeed
                        |> Task.perform Rooms.PostedMessage
                        |> Cmd.map RoomsMsg
                    )

                Ok Websocket.GetRooms ->
                    ( model
                    , Decode.decodeString (Websocket.payloadDecoder (Decode.list Room.decoder)) value
                        |> Task.succeed
                        |> Task.perform Rooms.GetRooms
                        |> Cmd.map RoomsMsg
                    )
                Ok (Websocket.SetRoomId) ->
                    ( model, Cmd.none)

                Ok (Websocket.UnDefined t) ->
                    ( model
                    , Task.succeed t
                        |> Task.perform Rooms.UnDefined
                        |> Cmd.map RoomsMsg
                    )

                Err error ->
                    ( model
                    , Task.succeed error
                        |> Task.perform Rooms.RequestError
                        |> Cmd.map RoomsMsg
                    )


view : Model -> Html Msg
view model =
    Rooms.view model.roomsModel
    |> Html.map RoomsMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    [ Websocket.websocketIn WebsocketIn
    , Websocket.websocketOnOpen WebsocketOnOpen
    ]
    |> Sub.batch
