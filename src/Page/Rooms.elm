module Page.Rooms exposing (..)

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
    | WebsocketIn String
    | WebsocketOnOpen String

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
