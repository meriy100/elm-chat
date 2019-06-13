module Page.Rooms exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode

import Api.Websocket as Websocket
import Api.Websocket.Action as Action
import Room as Room exposing (..)
import Message as Message exposing (..)

import Html as Html exposing (Html)
import Html.Attributes as  Attributes
import Html.Events as Events


type RequestStatus a =
    Loading
    | Loaded a
    | Failed

type alias Model =
    { messages : List Message
    , rooms : RequestStatus (List Room)
    , selectedRoomId : Maybe String
    , newMessage : Message
    , error : String
    }

type Msg =
    Change String
    | Submit Message
    | SelectRoom Room
    | PostedMessage (Result Decode.Error Message)
    | WebsocketOnOpen String
    | UnDefined String
    | RequestError Decode.Error
    | GetRooms (Result Decode.Error (List Room))

initModel : Model
initModel =
    { messages = []
    , rooms = Loading
    , selectedRoomId = Nothing
    , newMessage = Message.init
    , error = ""
    }


getRooms : Cmd Msg
getRooms =
    { action = Action.GetRooms, keys = [], payload = False }
        |> Websocket.encoder Encode.bool
        |> Encode.encode 0
        |> Websocket.websocketOut


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Change input ->
            ( { model | newMessage = { id = Nothing, content = input } }
            , Cmd.none
            )

        Submit newMessage ->
            ( model
            , case model.selectedRoomId of
                Just roomId ->
                    { action = Action.SendMessage, keys = [ { key = "roomId", value = roomId } ], payload = newMessage }
                        |> Websocket.encoder Message.encoder
                        |> Encode.encode 0
                        |> Websocket.websocketOut

                Nothing ->
                    Cmd.none
            )

        SelectRoom room ->
            ( { model | messages = room.messages, selectedRoomId = Just room.id }
            , { action = Action.SelectRoom, keys = [ { key = "id", value = room.id } ], payload = False }
                |> Websocket.encoder Encode.bool
                |> Encode.encode 0
                |> Websocket.websocketOut
            )
        WebsocketOnOpen _ ->
            ( model, getRooms )
        PostedMessage result ->
            case result of
                Err error ->
                    ( { model | error = Decode.errorToString error }, Cmd.none )

                Ok message ->
                    ( { model | messages = message :: model.messages }, Cmd.none )

        GetRooms result  ->
            case result of
                Err error ->
                    ( { model | error = Decode.errorToString error }, Cmd.none )

                Ok rooms ->
                    ( { model | rooms = Loaded rooms }, Cmd.none )

        UnDefined t ->
            ( { model | error = "Undefine Type: " ++ t }, Cmd.none )
        RequestError error ->
            ( { model | error = Decode.errorToString error }, Cmd.none )



li : String -> Html Msg
li string = Html.li [] [Html.text string]

listViewOrLoading : ((List a) -> List (Html Msg)) -> RequestStatus (List a) -> List (Html Msg)
listViewOrLoading f r =
    case r of
        Loading ->
            [Html.p [] [Html.text "Loading"] ]
        Failed ->
            [Html.p [] [Html.text "Failed"] ]
        Loaded xs ->
            f xs

roomListItemView : Room -> Html Msg
roomListItemView room =
    Html.li [Events.onClick (SelectRoom room)] [Html.text room.id]
roomListView : List Room -> List (Html Msg)
roomListView rooms =
    rooms
    |> List.map roomListItemView

view : Model -> Html Msg
view model = Html.div [Attributes.class "container"]
    [ Html.div [Attributes.class "row"]
        [ Html.p [Attributes.style "color" "#f88"] [Html.text model.error]
        ]
    , Html.div [Attributes.class "row"]
        [ Html.div [Attributes.class "two columns"]
            (listViewOrLoading roomListView model.rooms)
        , Html.div [Attributes.class "ten columns"]
            [ Html.form [Events.onSubmit (Submit model.newMessage)]
              [ Html.input [Attributes.placeholder "Enter some text.", Attributes.value model.newMessage.content, Events.onInput Change] []
              , model.messages |> List.map .content |> List.map li |> Html.ol []
              ]
            ]
        ]
    ]
