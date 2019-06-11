port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode exposing (decodeString, errorToString)
import WebsocketResponse as WebsocketResponse

import Room as Room exposing (..)
import Message as Message exposing (..)

-- JavaScript usage: app.ports.websocketIn.send(response);
port websocketIn : (String -> msg) -> Sub msg
-- JavaScript usage: app.ports.websocketOut.subscribe(handler);
port websocketOut : String -> Cmd msg
port websocketOnOpen : (String -> msg) -> Sub msg

main = Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

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

init : () -> (Model, Cmd Msg)
init _ =
    ({ messages = [], rooms = Loading, selectedRoomId = Nothing, newMessage = Message.init, error = "" }, Cmd.none)

{- UPDATE -}

type Msg =
    Change String
    | Submit Message
    | SelectRoom Room
    | WebsocketIn String
    | WebsocketOnOpen String

getRooms : Cmd Msg
getRooms =
    { action = WebsocketResponse.GetRooms, keys = [], payload = False }
    |> WebsocketResponse.encoder Encode.bool
    |> Encode.encode 0
    |> websocketOut

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Change input ->
      ( { model | newMessage = { id = Nothing, content = input } }
      , Cmd.none
      )
    Submit newMessage ->
      ( model
      ,  case model.selectedRoomId of
            Just roomId ->
               {action = WebsocketResponse.SendMessage, keys = [{key = "roomId", value = roomId}], payload = newMessage}
               |> WebsocketResponse.encoder Message.encoder
               |> Encode.encode 0
               |> websocketOut
            Nothing ->
                Cmd.none
      )
    SelectRoom room ->
        ( {model | messages = room.messages, selectedRoomId = Just room.id}
        , {action = WebsocketResponse.SelectRoom, keys = [{ key = "id", value = room.id }], payload = False }
            |> WebsocketResponse.encoder Encode.bool
            |> Encode.encode 0
            |> websocketOut
        )
    WebsocketOnOpen _ ->
      (model, getRooms)
    WebsocketIn value ->
        case decodeString WebsocketResponse.typeDecoder value of
            Ok "POSTED_MESSAGE" ->
                let
                   result =
                       decodeString (WebsocketResponse.payloadDecoder Message.decoder) value
                in
                case result of
                    Err error ->
                        ({ model | error = errorToString error}, Cmd.none)
                    Ok message ->
                        ( { model | messages = message :: model.messages }, Cmd.none)
            Ok "GET_ROOMS" ->
                let
                   result =
                       decodeString (WebsocketResponse.payloadDecoder (Decode.list Room.decoder)) value
                in
                case result of
                    Err error ->
                        ({ model | error = errorToString error}, Cmd.none)
                    Ok rooms ->
                        ( { model | rooms = Loaded rooms  }, Cmd.none)
            Ok _ ->
                (model, Cmd.none)
            Err error ->
                ({ model | error = errorToString error}, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ websocketIn WebsocketIn
        , websocketOnOpen WebsocketOnOpen
        ]

{- VIEW -}

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
            [ Html.form [onSubmit (Submit model.newMessage)]
              [ Html.input [Attributes.placeholder "Enter some text.", Attributes.value model.newMessage.content, onInput Change] []
              , model.messages |> List.map .content |> List.map li |> Html.ol []
              ]
            ]
        ]
    ]
