module Page exposing (Model, init, update, subscriptions, view)

import Api.Websocket as Websocket
import Html exposing (Html)
import Message as Message exposing (..)
import Page.Rooms as Rooms


type alias Model =
    { roomsModel : Rooms.Model
    }

type Msg =
    RoomsMsg Rooms.Msg


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


view : Model -> Html Msg
view model =
    Rooms.view model.roomsModel
    |> Html.map RoomsMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    [ Websocket.websocketIn Rooms.WebsocketIn
    , Websocket.websocketOnOpen Rooms.WebsocketOnOpen
    ]
    |> List.map (Sub.map RoomsMsg)
    |> Sub.batch
